// lib/settings_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _uploadPreference = 'uploadPreference';

  // Opciones: 'both', 'wifi', 'cellular'
  Future<String> getUploadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    // Valor por defecto: 'both' (Ambos)
    return prefs.getString(_uploadPreference) ?? 'both'; 
  }

  Future<void> setUploadPreference(String preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uploadPreference, preference);
  }
}