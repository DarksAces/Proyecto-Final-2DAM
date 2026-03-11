import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class ARModel {
  final String id;
  final String url;
  final String name;
  final double latitude;
  final double longitude;
  final String authorId;
  final DateTime timestamp;

  ARModel({
    required this.id,
    required this.url,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.authorId,
    required this.timestamp,
  });

  factory ARModel.fromMap(Map<String, dynamic> map, String id) {
    return ARModel(
      id: id,
      url: map['url'] ?? '',
      name: map['name'] ?? 'Unknown',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      authorId: map['authorId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'authorId': authorId,
      'timestamp': timestamp,
    };
  }
}

class ARService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Upload a 3D model (.glb/.gltf)
  Future<bool> uploadModel({
    required File file,
    required String name,
    required double lat,
    required double lng,
    required String authorId,
  }) async {
    try {
      String fileId = _uuid.v4();
      String extension = file.path.split('.').last;
      Reference ref = _storage.ref().child('ar_models').child('$fileId.$extension');
      
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('ar_models').add({
        'url': downloadUrl,
        'name': name,
        'latitude': lat,
        'longitude': lng,
        'authorId': authorId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print("Error uploading AR model: $e");
      return false;
    }
  }

  // Get models within a certain radius (simplified: gets all for now, filter in UI or query)
  // Real implementation should use GeoFlutterFire or similar for radius query.
  // For this prototype, we'll fetch all and filter in memory if needed, or just show last 20.
  Stream<List<ARModel>> getNearbyModels() {
    return _firestore
        .collection('ar_models')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ARModel.fromMap(doc.data(), doc.id)).toList();
    });
  }
}
