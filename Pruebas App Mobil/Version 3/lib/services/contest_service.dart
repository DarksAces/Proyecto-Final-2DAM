import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ContestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Fetch all accepted artworks for Global tab, optionally filtered by category
  Stream<QuerySnapshot> getGlobalArtworks({String? category}) {
    Query query = _firestore
        .collection('contest_entries')
        .where('status', isEqualTo: 'accepted');
    
    if (category != null && category != 'Todo') {
      query = query.where('category', isEqualTo: category);
    }
    
    return query.snapshots();
  }

  // Add a new contest entry
  Future<void> addContestEntry(Map<String, dynamic> entryData) {
    return _firestore.collection('contest_entries').add({
      ...entryData,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'accepted', // Auto-accept for demo or set to 'pending'
      'likes': 0,
    });
  }

  // Upload an image to Firebase Storage for a contest entry
  Future<String> uploadContestImage(File imageFile) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('contest_images').child(fileName);
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }
}
