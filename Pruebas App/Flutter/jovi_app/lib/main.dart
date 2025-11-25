import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:camera/camera.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';

// ==========================================
// 1. CONFIGURACIÓN
// ==========================================
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

// DATOS MOCK - ESPAÑA Y BARCELONA EXPANDIDA
final List<Map<String, dynamic>> MOCK_STOPS = [
  // --- BARCELONA: ZONA GLÒRIES ---
  { "id": 1, "title": "Torre Glòries", "lat": 41.403629, "lng": 2.187406, "author": "Jean Nouvel", "type": "Arquitectura", "image": "https://images.unsplash.com/photo-1583422409516-2895a77efded?auto=format&fit=crop&q=80&w=500" },
  { "id": 2, "title": "Disseny Hub", "lat": 41.402465, "lng": 2.188835, "author": "Museo", "type": "Diseño", "image": "https://images.unsplash.com/photo-1580666836703-65e796b93417?auto=format&fit=crop&q=80&w=500" },
  { "id": 3, "title": "Westfield Glòries", "lat": 41.4065, "lng": 2.1915, "author": "Centro", "type": "Ocio", "image": "https://images.unsplash.com/photo-1519567241046-7f570eee3c9e?auto=format&fit=crop&q=80&w=500" },
  { "id": 4, "title": "Els Encants", "lat": 41.4010, "lng": 2.1860, "author": "Mercado", "type": "Cultura", "image": "https://images.unsplash.com/photo-1561344640-2453889cde5b?auto=format&fit=crop&q=80&w=500" },
  
  // --- BARCELONA CENTRO ---
  { "id": 20, "title": "Sagrada Família", "lat": 41.4036, "lng": 2.1744, "author": "Gaudí", "type": "Monumento", "image": "https://images.unsplash.com/photo-1545443761-1a8698a56f18?auto=format&fit=crop&q=80&w=500" },
  { "id": 21, "title": "Casa Batlló", "lat": 41.3917, "lng": 2.1649, "author": "Gaudí", "type": "Modernismo", "image": "https://images.unsplash.com/photo-1513374200575-4e647896530e?auto=format&fit=crop&q=80&w=500" },
  { "id": 22, "title": "Arc de Triomf", "lat": 41.3910, "lng": 2.1806, "author": "Vilaseca", "type": "Historia", "image": "https://images.unsplash.com/photo-1564663427023-422448627773?auto=format&fit=crop&q=80&w=500" },
  { "id": 23, "title": "Catedral de Barcelona", "lat": 41.3839, "lng": 2.1762, "author": "Gótico", "type": "Religión", "image": "https://images.unsplash.com/photo-1565067692138-348295249c0c?auto=format&fit=crop&q=80&w=500" },

  // --- MADRID ---
  { "id": 30, "title": "Puerta del Sol", "lat": 40.4168, "lng": -3.7038, "author": "Madrid", "type": "Plaza", "image": "https://images.unsplash.com/photo-1549309019-a1d77ae910fc?auto=format&fit=crop&q=80&w=500" },
  { "id": 31, "title": "Museo del Prado", "lat": 40.4138, "lng": -3.6921, "author": "Villanueva", "type": "Museo", "image": "https://images.unsplash.com/photo-1559563665-c9500072a02b?auto=format&fit=crop&q=80&w=500" },

  // --- VALENCIA ---
  { "id": 40, "title": "Ciudad de las Artes", "lat": 39.4549, "lng": -0.3505, "author": "Calatrava", "type": "Ciencia", "image": "https://images.unsplash.com/photo-1532596733622-f63555624e0a?auto=format&fit=crop&q=80&w=500" },

  // --- SEVILLA ---
  { "id": 50, "title": "Plaza de España", "lat": 37.3772, "lng": -5.9869, "author": "A. González", "type": "Historia", "image": "https://images.unsplash.com/photo-1555881400-74d7acaacd81?auto=format&fit=crop&q=80&w=500" },

  // --- NORTE ---
  { "id": 60, "title": "Museo Guggenheim", "lat": 43.2687, "lng": -2.9340, "author": "Gehry", "type": "Arte", "image": "https://images.unsplash.com/photo-1526524806212-477e51c7a43a?auto=format&fit=crop&q=80&w=500" },
];

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainLayout(username: "User"))),
          child: const Text("ENTRAR AL MAPA"),
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
  double userLat = 41.4036; 
  double userLng = 2.1874;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

_initLocation() async {
    geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high, 
        distanceFilter: 2
      )
    ).listen((pos) {
      // 1. Guardamos la posición para la lógica del juego
      currentPosition = pos;
      userLat = pos.latitude;
      userLng = pos.longitude;
      
      // 2. Solo la primera vez que detecta ubicación, quitamos la carga y centramos cámara
      if(mounted && isLoading) {
        setState(() => isLoading = false);
        mapboxMap?.setCamera(CameraOptions(
          center: Point(coordinates: Position(pos.longitude, pos.latitude)),
          zoom: 17.0, 
          pitch: 60.0, 
          bearing: 0.0
        ));
      }

      // ⚠️ HE BORRADO EL 'updateSettings' DE AQUÍ.
      // La configuración del avatar ya se hizo en _onMapCreated y no hay que tocarla más.
    });
  }

  _onMapCreated(MapboxMap map) async {
    mapboxMap = map;

    // 1. Estilo Outdoors (Verde)
    try { await mapboxMap!.loadStyleURI("mapbox://styles/mapbox/outdoors-v12"); } catch (e) {}

    // 2. Avatar 3D
    try {
      await mapboxMap?.location.updateSettings(LocationComponentSettings(
        enabled: true,
        pulsingEnabled: false,
        puckBearingEnabled: true,
        locationPuck: LocationPuck(
          locationPuck3D: LocationPuck3D(
            modelUri: "asset://assets/avatar.glb", 
            modelScale: [50.0, 50.0, 50.0],
            modelRotation: [0.0, 0.0, 0.0],
          )
        )
      ));
    } catch(e) {}

    // 3. Puntos Rojos
    circleAnnotationManager = await map.annotations.createCircleAnnotationManager();
    await _drawPoints(); 

    // 4. Clics
    circleAnnotationManager?.addOnCircleAnnotationClickListener(
      MyAnnotationClickListener(onTap: (annotation) {
        try {
          final stop = MOCK_STOPS.firstWhere((s) => 
            (s['lat'] - annotation.geometry.coordinates.lat).abs() < 0.0001 &&
            (s['lng'] - annotation.geometry.coordinates.lng).abs() < 0.0001
          );
          setState(() => selectedStop = stop);
        } catch (e) {}
      })
    );
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
        MapWidget(
          key: const ValueKey("mapWidget"),
          // 👇 FORZAMOS EL TOKEN AQUÍ PARA QUE NO FALLE
          //resourceOptions: ResourceOptions(accessToken: MAPBOX_ACCESS_TOKEN),
          styleUri: "mapbox://styles/mapbox/outdoors-v12",
          textureView: true, // IMPORTANTE PARA SAMSUNG
          cameraOptions: CameraOptions(
            center: Point(coordinates: Position(userLng, userLat)),
            zoom: 15.0,
            pitch: 0.0
          ), 
          onMapCreated: _onMapCreated,
        ),
        
        if (isLoading)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator(color: JoviTheme.yellow)),
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

// 4. AR SCREEN
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
        Positioned(top: 40, left: 20, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)))
      ]),
    );
  }
}