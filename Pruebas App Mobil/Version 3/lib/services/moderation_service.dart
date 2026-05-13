import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ModerationService {
  // Singleton Pattern
  static final ModerationService _instance = ModerationService._internal();
  factory ModerationService() => _instance;
  ModerationService._internal();

  final String _apiKey = "AIzaSyB1QFr3WcG6vTx94yW6wsuu0qivwpqX598";
  final String _apiUrl = "https://vision.googleapis.com/v1/images:annotate";

  /// Analyzes an image and returns 'true' if it is safe, 'false' if inappropriate.
  Future<bool> isImageSafe(File imageFile) async {
    try {
      debugPrint('🔍 Moderation: Analyzing image for safety...');
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse("$_apiUrl?key=$_apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "requests": [
            {
              "image": {"content": base64Image},
              "features": [
                {"type": "SAFE_SEARCH_DETECTION"}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['responses'] == null || data['responses'].isEmpty) {
          debugPrint('⚠️ Moderation: No responses in Vision API data');
          return true;
        }

        final safeSearch = data['responses'][0]['safeSearchAnnotation'];
        if (safeSearch == null) {
          debugPrint('⚠️ Moderation: No safeSearchAnnotation in Vision API data');
          return true;
        }

        // Likelihood levels: UNKNOWN, VERY_UNLIKELY, UNLIKELY, POSSIBLE, LIKELY, VERY_LIKELY
        bool isInappropriate = 
            _isRisky(safeSearch['adult']) || 
            _isRisky(safeSearch['violence']) ||
            _isRisky(safeSearch['racy']);

        if (isInappropriate) {
          debugPrint("🚫 MODERATION: Image BLOCKED (Adult: ${safeSearch['adult']}, Violence: ${safeSearch['violence']}, Racy: ${safeSearch['racy']})");
          return false;
        }

        debugPrint('✅ Moderation: Image passed safety check');
        return true;
      } else {
        debugPrint('❌ Moderation: API Error ${response.statusCode} - ${response.body}');
        return true; // Fallback to allow if API fails (could be changed to block)
      }
    } catch (e) {
      debugPrint("❌ Moderation Error: $e");
      return true; // Fallback
    }
  }

  bool _isRisky(String? level) {
    return level == "LIKELY" || level == "VERY_LIKELY";
  }
}
