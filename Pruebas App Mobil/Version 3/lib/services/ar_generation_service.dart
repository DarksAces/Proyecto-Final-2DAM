import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../config/secrets.dart';

class ArGenerationService {
  final String _renderUrl = 'https://aura-bmqy.onrender.com';
  final String _hfUrl = 'https://api-inference.huggingface.co/models/Tencent/Hunyuan3D-2';

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
      return true;
    }
  }

  /// Generates a 3D model with failover support.
  Future<File?> generateAndUpload3DModel(File imageFile) async {
    if (currentUserId == null) {
      throw Exception("Debes iniciar sesión para guardar objetos AR.");
    }

    Uint8List? modelBytes;

    // --- 1. Intentar con Render ---
    try {
      print("DEBUG: Intentando generación con Render ($_renderUrl)...");
      modelBytes = await _generateFromRender(imageFile);
    } catch (e) {
      print("⚠️ Render falló o tardó demasiado: $e");
    }

    // --- 2. Si falla Render, intentar con Hugging Face ---
    if (modelBytes == null) {
      try {
        print("DEBUG: Render falló. Intentando con Hugging Face Backup...");
        modelBytes = await _generateFromHuggingFace(imageFile);
      } catch (e) {
        print("⚠️ Hugging Face falló: $e");
      }
    }

    if (modelBytes == null) {
      throw Exception("Todos los servidores de IA están saturados. Inténtalo de nuevo en unos minutos.");
    }

    // --- 3. Finalizar subida ---
    return await _finalizeAndUpload(modelBytes, imageFile);
  }

  Future<Uint8List?> _generateFromRender(File imageFile) async {
    var request = http.MultipartRequest('POST', Uri.parse('$_renderUrl/generate'));
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    
    var streamedResponse = await request.send().timeout(const Duration(seconds: 50));
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) return null;

    final Map<String, dynamic> data = json.decode(response.body);
    if (data['success'] == true && data['model_url'] != null) {
      String fullModelUrl = data['model_url'].toString().startsWith('http')
          ? data['model_url']
          : '$_renderUrl${data['model_url']}';
      
      final modelRes = await http.get(Uri.parse(fullModelUrl)).timeout(const Duration(seconds: 30));
      if (modelRes.statusCode == 200) return modelRes.bodyBytes;
    }
    return null;
  }

  Future<Uint8List?> _generateFromHuggingFace(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final response = await http.post(
      Uri.parse(_hfUrl),
      headers: {
        "Authorization": "Bearer ${Secrets.hfToken}",
        "Content-Type": "application/octet-stream",
      },
      body: bytes,
    ).timeout(const Duration(seconds: 90));

    if (response.statusCode == 200) {
      print("✅ Éxito con Hugging Face");
      return response.bodyBytes;
    }
    print("❌ Error HF: ${response.statusCode}");
    return null;
  }

  Future<File?> _finalizeAndUpload(Uint8List modelBytes, File thumbFile) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String glbFileName = "ar_$timestamp.glb";
      final String imgFileName = "thumb_$timestamp.jpg";

      final Reference glbRef = _storage.ref().child('users/$currentUserId/ar_models/$glbFileName');
      final Reference imgRef = _storage.ref().child('users/$currentUserId/ar_models/$imgFileName');

      final List<String> urls = await Future.wait([
        glbRef.putData(modelBytes, SettableMetadata(contentType: 'model/gltf-binary')).then((s) => s.ref.getDownloadURL()),
        imgRef.putFile(thumbFile, SettableMetadata(contentType: 'image/jpeg')).then((s) => s.ref.getDownloadURL()),
      ]);

      await _firestore.collection('ar_objects').add({
        'name': glbFileName,
        'thumbnailUrl': urls[1],
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'glb',
        'url': urls[0],
        'userId': currentUserId,
        'status': 'pending_review',
      });

      await _firestore.collection('users').doc(currentUserId).update({
        'points': FieldValue.increment(10),
      });

      return await saveBytesLocally(modelBytes, glbFileName);
    } catch (e) {
      print("Error en el proceso final: $e");
      rethrow;
    }
  }
}
