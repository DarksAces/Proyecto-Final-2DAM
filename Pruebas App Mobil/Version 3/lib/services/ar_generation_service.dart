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
  final String _baseUrl = 'https://ARte-r3zk.onrender.com';
  final String _apiKey = 'antigravity_3d_key_2026';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

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
    if (currentUserId == null) return false;

    try {
      final query = await _firestore
          .collection('ar_objects')
          .where('userId', isEqualTo: currentUserId)
          .get();

      return query.docs.length < 5;
    } catch (e) {
      print("Error checking AR limits: $e");
      return false;
    }
  }

  /// Generates a 3D model from an image and uploads it to Firebase Storage.
  Future<String?> generateAndUpload3DModel(File imageFile) async {
    if (currentUserId == null) return null;

    // 1. Check Limits
    if (!await canGenerateMore()) {
      throw Exception("Has alcanzado el límite de 5 objetos AR.");
    }

    try {
      // 2. Request to Render API
      var request =
          http.MultipartRequest('POST', Uri.parse('$_baseUrl/generate'));
      request.headers['X-API-KEY'] = _apiKey;
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        final String jsonString = await response.stream.bytesToString();
        print("DEBUG: API Response: $jsonString");
        final Map<String, dynamic> data = json.decode(jsonString);

        if (data['success'] != true || data['model_url'] == null) {
          print("API Error: Success is false or model_url is missing");
          return null;
        }

        final String modelUrl = data['model_url'].toString().startsWith('http')
            ? data['model_url']
            : '$_baseUrl${data['model_url']}';

        print("DEBUG: Fetching GLB from $modelUrl");
        final modelResponse = await http.get(Uri.parse(modelUrl));

        if (modelResponse.statusCode != 200) {
          print(
              "Error downloading model from $modelUrl: ${modelResponse.statusCode}");
          return null;
        }

        final Uint8List bytes = modelResponse.bodyBytes;

        // DEBUG: Inspect GLB header
        if (bytes.length > 12) {
          final String header = String.fromCharCodes(bytes.sublist(0, 4));
          final int version = bytes[4];
          print("DEBUG: GLB Header State: $header, Version Byte: $version");
          print("DEBUG: First 20 bytes: ${bytes.sublist(0, 20)}");
        }

        // 3. Upload GLB and Image to Firebase Storage
        final String timestamp =
            DateTime.now().millisecondsSinceEpoch.toString();
        final String glbFileName = "ar_$timestamp.glb";
        final String imgFileName = "thumb_$timestamp.jpg";

        final Reference glbRef =
            _storage.ref().child('users/$currentUserId/ar_models/$glbFileName');
        final Reference imgRef =
            _storage.ref().child('users/$currentUserId/ar_models/$imgFileName');

        final List<Future<String>> uploadTasks = [
          glbRef
              .putData(
                  bytes, SettableMetadata(contentType: 'model/gltf-binary'))
              .then((s) => s.ref.getDownloadURL()),
          imgRef
              .putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'))
              .then((s) => s.ref.getDownloadURL()),
        ];

        final List<String> urls = await Future.wait(uploadTasks);
        final String downloadUrl = urls[0];
        final String thumbnailUrl = urls[1];

        // 4. Record in Firestore
        await _firestore.collection('ar_objects').add({
          'userId': currentUserId,
          'name': glbFileName,
          'url': downloadUrl,
          'thumbnailUrl': thumbnailUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'type': 'glb'
        });

        // 5. Update user stats (optional but helpful)
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .update({'ar_objects_count': FieldValue.increment(1)});

        return downloadUrl;
      } else {
        print("API Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error in generateAndUpload3DModel: $e");
      rethrow;
    }
  }

  /// Legacy method for backward compatibility if needed
  Future<Uint8List?> generate3DModel(File imageFile) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$_baseUrl/generate'));
      request.headers['X-API-KEY'] = _apiKey;
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
