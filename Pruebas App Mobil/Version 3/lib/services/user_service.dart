import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      
      // Recalculate and clean orphans in the background for 100% accuracy
      recalculateUserCounts(userId);
      
      final data = doc.data()!;
      
      // Ensure avatarUrl is set if photoUrl exists (compatibility)
      if (data['photoUrl'] != null && data['avatarUrl'] == null) {
        data['avatarUrl'] = data['photoUrl'];
      }
      
      return data;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (currentUserId == null) return null;
    return getUserData(currentUserId!);
  }

  // Get current user object (helper for models)
  Future<UserModel?> getCurrentUser() async {
    final data = await getCurrentUserData();
    if (data != null && currentUserId != null) {
      return UserModel.fromMap(data, currentUserId!);
    }
    return null;
  }

  // Update user data
  Future<bool> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      return true;
    } catch (e) {
      debugPrint('Error updating user data: $e');
      return false;
    }
  }

  // Upload profile image
  Future<String?> uploadProfileImage(File imageFile) async {
    if (currentUserId == null) return null;
    try {
      final ref = _storage.ref().child('profile_images').child('$currentUserId.jpg');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      
      // Update user data with new photoUrl and avatarUrl for compatibility
      await updateUserData(currentUserId!, {
        'photoUrl': url,
        'avatarUrl': url
      });
      
      return url;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  // Get user notifications
  Stream<QuerySnapshot> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        //.orderBy('timestamp', descending: true) // Removed to avoid index error
        .limit(50)
        .snapshots();
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Get user posts (In-memory sorting to avoid index requirements)
  Stream<QuerySnapshot> getUserPosts(String userId) {
    return _firestore
        .collection('sitios')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  // Get user followers count
  Future<int> getFollowersCount(String userId) async {
    try {
      final userData = await getUserData(userId);
      return userData?['followers'] ?? 0;
    } catch (e) {
      debugPrint('Error getting followers count: $e');
      return 0;
    }
  }

  // Get user following count
  Future<int> getFollowingCount(String userId) async {
    try {
      final userData = await getUserData(userId);
      return userData?['following'] ?? 0;
    } catch (e) {
      debugPrint('Error getting following count: $e');
      return 0;
    }
  }

  // Recalculate counts from actual subcollections with existence check (Deep Clean)
  Future<void> recalculateUserCounts(String userId) async {
    try {
      // Clean following
      final followingSnap = await _firestore.collection('users').doc(userId).collection('following').get();
      int realFollowingCount = 0;
      for (var doc in followingSnap.docs) {
        final exists = (await _firestore.collection('users').doc(doc.id).get()).exists;
        if (exists) {
          realFollowingCount++;
        } else {
          // Clean orphan
          await _firestore.collection('users').doc(userId).collection('following').doc(doc.id).delete();
        }
      }

      // Clean followers
      final followersSnap = await _firestore.collection('users').doc(userId).collection('followers').get();
      int realFollowersCount = 0;
      for (var doc in followersSnap.docs) {
        final exists = (await _firestore.collection('users').doc(doc.id).get()).exists;
        if (exists) {
          realFollowersCount++;
        } else {
          // Clean orphan
          await _firestore.collection('users').doc(userId).collection('followers').doc(doc.id).delete();
        }
      }
          
      await _firestore.collection('users').doc(userId).update({
        'followers': realFollowersCount,
        'following': realFollowingCount,
      });
    } catch (e) {
      debugPrint('Error recalculating counts: $e');
    }
  }

  // Create sample notification (for testing)
  Future<void> createSampleNotification(String userId) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'welcome',
        'message': '¡Bienvenido a ARte!',
        'fromUser': 'system',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  // Follow a user
  Future<bool> followUser(String targetUserId) async {
    if (currentUserId == null || currentUserId == targetUserId) return false;
    try {
      // Check if already following to avoid double counting
      final followDoc = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('following')
          .doc(targetUserId)
          .get();
      
      if (followDoc.exists) return true; // Already following

      final batch = _firestore.batch();

      // Add to my following
      batch.set(
        _firestore
            .collection('users')
            .doc(currentUserId!)
            .collection('following')
            .doc(targetUserId),
        {'timestamp': FieldValue.serverTimestamp()},
      );

      // Add to their followers
      batch.set(
        _firestore
            .collection('users')
            .doc(targetUserId)
            .collection('followers')
            .doc(currentUserId!),
        {'timestamp': FieldValue.serverTimestamp()},
      );

      await batch.commit();
      
      // CREATE NOTIFICATION for the target user (the one who is being followed)
      _createFollowNotification(targetUserId);
      
      // Force a real recount to ensure 100% accuracy and trigger UI streams
      await recalculateUserCounts(currentUserId!);
      await recalculateUserCounts(targetUserId);
      
      return true;
    } catch (e) {
      debugPrint('Error following user: $e');
      return false;
    }
  }

  // Helper to create follow notifications reliably
  Future<void> _createFollowNotification(String targetUserId) async {
    try {
      if (currentUserId == null) return;
      
      final currentUserData = await getCurrentUserData();
      final currentUserName = currentUserData?['userName'] ?? currentUserData?['fullName'] ?? currentUserData?['displayName'] ?? 'Un nuevo usuario';
      
      await _firestore.collection('notifications').add({
        'userId': targetUserId, // Receiver
        'fromUserId': currentUserId, // Sender
        'type': 'follow',
        'message': '¡$currentUserName ha empezado a seguirte!',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
      debugPrint('Follow notification created for $targetUserId');
    } catch (e) {
      debugPrint('Error in _createFollowNotification: $e');
    }
  }

  // Unfollow a user
  Future<bool> unfollowUser(String targetUserId) async {
    if (currentUserId == null) return false;
    try {
      // Check if actually following
      final followDoc = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('following')
          .doc(targetUserId)
          .get();
      
      if (!followDoc.exists) return true; // Not following anyway

      final batch = _firestore.batch();

      batch.delete(_firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('following')
          .doc(targetUserId));
      batch.delete(_firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId!));

      await batch.commit();

      // Force a real recount to ensure 100% accuracy and trigger UI streams
      await recalculateUserCounts(currentUserId!);
      await recalculateUserCounts(targetUserId);

      return true;
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      return false;
    }
  }

  // Remove a follower (the target user is following me, and I want them to stop following me)
  Future<bool> removeFollower(String followerId) async {
    if (currentUserId == null) return false;
    try {
      final batch = _firestore.batch();

      // Remove from my followers
      batch.delete(_firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('followers')
          .doc(followerId));
          
      // Remove from their following
      batch.delete(_firestore
          .collection('users')
          .doc(followerId)
          .collection('following')
          .doc(currentUserId!));

      await batch.commit();

      // Force a real recount to ensure 100% accuracy and trigger UI streams
      await recalculateUserCounts(currentUserId!);
      await recalculateUserCounts(followerId);

      return true;
    } catch (e) {
      debugPrint('Error removing follower: $e');
      return false;
    }
  }

  // Check if following
  Future<bool> isFollowing(String targetUserId) async {
    if (currentUserId == null) return false;
    final doc = await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('following')
        .doc(targetUserId)
        .get();
    return doc.exists;
  }

  // Get following users detailed info for any user
  Future<List<Map<String, dynamic>>> getFollowingDetails(String userId) async {
    try {
      final following = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .get();
          
      if (following.docs.isEmpty) return [];
      
      final followingIds = following.docs.map((doc) => doc.id).toList();
      
      List<Map<String, dynamic>> users = [];
      for (var id in followingIds) {
        final userDoc = await _firestore.collection('users').doc(id).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          data['id'] = userDoc.id;
          users.add(data);
        }
      }
      return users;
    } catch (e) {
      debugPrint('Error getting following users detailed info: $e');
      return [];
    }
  }

  // Get followers detailed info for any user
  Future<List<Map<String, dynamic>>> getFollowersDetails(String userId) async {
    try {
      final followers = await _firestore
          .collection('users')
          .doc(userId)
          .collection('followers')
          .get();
          
      if (followers.docs.isEmpty) return [];
      
      final followerIds = followers.docs.map((doc) => doc.id).toList();
      
      List<Map<String, dynamic>> users = [];
      for (var id in followerIds) {
        final userDoc = await _firestore.collection('users').doc(id).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          data['id'] = userDoc.id;
          users.add(data);
        }
      }
      return users;
    } catch (e) {
      debugPrint('Error getting followers detailed info: $e');
      return [];
    }
  }

  // Legacy method for current user
  Future<List<Map<String, dynamic>>> getFollowingUsersDetails() async {
    return getFollowingDetails(currentUserId ?? '');
  }

  // Get suggested users (not following)
  Future<List<Map<String, dynamic>>> getSuggestedUsers() async {
    if (currentUserId == null) return [];
    try {
      // Get users I already follow
      final following = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('following')
          .get();
      final followingIds = following.docs.map((doc) => doc.id).toList();
      followingIds.add(currentUserId!);

      // Query all users
      final query = await _firestore.collection('users').limit(50).get();

      return query.docs.where((doc) {
        final data = doc.data();
        final String id = doc.id;
        // Filter out self, followed users, bots, and incomplete profiles
        final bool isMe = id == currentUserId;
        final bool isFollowed = followingIds.contains(id);
        final bool isBot = data['isBot'] == true || id.startsWith('bot_');
        final bool hasName = data['displayName'] != null &&
            data['displayName'].toString().trim().isNotEmpty;

        return !isMe && !isFollowed && !isBot && hasName;
      }).map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting suggested users: $e');
      return [];
    }
  }

  // Get all users with follow status (for Instagram-like add friends list)
  Future<List<Map<String, dynamic>>> getAllUsersWithFollowStatus() async {
    if (currentUserId == null) return [];
    try {
      final following = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('following')
          .get();
      final followingIds = following.docs.map((doc) => doc.id).toList();

      final query = await _firestore.collection('users').limit(100).get();

      return query.docs.where((doc) {
        final data = doc.data();
        final String id = doc.id;
        final bool isMe = id == currentUserId;
        final bool isBot = data['isBot'] == true || id.startsWith('bot_');
        final bool hasName = data['displayName'] != null &&
            data['displayName'].toString().trim().isNotEmpty;
        return !isMe && !isBot && hasName;
      }).map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['isFollowing'] = followingIds.contains(doc.id);
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting all users with follow status: $e');
      return [];
    }
  }

  // Get user-generated content (sites and AR objects)
  Future<List<Map<String, dynamic>>> getUserContent(String userId) async {
    try {
      // Fetch sites
      final sitesQuery = await _firestore
          .collection('sitios')
          .where('userId', isEqualTo: userId)
          .get();

      // Fetch AR objects
      final arQuery = await _firestore
          .collection('ar_objects')
          .where('userId', isEqualTo: userId)
          .get();

      final List<Map<String, dynamic>> allContent = [];

      // Process sites
      for (var doc in sitesQuery.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['contentType'] = 'site';
        allContent.add(data);
      }

      // Process AR objects
      for (var doc in arQuery.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['contentType'] = 'ar_object';
        // Use thumbnailUrl for AR objects, mapping to imageUrl for easy display
        data['imageUrl'] = data['thumbnailUrl'];
        allContent.add(data);
      }

      // In-memory sort by timestamp descending
      allContent.sort((a, b) {
        final Timestamp? tA = a['timestamp'] ?? a['createdAt'] as Timestamp?;
        final Timestamp? tB = b['timestamp'] ?? b['createdAt'] as Timestamp?;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tB.compareTo(tA);
      });

      return allContent;
    } catch (e) {
      debugPrint('Error getting user content: $e');
      return [];
    }
  }

  // Calculate medals based on user data and content count
  List<Map<String, dynamic>> calculateMedals(
      Map<String, dynamic> userData, int contentCount) {
    final int points = userData['points'] ?? 0;
    final int followers = userData['followers'] ?? 0;

    return [
      {
        'id': 'pioneer',
        'label': 'PIONERO',
        'icon': Icons.auto_awesome,
        'color': const Color(0xFFFFD700), // ARte Yellow
        'isUnlocked': contentCount >= 1,
        'requirement': 'Crea tu primera obra o sitio',
      },
      {
        'id': 'explorer',
        'label': 'CAZADOR AR',
        'icon': Icons.explore_rounded,
        'color': const Color(0xFF4CAF50), // Green
        'isUnlocked': contentCount >= 3,
        'requirement': 'Registra 3 sitios en el mapa',
      },
      {
        'id': 'master',
        'label': 'MAESTRO AR',
        'icon': Icons.psychology_rounded,
        'color': const Color(0xFF00BFFF), // ARte Blue
        'isUnlocked': contentCount >= 10,
        'requirement': 'Crea 10 obras o sitios',
      },
      {
        'id': 'influencer',
        'label': 'ARte STAR',
        'icon': Icons.star_rounded,
        'color': const Color(0xFFFF69B4), // Pink
        'isUnlocked': followers >= 5,
        'requirement': 'Consigue 5 seguidores',
      },
      {
        'id': 'critic',
        'label': 'LEYENDA',
        'icon': Icons.shield_rounded,
        'color': const Color(0xFFE30613), // ARte Red
        'isUnlocked': points >= 1000,
        'requirement': 'Alcanza los 1000 puntos',
      },
    ];
  }

  // Get Level Name from points
  String getLevelName(int points) {
    if (points >= 1500) return 'Leyenda ARte';
    if (points >= 500) return 'Explorador Experto';
    if (points >= 100) return 'Explorador Activo';
    return 'Novato';
  }
}
