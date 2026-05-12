import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ArGenerationService {
  final List<String> _baseUrls = [
    'https://aura-bmqy.onrender.com',
    'https://aura-backup-1.onrender.com', // Placeholder for actual backups
    'https://aura-backup-2.onrender.com',
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Saves bytes to a local GLB file.
  Future<File?> saveBytesLocally(Uint8List bytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final localPath = path.join(directory.path, 'ar_models');

      final localDir = Directory(localPath);
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
      }

      final file = File(path.join(localPath, fileName));
      await file.writeAsBytes(bytes);
      print("Model saved locally at: ${file.path}");
      return file;
    } catch (e) {
      print("Error saving bytes locally: $e");
      return null;
    }
  }

  /// Downloads a GLB file from a URL and saves it locally.
  Future<File?> downloadToLocal(String url, String fileName) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final localPath = path.join(directory.path, 'ar_models');

        final localDir = Directory(localPath);
        if (!await localDir.exists()) {
          await localDir.create(recursive: true);
        }

        final file = File(path.join(localPath, fileName));
        await file.writeAsBytes(response.bodyBytes);
        print("Model saved locally at: ${file.path}");
        return file;
      }
      return null;
    } catch (e) {
      print("Error downloading AR model: $e");
      return null;
    }
  }

  /// Checks if the user has reached the daily limit.
  Future<bool> canGenerateMore() async {
    if (currentUserId == null) return false;
    
    try {
      // Limit: 3 generations per day to save tokens
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      
      final snap = await _firestore
          .collection('ar_objects')
          .where('userId', isEqualTo: currentUserId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .get();
          
      return snap.docs.length < 3;
    } catch (e) {
      print("Error checking generation limit: $e");
      return true; // Fallback to allow if error
    }
  }

  /// Generates a 3D model, saves it locally, and syncs it to Firebase.
  /// Now with multi-server fallback support.
  Future<File?> generateAndUpload3DModel(File imageFile) async {
    if (currentUserId == null) {
      throw Exception("Debes iniciar sesión para guardar objetos AR.");
    }

    Uint8List? modelBytes;
    String? flaskModelUrl;

    // --- MULTI-SERVER FALLBACK LOOP ---
    for (String baseUrl in _baseUrls) {
      try {
        print("DEBUG: Attempting generation with $baseUrl...");
        
        var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/generate'));
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
        
        var response = await request.send().timeout(const Duration(seconds: 45));

        if (response.statusCode != 200) {
          print("API Error on $baseUrl: Status ${response.statusCode}");
          continue; // Try next server
        }

        final String jsonString = await response.stream.bytesToString();
        final Map<String, dynamic> data = json.decode(jsonString);

        if (data['success'] != true || data['model_url'] == null) {
          continue; // Try next server
        }

        flaskModelUrl = data['model_url'].toString().startsWith('http')
            ? data['model_url']
            : '$baseUrl${data['model_url']}';

        // Download model bytes
        final modelResponse = await http.get(Uri.parse(flaskModelUrl!)).timeout(const Duration(seconds: 30));
        if (modelResponse.statusCode == 200) {
          modelBytes = modelResponse.bodyBytes;
          print("DEBUG: Successfully generated model with $baseUrl");
          break; // Success! Exit loop
        }
      } catch (e) {
        print("Error with server $baseUrl: $e");
        // Loop continues to next server
      }
    }

    if (modelBytes == null) {
      throw Exception("Todos los servidores de IA están ocupados o fuera de línea. Inténtalo de nuevo en unos minutos.");
    }

    try {
      // 3. Prepare paths and names
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String glbFileName = "ar_$timestamp.glb";
      final String imgFileName = "thumb_$timestamp.jpg";

      // 4. Upload to Firebase Storage
      final Reference glbRef =
          _storage.ref().child('users/$currentUserId/ar_models/$glbFileName');
      final Reference imgRef =
          _storage.ref().child('users/$currentUserId/ar_models/$imgFileName');

      print("DEBUG: Uploading to Firebase Storage...");
      final List<Future<String>> uploadTasks = [
        glbRef
            .putData(modelBytes!, SettableMetadata(contentType: 'model/gltf-binary'))
            .then((s) => s.ref.getDownloadURL()),
        imgRef
            .putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'))
            .then((s) => s.ref.getDownloadURL()),
      ];

      final List<String> urls = await Future.wait(uploadTasks);
      final String firebaseModelUrl = urls[0];
      final String thumbnailUrl = urls[1];

      // 5. Save to Firestore (matching the requested schema)
      print("DEBUG: Saving to Firestore ar_objects...");
      await _firestore.collection('ar_objects').add({
        'name': glbFileName,
        'thumbnailUrl': thumbnailUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'glb',
        'url': firebaseModelUrl,
        'userId': currentUserId,
        'status': 'pending_review',
      });

      // 6. Award +10 points for generating an AR model
      await _firestore.collection('users').doc(currentUserId).update({
        'points': FieldValue.increment(10),
      });
      print("DEBUG: +10 points awarded to $currentUserId for AR generation");

      // 7. Also save locally for the viewer (immediate performance)
      return await saveBytesLocally(modelBytes!, glbFileName);
    } catch (e) {
      print("Error in finalizing AR upload: $e");
      rethrow;
    }
  }

  /// Legacy helper for local-only saving if needed
  Future<File?> generateAndSaveLocal(File imageFile) async {
    return await generateAndUpload3DModel(imageFile);
  }

  /// Legacy method for backward compatibility if needed
  Future<Uint8List?> generate3DModel(File imageFile) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('${_baseUrls[0]}/generate'));
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        return await response.stream.toBytes();
      }
      return null;
    } catch (e) {
      print("Error in generating 3D model: $e");
      return null;
    }
  }
}
