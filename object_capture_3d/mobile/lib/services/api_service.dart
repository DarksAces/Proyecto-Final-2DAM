import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/capture_session.dart';

class ApiService {
  String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:8000';

  Future<CaptureSession> createSession(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 200) {
      return CaptureSession.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create session');
    }
  }

  Future<void> uploadImages(String sessionId, List<String> imagePaths) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/sessions/$sessionId/images'),
    );

    for (var path in imagePaths) {
      request.files.add(await http.MultipartFile.fromPath('files', path));
    }

    var response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to upload images');
    }
  }

  Future<void> startProcessing(String sessionId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/$sessionId/process'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to start processing');
    }
  }

  Future<CaptureSession> getSession(String sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/$sessionId'),
    );

    if (response.statusCode == 200) {
      return CaptureSession.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get session');
    }
  }
  
  String getModelUrl(String relativeUrl) {
    return '$baseUrl$relativeUrl';
  }
}
