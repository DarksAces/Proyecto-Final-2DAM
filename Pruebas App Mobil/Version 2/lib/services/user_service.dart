import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
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

  // Create sample notification (for testing)
  Future<void> createSampleNotification(String userId) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'welcome',
        'message': '¡Bienvenido a Jovi AR!',
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
    if (currentUserId == null) return false;
    try {
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

      // Update counts
      batch.update(_firestore.collection('users').doc(currentUserId!),
          {'following': FieldValue.increment(1)});
      batch.update(_firestore.collection('users').doc(targetUserId),
          {'followers': FieldValue.increment(1)});

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error following user: $e');
      return false;
    }
  }

  // Unfollow a user
  Future<bool> unfollowUser(String targetUserId) async {
    if (currentUserId == null) return false;
    try {
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

      batch.update(_firestore.collection('users').doc(currentUserId!),
          {'following': FieldValue.increment(-1)});
      batch.update(_firestore.collection('users').doc(targetUserId),
          {'followers': FieldValue.increment(-1)});

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
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
        'color': const Color(0xFFFFD700), // Jovi Yellow
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
        'color': const Color(0xFF00BFFF), // Jovi Blue
        'isUnlocked': contentCount >= 10,
        'requirement': 'Crea 10 obras o sitios',
      },
      {
        'id': 'influencer',
        'label': 'JOVI STAR',
        'icon': Icons.star_rounded,
        'color': const Color(0xFFFF69B4), // Pink
        'isUnlocked': followers >= 5,
        'requirement': 'Consigue 5 seguidores',
      },
      {
        'id': 'critic',
        'label': 'LEYENDA',
        'icon': Icons.shield_rounded,
        'color': const Color(0xFFE30613), // Jovi Red
        'isUnlocked': points >= 1000,
        'requirement': 'Alcanza los 1000 puntos',
      },
    ];
  }

  // Get Level Name from points
  String getLevelName(int points) {
    if (points >= 1500) return 'Leyenda Jovi';
    if (points >= 500) return 'Explorador Experto';
    if (points >= 100) return 'Explorador Activo';
    return 'Novato';
  }
}
