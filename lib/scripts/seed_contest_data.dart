import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;

  const schoolId = 'school_id_placeholder';

  // Seed Contest Entries
  final contestEntries = [
    {
      'title': 'Atardecer en la Ciudad',
      'artistName': 'Sofia Garcia',
      'imageUrl':
          'https://plus.unsplash.com/premium_photo-1673292293042-cafd9c8a3ab3?q=80&w=987&auto=format&fit=crop',
      'status': 'accepted',
      'schoolId': schoolId,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 15,
      'userId': 'user_1',
    },
    {
      'title': 'Futuro Abstracto',
      'artistName': 'Mateo Rodriguez',
      'imageUrl':
          'https://images.unsplash.com/photo-1541963463532-d68292c34b19?q=80&w=988&auto=format&fit=crop',
      'status': 'accepted',
      'schoolId': 'other_school_id',
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 22,
      'userId': 'user_2',
    },
    {
      'title': 'Mi Colegio Soñado',
      'artistName': 'Valentina Lopez',
      'imageUrl':
          'https://images.unsplash.com/photo-1549887552-93f954d716d7?q=80&w=1035&auto=format&fit=crop',
      'status': 'accepted',
      'schoolId': schoolId, // Same school
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 8,
      'userId': 'user_3',
    },
    {
      'title': 'Naturaleza Viva',
      'artistName': 'Lucas Perez',
      'imageUrl':
          'https://images.unsplash.com/photo-1579783902614-a3fb39279c0f?q=80&w=1000&auto=format&fit=crop',
      'status': 'pending',
      'schoolId': schoolId,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'userId': 'user_4',
    },
  ];

  for (var entry in contestEntries) {
    await firestore.collection('contest_entries').add(entry);
    debugPrint('Added contest entry: ${entry['title']}');
  }

  debugPrint('Seeding complete!');
}
