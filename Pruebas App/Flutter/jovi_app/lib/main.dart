import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:camera/camera.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';

const String MAPBOX_ACCESS_TOKEN = "pk.eyJ1IjoiZGFuaWVsZ2FyYnJ1IiwiYSI6ImNtaWVpdXozMzAydTgzZXIxdWVyYjN1NDAifQ.DlQ0hO6UMGSde4aLxTPKSg";

class JoviTheme {
  static const Color yellow = Color(0xFFF8C41E);
  static const Color blue = Color(0xFF2A4D9B);
  static const Color red = Color(0xFFE34132);
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray = Color(0xFFF2F2F5);
  
  static TextStyle get fontBaloo => GoogleFonts.baloo2();
  static TextStyle get fontPoppins => GoogleFonts.poppins();
}

final List<Map<String, dynamic>> MOCK_STOPS = [
  { "id": 1, "title": "Torre Glòries", "lat": 41.403629, "lng": 2.187406, "author": "Jean Nouvel", "type": "Arquitectura", "image": "https://images.unsplash.com/photo-1583422409516-2895a77efded?auto=format&fit=crop&q=80&w=500" },
  { "id": 2, "title": "Disseny Hub", "lat": 41.402465, "lng": 2.188835, "author": "Museo", "type": "Diseño", "image": "https://images.unsplash.com/photo-1580666836703-65e796b93417?auto=format&fit=crop&q=80&w=500" },
  { "id": 3, "title": "Westfield Glòries", "lat": 41.4065, "lng": 2.1915, "author": "Centro", "type": "Ocio", "image": "https://images.unsplash.com/photo-1519567241046-7f570eee3c9e?auto=format&fit=crop&q=80&w=500" },
  { "id": 4, "title": "Els Encants", "lat": 41.4010, "lng": 2.1860, "author": "Mercado", "type": "Cultura", "image": "https://images.unsplash.com/photo-1561344640-2453889cde5b?auto=format&fit=crop&q=80&w=500" },
];

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pedir permisos uno por uno al inicio
  await Permission.location.request();
  await Permission.camera.request();
  
  try { cameras = await availableCameras(); } catch (e) { print("Error camara: $e"); }
  
  MapboxOptions.setAccessToken(MAPBOX_ACCESS_TOKEN);
  runApp(const JoviApp());
}

class JoviApp extends StatelessWidget {
  const JoviApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jovi AR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(color: JoviTheme.yellow, shape: BoxShape.circle, border: Border.all(color: JoviTheme.blue, width: 4)),
              child: const Icon(LucideIcons.palette, size: 48, color: JoviTheme.blue),
            ),
            const SizedBox(height: 16),
            Text("Jovi AR World", style: JoviTheme.fontBaloo.copyWith(fontSize: 32, fontWeight: FontWeight.bold, color: JoviTheme.blue)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: JoviTheme.yellow, foregroundColor: JoviTheme.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainLayout(username: "User"))),
                child: const Text("Entrar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
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
  final List<Widget> _pages = [const MapGameScreen(), const ARScannerScreen(), const Center(child: Text("Perfil"))];

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

class MapGameScreen extends StatefulWidget {
  const MapGameScreen({super.key});
  @override State<MapGameScreen> createState() => _MapGameScreenState();
}

class _MapGameScreenState extends State<MapGameScreen> {
  MapboxMap? mapboxMap;
  CircleAnnotationManager? circleAnnotationManager;
  geo.Position? currentPosition;
  Map<String, dynamic>? selectedStop;
  bool isLoading = true;
  bool mapReady = false;
  double userLat = 41.4036; 
  double userLng = 2.1874;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  _initLocation() async {
    print("📡 Iniciando ubicación...");
    var status = await Permission.location.request();
    if (!status.isGranted) {
      print("❌ Permiso de ubicación denegado");
      setState(() => isLoading = false);
      return;
    }
    
    geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 10,
      )
    ).listen((pos) {
      print("📍 Nueva ubicación: ${pos.latitude}, ${pos.longitude}");
      currentPosition = pos;
      userLat = pos.latitude;
      userLng = pos.longitude;
      
      if(mounted && isLoading) {
        setState(() => isLoading = false);
        print("🔄 Actualizando cámara con ubicación real");
        
        mapboxMap?.setCamera(CameraOptions(
          center: Point(coordinates: Position(pos.longitude, pos.latitude)),
          zoom: 16.0, 
          pitch: 0.0,
          bearing: 0.0
        ));
      }
    });
  }

_onMapCreated(MapboxMap map) async {
    print("🗺️ Mapa creado");
    mapboxMap = map;
    
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // 1. Configurar la cámara inicial
      await mapboxMap?.setCamera(CameraOptions(
        center: Point(coordinates: Position(userLng, userLat)),
        zoom: 17.0, // Zoom más cercano para ver el muñeco
        pitch: 60.0, // Inclinación 3D
        bearing: 0.0
      ));
      
      print("🎥 Cámara configurada");

      // 2. CONFIGURAR EL AVATAR 3D (Aquí está el cambio clave)
      await mapboxMap?.location.updateSettings(LocationComponentSettings(
        enabled: true, 
        pulsingEnabled: false, // Desactivamos el pulso azul para ver el muñeco
        puckBearingEnabled: true,
        
        // Definimos el muñeco 3D
        locationPuck: LocationPuck(
          locationPuck3D: LocationPuck3D(
            // La ruta debe coincidir con tu pubspec.yaml
            modelUri: "asset://assets/avatar.glb", 
            // Aumentamos la escala porque a veces se ven muy pequeños
            modelScale: [100.0, 100.0, 100.0], 
            // Rotación para que mire al frente si sale tumbado
            modelRotation: [0.0, 0.0, 0.0],
          )
        )
      ));
      
      print("📍 Avatar 3D configurado");

      // 3. Cargar los puntos rojos (Marcadores)
      circleAnnotationManager = await map.annotations.createCircleAnnotationManager();
      print("⭕ Gestor de anotaciones creado");

      await _drawPoints(); 
      print("🎯 Puntos dibujados");

      // 4. Configurar el clic en los puntos
      circleAnnotationManager?.addOnCircleAnnotationClickListener(
        MyAnnotationClickListener(onTap: (annotation) {
          try {
            final stop = MOCK_STOPS.firstWhere((s) => 
              (s['lat'] - annotation.geometry.coordinates.lat).abs() < 0.0001 &&
              (s['lng'] - annotation.geometry.coordinates.lng).abs() < 0.0001
            );
            setState(() => selectedStop = stop);
          } catch (e) { print("No encontrado"); }
        })
      );
      
      setState(() => mapReady = true);
      print("✅ Mapa completamente listo");
      
    } catch (e) {
      print("❌ Error configurando mapa: $e");
    }
  }

  _drawPoints() async {
    await circleAnnotationManager?.deleteAll();
    for (var stop in MOCK_STOPS) {
      await circleAnnotationManager?.create(CircleAnnotationOptions(
        geometry: Point(coordinates: Position(stop['lng'], stop['lat'])),
        circleColor: JoviTheme.red.value,
        circleRadius: 15.0, 
        circleStrokeWidth: 4.0,
        circleStrokeColor: Colors.white.value,
      ));
    }
  }


@override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.white, // Fondo por si el mapa tarda
          child: MapWidget(
            key: const ValueKey("mapWidget"),
            // Usamos el estilo estándar de calles v12
            styleUri: "mapbox://styles/mapbox/streets-v12", 
            
            // MANTENEMOS ESTO EN TRUE PARA SAMSUNG
            textureView: true, 
            
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(userLng, userLat)),
              zoom: 15.0,
              pitch: 0.0 // Sin inclinación al principio para asegurar renderizado
            ), 
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: (_) => print("🎨 ESTILO CARGADO OK"),
            onMapLoadErrorListener: (err) => print("🚨 ERROR MAPA: ${err.message}"),
          ),
        ),
        
        if (isLoading || !mapReady)
          Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: JoviTheme.yellow),
                  const SizedBox(height: 16),
                  Text(
                    isLoading ? "Obteniendo ubicación..." : "Cargando mapa...",
                    style: const TextStyle(color: JoviTheme.blue, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

        if (selectedStop != null)
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: CachedNetworkImage(
                      imageUrl: selectedStop!['image'],
                      height: 150, width: double.infinity, fit: BoxFit.cover,
                      placeholder: (c, u) => Container(color: Colors.grey[300]),
                      errorWidget: (c, u, e) => Container(color: Colors.grey, child: const Icon(Icons.error)),
                    ),
                  ),
                  ListTile(
                    title: Text(selectedStop!['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    subtitle: Text(selectedStop!['type']),
                    trailing: IconButton(
                      icon: const Icon(Icons.close), 
                      onPressed: () => setState(() => selectedStop = null)
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: JoviTheme.yellow, foregroundColor: JoviTheme.blue, padding: const EdgeInsets.all(12)),
                        icon: const Icon(LucideIcons.scanLine),
                        label: const Text("Ver en AR"),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ARScannerScreen())),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
      ],
    );
  }
}

class MyAnnotationClickListener implements OnCircleAnnotationClickListener {
  final Function(CircleAnnotation) onTap;
  MyAnnotationClickListener({required this.onTap});
  @override
  void onCircleAnnotationClick(CircleAnnotation annotation) {
    onTap(annotation);
  }
}

class ARScannerScreen extends StatefulWidget {
  const ARScannerScreen({super.key});
  @override State<ARScannerScreen> createState() => _ARScannerScreenState();
}

class _ARScannerScreenState extends State<ARScannerScreen> {
  CameraController? controller;
  @override
  void initState() {
    super.initState();
    if (cameras.isNotEmpty) {
      controller = CameraController(cameras[0], ResolutionPreset.high);
      controller!.initialize().then((_) => setState(() {}));
    }
  }
  @override
  void dispose() { controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) return const Scaffold(backgroundColor: Colors.black);
    return Scaffold(
      body: Stack(children: [
        CameraPreview(controller!),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30)),
                child: const Text("Apunta a una superficie plana", style: TextStyle(color: Colors.white)),
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 250, height: 250,
                  decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.5), width: 1), borderRadius: BorderRadius.circular(20)),
                  child: Stack(children: [
                     Positioned(top: 0, left: 0, child: _corner()),
                     Positioned(top: 0, right: 0, child: RotatedBox(quarterTurns: 1, child: _corner())),
                     Positioned(bottom: 0, left: 0, child: RotatedBox(quarterTurns: 3, child: _corner())),
                     Positioned(bottom: 0, right: 0, child: RotatedBox(quarterTurns: 2, child: _corner())),
                  ]),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Escaneado!"))),
                child: Container(width: 80, height: 80, decoration: BoxDecoration(color: JoviTheme.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 5))),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        Positioned(top: 40, left: 20, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)))
      ]),
    );
  }
  Widget _corner() => Container(width: 30, height: 30, decoration: const BoxDecoration(border: Border(top: BorderSide(color: JoviTheme.yellow, width: 4), left: BorderSide(color: JoviTheme.yellow, width: 4))));
}

class ProfileScreen extends StatelessWidget {
  final String username;
  const ProfileScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Mi Perfil", style: JoviTheme.fontBaloo.copyWith(fontSize: 32, fontWeight: FontWeight.bold, color: JoviTheme.blue)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: JoviTheme.yellow, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                    alignment: Alignment.center,
                    child: Text(username.substring(0, 1).toUpperCase(), style: JoviTheme.fontBaloo.copyWith(fontSize: 40, color: Colors.white)),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Text("Explorador", style: TextStyle(color: Colors.grey)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 32),
              _statCard("Obras Escaneadas", "12"),
              const SizedBox(height: 12),
              _statCard("Kilómetros AR", "4.5 km"),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: JoviTheme.red), foregroundColor: JoviTheme.red),
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AuthScreen())),
                  child: const Text("Cerrar Sesión"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
  Widget _statCard(String label, String value) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: JoviTheme.gray, borderRadius: BorderRadius.circular(16)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: JoviTheme.blue)),
    ]),
  );
}