import 'package:cloud_firestore/cloud_firestore.dart';

class ContestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all accepted artworks for Global tab
  Stream<QuerySnapshot> getGlobalArtworks() {
    return _firestore
        .collection('contest_entries') // Assuming 'contest_entries' or 'posts'
        .where('status', isEqualTo: 'accepted')
        .snapshots();
  }

  // Fetch accepted artworks for a specific school
  Stream<QuerySnapshot> getSchoolArtworks(String schoolId) {
    return _firestore
        .collection('contest_entries')
        .where('status', isEqualTo: 'accepted')
        .where('schoolId', isEqualTo: schoolId)
        .snapshots();
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
}
