// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import '../main.dart'; // Para JoviTheme
import '../settings_service.dart'; // Para SettingsService

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  String _selectedOption = 'both';

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  void _loadPreference() async {
    final preference = await _settingsService.getUploadPreference();
    setState(() {
      _selectedOption = preference;
    });
  }

  void _updatePreference(String? newPreference) async {
    if (newPreference != null) {
      setState(() => _selectedOption = newPreference);
      await _settingsService.setUploadPreference(newPreference);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferencias de subida guardadas.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Subida'),
        backgroundColor: JoviTheme.blue,
        foregroundColor: JoviTheme.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permitir subida de contenido solo cuando el dispositivo esté conectado a:',
              style: JoviTheme.fontPoppins.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            
            RadioListTile<String>(
              title: const Text('Wi-Fi y Datos Móviles'),
              subtitle: const Text('Subirá contenido en cualquier conexión.'),
              value: 'both',
              groupValue: _selectedOption,
              onChanged: _updatePreference,
            ),
            RadioListTile<String>(
              title: const Text('Solo Wi-Fi'),
              subtitle: const Text('Guardará el contenido y lo subirá cuando detecte Wi-Fi.'),
              value: 'wifi',
              groupValue: _selectedOption,
              onChanged: _updatePreference,
            ),
            RadioListTile<String>(
              title: const Text('Solo Datos Móviles'),
              subtitle: const Text('Guardará el contenido y lo subirá cuando use Datos Móviles.'),
              value: 'cellular',
              groupValue: _selectedOption,
              onChanged: _updatePreference,
            ),
          ],
        ),
      ),
    );
  }
}