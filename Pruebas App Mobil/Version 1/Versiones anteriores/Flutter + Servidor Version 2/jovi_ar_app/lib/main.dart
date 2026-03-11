// lib/main.dart (VERSIÓN FINAL Y LIMPIA)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';

// 🔒 IMPORTS DE FIREBASE Y SERVICIOS MODULARIZADOS
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'auth_service.dart';

// 📂 IMPORTS DE LAS NUEVAS PANTALLAS MODULARIZADAS
import 'screens/auth_screens.dart';
import 'screens/app_screens.dart';


// ==========================================
// 1. CONFIGURACIÓN GLOBAL
// ==========================================
const String MAPBOX_ACCESS_TOKEN = "***REMOVED***";

class JoviTheme {
  static const Color yellow = Color(0xFFF8C41E);
  static const Color blue = Color(0xFF2A4D9B);
  static const Color red = Color(0xFFE34132);
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray = Color(0xFFF2F2F5);

  static TextStyle get fontBaloo => GoogleFonts.baloo2();
  static TextStyle get fontPoppins => GoogleFonts.poppins();
}

// DATOS GLOBALES (MOCK y Cámaras)
final List<Map<String, dynamic>> MOCK_STOPS = [];
List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 INICIALIZACIÓN DE FIREBASE
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("❌ Error al inicializar Firebase: $e");
  }

  // 🔒 SOLICITUD DE PERMISOS Y CÁMARAS
  await Permission.location.request();
  await Permission.camera.request();
  try {
    cameras = await availableCameras();
  } catch (e) {
    print("Error cámara: $e");
  }

  MapboxOptions.setAccessToken(MAPBOX_ACCESS_TOKEN);
  runApp(const JoviApp());
}

// ==========================================
// 2. PUNTO DE ENTRADA Y NAVEGACIÓN
// ==========================================

class JoviApp extends StatelessWidget {
  const JoviApp({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder escucha si el usuario está logueado o no
    return MaterialApp(
      title: 'Jovi AR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: StreamBuilder<User?>(
        stream: AuthService().user,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: JoviTheme.yellow)),
            );
          }

          final user = snapshot.data;

          if (user != null) {
            // Usuario logueado, ir al contenido principal
            return MainLayout(username: user.email ?? "Usuario");
          } else {
            // Usuario no logueado, ir a la pantalla de autenticación
            return const AuthScreen();
          }
        },
      ),
    );
  }
}

class MainLayout extends StatefulWidget {
  final String username;
  const MainLayout({super.key, required this.username});
  @override State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MapGameScreen(),
    const ARScannerScreen(),
    ProfileScreen(onSignOut: () => AuthService().signOut()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(LucideIcons.map), label: "Mapa"),
          NavigationDestination(icon: Icon(LucideIcons.scanLine), label: "AR"),
          NavigationDestination(icon: Icon(LucideIcons.user), label: "Perfil"),
        ],
      ),
    );
  }
}