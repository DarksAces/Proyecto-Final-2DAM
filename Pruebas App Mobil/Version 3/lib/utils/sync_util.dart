import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/user_service.dart';

Future<void> syncAllUsersPoints() async {
  final firestore = FirebaseFirestore.instance;
  final userService = UserService();
  
  debugPrint('DEBUG: Starting GLOBAL SYNC for all users...');
  
  try {
    final usersSnap = await firestore.collection('users').get();
    debugPrint('DEBUG: Found ${usersSnap.docs.length} users.');
    
    for (var doc in usersSnap.docs) {
      final userId = doc.id;
      debugPrint('DEBUG: Syncing points for user: $userId');
      await userService.recalculateUserPoints(userId);
    }
    
    debugPrint('DEBUG: GLOBAL SYNC COMPLETED SUCCESSFULY!');
  } catch (e) {
    debugPrint('DEBUG: GLOBAL SYNC FAILED: $e');
  }
}
