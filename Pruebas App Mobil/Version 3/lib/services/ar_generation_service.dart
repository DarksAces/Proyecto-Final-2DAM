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
  final String _baseUrl = 'https://aura-bmqy.onrender.com';

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

  /// Checks if the user has reached the limit of 5 AR objects.
  Future<bool> canGenerateMore() async {
    // For now, always return true as requested (local focus)
    return true;
  }

  /// Generates a 3D model, saves it locally, and syncs it to Firebase.
  Future<File?> generateAndUpload3DModel(File imageFile) async {
    if (currentUserId == null) {
      throw Exception("Debes iniciar sesión para guardar objetos AR.");
    }

    try {
      // 1. Generate via Flask API
      // We use the multipart request to get the model URL from Flask
      var request =
          http.MultipartRequest('POST', Uri.parse('$_baseUrl/generate'));
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));

      print("DEBUG: Sending request to $_baseUrl/generate");
      var response = await request.send();

      if (response.statusCode != 200) {
        print("API Error: Status ${response.statusCode}");
        return null;
      }

      final String jsonString = await response.stream.bytesToString();
      print("DEBUG: API Response: $jsonString");
      final Map<String, dynamic> data = json.decode(jsonString);

      if (data['success'] != true || data['model_url'] == null) {
        return null;
      }

      final String flaskModelUrl = data['model_url'].toString().startsWith('http')
          ? data['model_url']
          : '$_baseUrl${data['model_url']}';

      // 2. Download model bytes for Firebase Storage
      final modelResponse = await http.get(Uri.parse(flaskModelUrl));
      if (modelResponse.statusCode != 200) return null;
      final Uint8List modelBytes = modelResponse.bodyBytes;

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
            .putData(modelBytes, SettableMetadata(contentType: 'model/gltf-binary'))
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
      });

      // 6. Award +10 points for generating an AR model
      await _firestore.collection('users').doc(currentUserId).update({
        'points': FieldValue.increment(10),
      });
      print("DEBUG: +10 points awarded to $currentUserId for AR generation");

      // 7. Also save locally for the viewer (immediate performance)
      // Using already downloaded modelBytes to avoid redundant request
      return await saveBytesLocally(modelBytes, glbFileName);
    } catch (e) {
      print("Error in generateAndUpload3DModel: $e");
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
          http.MultipartRequest('POST', Uri.parse('$_baseUrl/generate'));
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
