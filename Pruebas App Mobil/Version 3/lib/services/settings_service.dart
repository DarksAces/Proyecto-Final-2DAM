import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('es', 'ES');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    
    final langCode = prefs.getString('languageCode') ?? 'es';
    _locale = Locale(langCode);
    notifyListeners();
  }

  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  void setLanguage(String langCode) async {
    _locale = Locale(langCode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', langCode);
  }

  // Simple Translation Map
  static final Map<String, Map<String, String>> _translations = {
    'es': {
      'settings_title': 'Configuración Avanzada',
      'appearance': 'APARIENCIA',
      'dark_mode': 'Modo Oscuro',
      'language': 'Idioma',
      'security': 'SEGURIDAD',
      'preferences': 'PREFERENCIAS',
      'change_password': 'Cambiar Contraseña',
      'sign_out': 'Cerrar Sesión',
      'delete_account': 'Eliminar Cuenta permanentemente',
    },
    'en': {
      'settings_title': 'Advanced Settings',
      'appearance': 'APPEARANCE',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'security': 'SECURITY',
      'preferences': 'PREFERENCES',
      'change_password': 'Change Password',
      'sign_out': 'Sign Out',
      'delete_account': 'Delete Account permanently',
    },
    'fr': {
      'settings_title': 'Paramètres Avancés',
      'appearance': 'APPARENCE',
      'dark_mode': 'Mode Sombre',
      'language': 'Langue',
      'security': 'SÉCURITÉ',
      'preferences': 'PRÉFÉRENCES',
      'change_password': 'Changer le mot de passe',
      'sign_out': 'Déconnexion',
      'delete_account': 'Supprimer le compte définitivement',
    }
  };

  String translate(String key) {
    return _translations[locale.languageCode]?[key] ?? _translations['es']![key] ?? key;
  }
}
