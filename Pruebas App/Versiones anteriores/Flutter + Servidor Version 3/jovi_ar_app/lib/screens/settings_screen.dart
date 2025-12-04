// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart'; 
import '../settings_service.dart';
import '../api_service.dart'; 

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
        const SnackBar(content: Text('Preferencias guardadas.')),
      );
    }
  }

  // FUNCIÓN PARA ARREGLAR TU PROPIO NOMBRE EN LA BASE DE DATOS
  Future<void> _syncMyProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Cogemos los datos que ya tienes en tu login (Auth)
    final nickname = user.displayName ?? "Usuario Recuperado";
    final email = user.email ?? "";

    // Los guardamos a la fuerza en la base de datos pública
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'nickname': nickname,
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Perfil sincronizado. Ahora eres visible como: $nickname"), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: JoviTheme.blue,
        foregroundColor: JoviTheme.white,
      ),
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferencias de Subida',
              style: JoviTheme.fontPoppins.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            RadioListTile<String>(
              title: const Text('Wi-Fi y Datos Móviles'),
              value: 'both',
              groupValue: _selectedOption,
              onChanged: _updatePreference,
            ),
            RadioListTile<String>(
              title: const Text('Solo Wi-Fi'),
              value: 'wifi',
              groupValue: _selectedOption,
              onChanged: _updatePreference,
            ),
            RadioListTile<String>(
              title: const Text('Solo Datos Móviles'),
              value: 'cellular',
              groupValue: _selectedOption,
              onChanged: _updatePreference,
            ),

            const Divider(height: 30, thickness: 2),

            // ==========================================
            // ZONA DE REPARACIÓN DE PERFIL (SOLUCIÓN USUARIO DESCONOCIDO)
            // ==========================================
            Text(
              'Mi Cuenta',
              style: JoviTheme.fontPoppins.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: JoviTheme.blue),
            ),
            const SizedBox(height: 10),
             Text(
              'Si apareces como "Desconocido" en las listas, pulsa aquí:',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[100],
                  foregroundColor: JoviTheme.blue,
                  padding: const EdgeInsets.all(15),
                ),
                icon: const Icon(LucideIcons.refreshCw),
                label: const Text("SINCRONIZAR MI PERFIL"),
                onPressed: _syncMyProfile, // <--- ESTO ARREGLA EL NOMBRE
              ),
            ),

            const SizedBox(height: 30),

            // ==========================================
            // ZONA DE MANTENIMIENTO (SITIOS)
            // ==========================================
            Text(
              'Mantenimiento',
              style: JoviTheme.fontPoppins.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[800]),
            ),
            const SizedBox(height: 10),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(15),
                ),
                icon: const Icon(LucideIcons.wrench),
                label: const Text("REPARAR SITIOS SIN AUTOR"),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🛠️ Reparando...")));
                  final count = await ApiService().asignarAutorASitiosHuerfanos();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ ¡Listo! $count sitios recuperados.")));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}