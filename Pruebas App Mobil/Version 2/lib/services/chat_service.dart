import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        .orderBy('lastMessageTime', descending: true)
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

    // Create new chat
    final docRef = await _firestore.collection('chats').add({
      'participants': [currentUserId, otherUserId],
      'participantNames': {
        // Store names for easy display
        otherUserId: otherUserName,
        // We assume the other user has our name, or we fetch it.
        // For simplicity in this demo, we might update this differently or fetch user data.
      },
      'participantAvatars': {
        otherUserId: otherUserAvatar,
      },
      'lastMessage': 'Nuevo chat comenzado',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }
}
