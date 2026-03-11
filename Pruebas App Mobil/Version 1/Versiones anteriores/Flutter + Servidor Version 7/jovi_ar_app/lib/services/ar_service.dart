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

  // Get models within a certain radius
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

  // Simulate Photogrammetry: Upload photos to be processed by a backend
  Future<String?> uploadPhotosForProcessing(List<File> photos) async {
    try {
      String batchId = _uuid.v4();
      
      // Upload each photo
      for (int i = 0; i < photos.length; i++) {
        String ext = photos[i].path.split('.').last;
        Reference ref = _storage.ref().child('photogrammetry_inputs/$batchId/photo_$i.$ext');
        await ref.putFile(photos[i]);
      }
      
      // Creating a "Job" entry in Firestore (optional, good for backend triggers)
      await _firestore.collection('processing_jobs').doc(batchId).set({
        'status': 'pending',
        'photo_count': photos.length,
        'timestamp': FieldValue.serverTimestamp(),
        // 'authorId': ...
      });

      return batchId; 
    } catch (e) {
      print("Error uploading photos: $e");
      return null;
    }
  }

  // Listen to a specific processing job
  Stream<DocumentSnapshot> listenToProcessingJob(String jobId) {
    return _firestore.collection('processing_jobs').doc(jobId).snapshots();
  }

  // --- MOCK BACKEND ---
  // Call this to simulate a server processing the job automatically.
  // This avoids the need to manually edit Firebase Console for testing.
  Future<void> simulateBackendProcessing(String jobId) async {
    // 1. Wait to simulate processing time (GPU/CPU)
    await Future.delayed(const Duration(seconds: 6));

    // 2. Update the job as "completed" with a sample result URL
    // We use a public GLB (duck) to show it's different from the default avatar,
    // or we could use the avatar URL if preferred. Let's use a distinct one to prove it worked.
    // GitHub Raw Link to a simple GLB (Duck)
    const mockResultUrl = "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Duck/glTF-Binary/Duck.glb";
    
    await _firestore.collection('processing_jobs').doc(jobId).update({
      'status': 'completed',
      'model_url': mockResultUrl,
    });
  }
}
