// lib/main.dart (VERSIÓN FINAL Y LIMPIA)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

// 🔒 IMPORTS DE FIREBASE Y SERVICIOS MODULARIZADOS
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'auth_service.dart';
import 'settings_service.dart'; // Importar SettingsService

// 📂 IMPORTS DE LAS PANTALLAS
import 'screens/auth_screens.dart';
import 'screens/app_screens.dart';
import 'screens/tutorial_screen.dart'; // Importar TutorialScreen


// ==========================================
// 1. CONFIGURACIÓN GLOBAL
// ==========================================
const String MAPBOX_ACCESS_TOKEN = "pk.eyJ1IjoiZGFuaWVsZ2FyYnJ1IiwiYSI6ImNtaWZxNmwxczA5dDAzZXIwMmsyMWgyYTkifQ.aauKhXogwH_1ZA6EDGYJCA";

class JoviTheme {
  static const Color yellow = Color(0xFFF8C41E);
  static const Color blue = Color(0xFF2A4D9B);
  static const Color red = Color(0xFFE34132);
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray = Color(0xFFF2F2F5);

  static TextStyle get fontBaloo => GoogleFonts.baloo2();
  static TextStyle get fontPoppins => GoogleFonts.poppins();
}

List<CameraDescription> cameras = [];

// Reemplaza la función main() en main.dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 INICIALIZAR FIREBASE
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase inicializado correctamente");
  } catch (e) {
    print("❌ Error al inicializar Firebase: $e");
  }

  // 🔥 SOLICITAR PERMISOS DE UBICACIÓN
  var locationStatus = await Permission.location.request();
  if (locationStatus.isDenied) {
    print("⚠️ Permiso de ubicación denegado");
  } else if (locationStatus.isGranted) {
    print("✅ Permiso de ubicación concedido");
  } else if (locationStatus.isPermanentlyDenied) {
    print("❌ Permiso de ubicación denegado permanentemente");
    // Aquí podrías abrir los ajustes con: await openAppSettings();
  }

  // 🔥 SOLICITAR PERMISOS DE CÁMARA
  var cameraStatus = await Permission.camera.request();
  if (cameraStatus.isDenied) {
    print("⚠️ Permiso de cámara denegado");
  } else if (cameraStatus.isGranted) {
    print("✅ Permiso de cámara concedido");
  }

  // 🔥 INICIALIZAR CÁMARAS
  try {
    cameras = await availableCameras();
    print("✅ ${cameras.length} cámaras disponibles");
  } catch (e) {
    print("❌ Error al cargar cámaras: $e");
  }

  // 🔥 CONFIGURAR MAPBOX
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
    return MaterialApp(
      title: 'Jovi AR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: JoviTheme.gray,
        colorScheme: ColorScheme.fromSeed(seedColor: JoviTheme.blue),
      ),
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
            // 🔍 CHECK TUTORIAL STATUS
            return FutureBuilder<bool>(
              future: SettingsService().isTutorialShown(user.uid),
              builder: (context, settingsSnapshot) {
                 if (!settingsSnapshot.hasData) {
                    return const Scaffold(body: Center(child: CircularProgressIndicator(color: JoviTheme.yellow)));
                 }
                 
                 final tutorialShown = settingsSnapshot.data ?? false;

                 if (tutorialShown) {
                   return MainLayout(username: user.email ?? "Usuario");
                 } else {
                   // Si no se ha visto, mostrar Tutorial. Al terminar, navegar a MainLayout.
                   return TutorialScreen(
                     userId: user.uid,
                     onDone: () {
                       // Forzar recarga o navegar directamente
                       Navigator.pushReplacement(
                         context, 
                         MaterialPageRoute(builder: (_) => MainLayout(username: user.email ?? "Usuario"))
                       );
                     }
                   );
                 }
              }
            );
          } else {
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

class _MainLayoutState extends State<MainLayout> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 5 Pestañas: Inicio, Social, Mapa, Galería, Perfil
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Desactivar swipe para evitar conflictos con mapas
        children: [
          HomeScreen(tabController: _tabController), // 0: Inicio Dashboard
          const SocialScreen(),                      // 1: Configuración / Social
          const MapGameScreen(),                     // 2: Mapa con Filtros
          const GalleryScreen(),                     // 3: Galería (Max 5)
          ProfileScreen(onSignOut: () => AuthService().signOut()), // 4: Perfil (+ Añadir Amigos)
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]
        ),
        child: SafeArea(
          child: TabBar(
            controller: _tabController,
            labelColor: JoviTheme.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: JoviTheme.yellow,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(LucideIcons.home), text: "Inicio"),
              Tab(icon: Icon(LucideIcons.users), text: "Social"), // Era "Configuración"
              Tab(icon: Icon(LucideIcons.map), text: "Mapa"),
              Tab(icon: Icon(LucideIcons.image), text: "Galería"),
              Tab(icon: Icon(LucideIcons.user), text: "Perfil"),
            ],
          ),
        ),
      ),
    );
  }
}