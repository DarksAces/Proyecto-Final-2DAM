import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'moderation_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get stream of chats for current user
  Stream<QuerySnapshot> getUserChats() {
    if (currentUserId == null) return const Stream.empty();
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots();
  }

  // Get stream of messages for a chat
  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Send a message
  Future<void> sendMessage(String chatId, String text,
      {String? postId, String? postImageUrl, String? postTitle}) async {
    if (currentUserId == null) return;

    final messageData = {
      'senderId': currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [currentUserId],
    };

    if (postId != null) {
      messageData['postId'] = postId;
      messageData['postImageUrl'] = postImageUrl;
      messageData['postTitle'] = postTitle;
      messageData['type'] = 'post_share';
    } else {
      messageData['type'] = 'text';
    }

    // Add message
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    // Update chat last message
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': postId != null ? 'Compartió una publicación' : text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': currentUserId,
    });
  }

  // Send an image message
  Future<void> sendImageMessage(String chatId, File imageFile) async {
    if (currentUserId == null) return;
    
    // 1. Check for inappropriate content
    final isSafe = await ModerationService().isImageSafe(imageFile);
    if (!isSafe) {
      throw Exception("La imagen contiene contenido inapropiado y ha sido bloqueada.");
    }

    // 2. Upload image
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child('chat_images').child(chatId).child('$fileName.jpg');
    
    await ref.putFile(imageFile);
    final imageUrl = await ref.getDownloadURL();
    
    // Send message
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'text': '',
      'imageUrl': imageUrl,
      'type': 'image',
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [currentUserId],
    });

    // Update chat last message
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': '📷 Imagen',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': currentUserId,
    });
  }

  // Send a video message
  Future<void> sendVideoMessage(String chatId, File videoFile) async {
    if (currentUserId == null) return;
    
    // Upload video
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child('chat_videos').child(chatId).child('$fileName.mp4');
    
    await ref.putFile(videoFile);
    final videoUrl = await ref.getDownloadURL();
    
    // Send message
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'text': '',
      'videoUrl': videoUrl,
      'type': 'video',
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [currentUserId],
    });

    // Update chat last message
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': '🎥 Vídeo',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': currentUserId,
    });
  }

  // Create or get existing chat with a user
  Future<String> createChat(
      String otherUserId, String otherUserName, String otherUserAvatar) async {
    if (currentUserId == null) throw Exception('User not logged in');

    // Check if chat already exists (simplified check)
    final query = await _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (var doc in query.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(otherUserId) && participants.length == 2) {
        return doc.id;
      }
    }

    // Get current user data to store in the chat
    final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
    final currentUserName = currentUserDoc.data()?['userName'] ?? currentUserDoc.data()?['fullName'] ?? 'Usuario';
    final currentUserAvatar = currentUserDoc.data()?['profileImageUrl'] ?? currentUserDoc.data()?['avatarUrl'];

    // Create new chat
    final docRef = await _firestore.collection('chats').add({
      'participants': [currentUserId, otherUserId],
      'participantNames': {
        currentUserId: currentUserName,
        otherUserId: otherUserName,
      },
      'participantAvatars': {
        currentUserId: currentUserAvatar,
        otherUserId: otherUserAvatar,
      },
      'lastMessage': 'Nuevo chat comenzado',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // Mark chat as read for current user
  Future<void> markChatAsRead(String chatId) async {
    if (currentUserId == null) return;
    try {
      // 1. Mark in the chat document (lastReadTime)
      await _firestore.collection('chats').doc(chatId).set({
        'lastReadTime': {
          currentUserId: FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      // 2. Mark all notifications for this chat as read
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .where('chatId', isEqualTo: chatId)
          .where('read', isEqualTo: false)
          .get();

      if (unreadNotifications.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in unreadNotifications.docs) {
          batch.update(doc.reference, {'read': true});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error marking chat as read: $e');
    }
  }

  // Get unread chats count (source of truth for messages)
  Stream<int> getUnreadChatCount() {
    if (currentUserId == null) return Stream.value(0);
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['lastMessageTime'] as Timestamp?;
        final lastSenderId = data['lastSenderId'];
        final lastReadTimeMap = data['lastReadTime'] as Map<String, dynamic>?;
        final myLastReadTime = lastReadTimeMap?[currentUserId] as Timestamp?;

        if (lastSenderId != currentUserId && 
            (myLastReadTime == null || 
             (timestamp != null && timestamp.compareTo(myLastReadTime) > 0))) {
          count++;
        }
      }
      debugPrint('DEBUG: UnreadChatCount (source of truth): $count');
      return count;
    });
  }
}
