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
// CONFIGURACIÓN Y TEMAS (JOVI BRAND)
// ==========================================

const String MAPBOX_ACCESS_TOKEN = "pk.eyJ1IjoiZGFuaWVsZ2FyYnJ1IiwiYSI6ImNtaWRmNHAwdTA0anYyanNjbHZibnBkcmUifQ.GWjrEAwP4-v8St3jYbSkzQ";
const String AVATAR_URL = "https://models.readyplayer.me/6924944848062250a4f9c961.glb";

class JoviTheme {
  static const Color yellow = Color(0xFFF8C41E);
  static const Color blue = Color(0xFF2A4D9B);
  static const Color red = Color(0xFFE34132);
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray = Color(0xFFF2F2F5);
  static const Color text = Color(0xFF1A1A1A);

  static TextStyle get fontBaloo => GoogleFonts.baloo2();
  static TextStyle get fontPoppins => GoogleFonts.poppins();
}

// Datos Mock
// Datos Mock - ZONA GLÒRIES BARCELONA
final List<Map<String, dynamic>> MOCK_STOPS = [
  { 
    "id": 1, 
    "title": "Torre Glòries", 
    "lat": 41.403629, 
    "lng": 2.187406, 
    "author": "Jean Nouvel", 
    "type": "Arquitectura", 
    "image": "https://images.unsplash.com/photo-1583422409516-2895a77efded?auto=format&fit=crop&q=80&w=500"
  },
  { 
    "id": 2, 
    "title": "Disseny Hub", 
    "lat": 41.402465, 
    "lng": 2.188835, 
    "author": "Museo", 
    "type": "Diseño", 
    "image": "https://images.unsplash.com/photo-1580666836703-65e796b93417?auto=format&fit=crop&q=80&w=500" 
  },
  { 
    "id": 3, 
    "title": "Westfield Glòries", 
    "lat": 41.4065, 
    "lng": 2.1915, 
    "author": "Centro", 
    "type": "Ocio", 
    "image": "https://images.unsplash.com/photo-1519567241046-7f570eee3c9e?auto=format&fit=crop&q=80&w=500"
  },
  { 
    "id": 4, 
    "title": "Els Encants", 
    "lat": 41.4010, 
    "lng": 2.1860, 
    "author": "Mercado", 
    "type": "Cultura", 
    "image": "https://images.unsplash.com/photo-1561344640-2453889cde5b?auto=format&fit=crop&q=80&w=500"
  },
];

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } catch (e) {
    print("Error camara: $e");
  }
  
  MapboxOptions.setAccessToken(MAPBOX_ACCESS_TOKEN);

  runApp(const JoviApp());
}

class JoviApp extends StatelessWidget {
  const JoviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jovi AR World',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: JoviTheme.blue,
        scaffoldBackgroundColor: JoviTheme.gray,
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}

// ==========================================
// 1. PANTALLA DE AUTH (Login)
// ==========================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final TextEditingController _emailController = TextEditingController();

  void _submit() {
    if (_emailController.text.isNotEmpty) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (c) => MainLayout(username: _emailController.text.split('@')[0]))
      );
    }
  }

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
              decoration: BoxDecoration(
                color: JoviTheme.yellow,
                shape: BoxShape.circle,
                border: Border.all(color: JoviTheme.blue, width: 4),
              ),
              child: const Icon(LucideIcons.palette, size: 48, color: JoviTheme.blue),
            ),
            const SizedBox(height: 16),
            Text("Jovi AR World", style: JoviTheme.fontBaloo.copyWith(fontSize: 32, fontWeight: FontWeight.bold, color: JoviTheme.blue)),
            const Text("Crea, explora y conecta con arte.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                filled: true,
                fillColor: JoviTheme.gray,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Contraseña",
                filled: true,
                fillColor: JoviTheme.gray,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: JoviTheme.yellow,
                  foregroundColor: JoviTheme.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _submit,
                child: Text(isLogin ? "Iniciar Sesión" : "Crear Cuenta", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? "¿No tienes cuenta? Regístrate" : "¿Ya tienes cuenta? Entra", style: const TextStyle(color: JoviTheme.blue)),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. LAYOUT PRINCIPAL (Tabs)
// ==========================================
class MainLayout extends StatefulWidget {
  final String username;
  const MainLayout({super.key, required this.username});
  @override State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const MapGameScreen(),
      const ARScannerScreen(), 
      ProfileScreen(username: widget.username),
    ];
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(LucideIcons.map, "Mapa", 0),
                GestureDetector(
                  onTap: () => _onTabTapped(1),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: JoviTheme.yellow,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10)],
                    ),
                    child: const Icon(LucideIcons.scanLine, color: JoviTheme.blue, size: 32),
                  ),
                ),
                _buildNavItem(LucideIcons.user, "Perfil", 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? JoviTheme.blue : Colors.grey),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? JoviTheme.blue : Colors.grey)),
        ],
      ),
    );
  }
}

// ==========================================
// 3. PANTALLA DE MAPA (JUEGO)
// ==========================================
class MapGameScreen extends StatefulWidget {
  const MapGameScreen({super.key});

  @override
  State<MapGameScreen> createState() => _MapGameScreenState();
}

class _MapGameScreenState extends State<MapGameScreen> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  
  StreamSubscription<geo.Position>? positionStreamSubscription;
  geo.Position? currentPosition;

  double userLat = 41.3851;
  double userLng = 2.1734;

  Map<String, dynamic>? selectedStop;
  bool isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLocationUpdates() async {
    setState(() => isLoadingLocation = true);
    
    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied || permission == geo.LocationPermission.deniedForever) {
        setState(() => isLoadingLocation = false);
        return;
      }
    }
    
    const geo.LocationSettings locationSettings = geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 1, 
    );

    positionStreamSubscription = geo.Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (geo.Position position) {
        currentPosition = position;
        userLat = position.latitude;
        userLng = position.longitude;
        
        if (mapboxMap != null) {
          mapboxMap!.setCamera(CameraOptions(
            center: Point(coordinates: Position(userLng, userLat)),
            zoom: 18.0,
            pitch: 60.0
          ));
          
          mapboxMap!.location.updateSettings(LocationComponentSettings(
            enabled: true,
            showAccuracyRing: true,
            pulsingEnabled: true,
          ));
        }
        _checkProximity();
        setState(() {
          isLoadingLocation = false;
        });
      },
      onError: (error) {
        print("Error en Geolocator: $error");
        setState(() => isLoadingLocation = false);
      }
    );
  }

_onMapCreated(MapboxMap map) async {
    mapboxMap = map;
    mapboxMap!.loadStyleURI("mapbox://styles/mapbox/streets-v12");

    // Usamos círculos rojos para verlos fácilmente
    final circleAnnotationManager = await map.annotations.createCircleAnnotationManager();
    _loadMarkers(circleAnnotationManager);
    
    // Configurar el punto azul (tu ubicación)
    mapboxMap!.location.updateSettings(LocationComponentSettings(
        enabled: true,
        showAccuracyRing: true,
        pulsingEnabled: true,
    ));
    
    // Si el GPS ya nos dio una posición, vamos ahí inmediatamente
    if (currentPosition != null) {
        mapboxMap!.setCamera(CameraOptions(
            center: Point(coordinates: Position(currentPosition!.longitude, currentPosition!.latitude)),
            zoom: 16.0, // Zoom cercano para ver calles
            pitch: 45.0 // Un poco inclinado para efecto 3D
        ));
    }
  }

// ✅ Correcto: Acepta el gestor de círculos
_loadMarkers(CircleAnnotationManager manager) async {
    for (var stop in MOCK_STOPS) {
       var options = CircleAnnotationOptions(
          geometry: Point(coordinates: Position(stop['lng'], stop['lat'])),
          circleColor: JoviTheme.red.value, 
          circleRadius: 12.0,
          circleStrokeWidth: 3.0,
          circleStrokeColor: Colors.white.value,
       );
       
       await manager.create(options);
    }
}

  void _checkProximity() {
    for (var stop in MOCK_STOPS) {
      double dLat = (stop['lat'] - userLat).abs();
      double dLng = (stop['lng'] - userLng).abs();
      
      if (dLat < 0.0003 && dLng < 0.0003) {
        if (selectedStop != stop) {
          setState(() => selectedStop = stop);
        }
        return;
      }
    }
    if (selectedStop != null) setState(() => selectedStop = null);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapWidget(
          styleUri: "mapbox://styles/mapbox/streets-v12",
          
          cameraOptions: CameraOptions(
            center: Point(coordinates: Position(userLng, userLat)),
            zoom: 18.0,
            pitch: 60.0
          ),
          onMapCreated: _onMapCreated,
        ),
        
        if (isLoadingLocation)
          Container(
            color: Colors.black54,
            child: const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: JoviTheme.yellow),
                SizedBox(height: 10),
                Text("Buscando ubicación...", style: TextStyle(color: Colors.white)),
              ],
            )),
          ),

        if (selectedStop != null)
          Positioned(
            bottom: 40, left: 20, right: 20,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: CachedNetworkImage(
                      imageUrl: selectedStop!['image'],
                      height: 120, width: double.infinity, fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[300]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(selectedStop!['title'], style: JoviTheme.fontBaloo.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: JoviTheme.blue)),
                        Text("Por ${selectedStop!['author']}", style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: JoviTheme.yellow,
                              foregroundColor: JoviTheme.blue
                            ),
                            icon: const Icon(LucideIcons.scanLine, size: 16),
                            label: const Text("Ver en AR"),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (c) => const ARScannerScreen()));
                            },
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }
} // 👈 ESTA LLAVE FALTABA - Cierra _MapGameScreenState

// ==========================================
// 4. PANTALLA DE AR SCANNER
// ==========================================
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
      controller!.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(
            child: CameraPreview(controller!),
          ),
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
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        Positioned(top: 0, left: 0, child: _corner()),
                        Positioned(top: 0, right: 0, child: RotatedBox(quarterTurns: 1, child: _corner())),
                        Positioned(bottom: 0, left: 0, child: RotatedBox(quarterTurns: 3, child: _corner())),
                        Positioned(bottom: 0, right: 0, child: RotatedBox(quarterTurns: 2, child: _corner())),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Obra escaneada!")));
                  },
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: JoviTheme.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 5),
                      boxShadow: [const BoxShadow(color: Colors.black45, blurRadius: 10)]
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          Positioned(
            top: 40, left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          )
        ],
      ),
    );
  }

  Widget _corner() {
    return Container(
      width: 30, height: 30,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: JoviTheme.yellow, width: 4),
          left: BorderSide(color: JoviTheme.yellow, width: 4),
        )
      ),
    );
  }
}

// ==========================================
// 5. PANTALLA DE PERFIL
// ==========================================
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
                    decoration: BoxDecoration(color: JoviTheme.yellow, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: [const BoxShadow(blurRadius: 10, color: Colors.black12)]),
                    alignment: Alignment.center,
                    child: Text(username.substring(0, 1).toUpperCase(), style: JoviTheme.fontBaloo.copyWith(fontSize: 40, color: Colors.white)),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Text("Explorador Principiante", style: TextStyle(color: Colors.grey)),
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
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: JoviTheme.red),
                    foregroundColor: JoviTheme.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AuthScreen()));
                  },
                  child: const Text("Cerrar Sesión"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: JoviTheme.gray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: JoviTheme.blue)),
        ],
      ),
    );
  }
}