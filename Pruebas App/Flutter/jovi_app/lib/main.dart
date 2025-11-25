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
// Tu token nuevo (el que termina en KSg)
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

// DATOS MOCK - ZONA GLÒRIES / MERIDIANA
// Datos Mock - RUTA GLÒRIES -> SAGRERA -> FABRA I PUIG
// DATOS MOCK - ÁREA METROPOLITANA DE BARCELONA
// DATOS MOCK - ÁREA METROPOLITANA DE BARCELONA
// DATOS MOCK - ÁREA METROPOLITANA DE BARCELONA (AMPLIADO)
final List<Map<String, dynamic>> MOCK_STOPS = [
  // --- ZONA GLÒRIES / MERIDIANA (BARCELONA) - SIN CAMBIOS ---
  { "id": 1, "title": "Torre Glòries", "lat": 41.403629, "lng": 2.187406, "author": "Jean Nouvel", "type": "Arquitectura", "image": "https://images.unsplash.com/photo-1583422409516-2895a77efded?auto=format&fit=crop&q=80&w=500" },
  { "id": 2, "title": "Disseny Hub", "lat": 41.402465, "lng": 2.188835, "author": "Museo", "type": "Diseño", "image": "https://images.unsplash.com/photo-1580666836703-65e796b93417?auto=format&fit=crop&q=80&w=500" },
  { "id": 3, "title": "Westfield Glòries", "lat": 41.4065, "lng": 2.1915, "author": "Centro", "type": "Ocio", "image": "https://images.unsplash.com/photo-1519567241046-7f570eee3c9e?auto=format&fit=crop&q=80&w=500" },
  { "id": 4, "title": "Els Encants", "lat": 41.4010, "lng": 2.1860, "author": "Mercado", "type": "Cultura", "image": "https://images.unsplash.com/photo-1561344640-2453889cde5b?auto=format&fit=crop&q=80&w=500" },
  { "id": 5, "title": "Parc del Clot", "lat": 41.4095, "lng": 2.1878, "author": "Dani Freixes", "type": "Parque", "image": "https://images.unsplash.com/photo-1596394516093-501ba68a0ba6?auto=format&fit=crop&q=80&w=500" },
  { "id": 6, "title": "Pont de Bac de Roda", "lat": 41.4162, "lng": 2.1905, "author": "S. Calatrava", "type": "Puente", "image": "https://images.unsplash.com/photo-1543424668-3e6208726204?auto=format&fit=crop&q=80&w=500" },
  { "id": 7, "title": "Nau Ivanow", "lat": 41.4263, "lng": 2.1938, "author": "Fundación", "type": "Arte", "image": "https://images.unsplash.com/photo-1569336415962-a4bd9f69cd83?auto=format&fit=crop&q=80&w=500" },
  { "id": 8, "title": "Estació La Sagrera", "lat": 41.4214, "lng": 2.1865, "author": "Renfe", "type": "Transporte", "image": "https://images.unsplash.com/photo-1474487548417-781cb71495f3?auto=format&fit=crop&q=80&w=500" },
  { "id": 9, "title": "Fabra i Coats", "lat": 41.4315, "lng": 2.1910, "author": "Fàbrica", "type": "Creatividad", "image": "https://images.unsplash.com/photo-1534239689755-ebd72d6561c0?auto=format&fit=crop&q=80&w=500" },
  { "id": 10, "title": "Casa Bloc", "lat": 41.4305, "lng": 2.1875, "author": "GATCPAC", "type": "Arquitectura", "image": "https://images.unsplash.com/photo-1518780664697-55e3ad937233?auto=format&fit=crop&q=80&w=500" },
  { "id": 11, "title": "Parc de Can Dragó", "lat": 41.4345, "lng": 2.1840, "author": "Ruiz-Geli", "type": "Parque", "image": "https://images.unsplash.com/photo-1612528443702-f6741f70e049?auto=format&fit=crop&q=80&w=500" },
  { "id": 12, "title": "SOM Multiespai", "lat": 41.4362, "lng": 2.1815, "author": "Heron", "type": "Ocio", "image": "https://images.unsplash.com/photo-1516455590571-18256e5bb9ff?auto=format&fit=crop&q=80&w=500" },
  { "id": 13, "title": "Església Sant Andreu", "lat": 41.4368, "lng": 2.1902, "author": "P. Falqués", "type": "Historia", "image": "https://images.unsplash.com/photo-1548625361-a8a1e7f540a9?auto=format&fit=crop&q=80&w=500" },

  // --- BARCELONA CENTRO - SIN CAMBIOS ---
  { "id": 20, "title": "Sagrada Família", "lat": 41.4036, "lng": 2.1744, "author": "Gaudí", "type": "Monumento", "image": "https://images.unsplash.com/photo-1545443761-1a8698a56f18?auto=format&fit=crop&q=80&w=500" },
  { "id": 21, "title": "Casa Batlló", "lat": 41.3917, "lng": 2.1649, "author": "Gaudí", "type": "Modernismo", "image": "https://images.unsplash.com/photo-1513374200575-4e647896530e?auto=format&fit=crop&q=80&w=500" },
  { "id": 22, "title": "Arc de Triomf", "lat": 41.3910, "lng": 2.1806, "author": "Vilaseca", "type": "Historia", "image": "https://images.unsplash.com/photo-1564663427023-422448627773?auto=format&fit=crop&q=80&w=500" },
  { "id": 23, "title": "Catedral de Barcelona", "lat": 41.3839, "lng": 2.1762, "author": "Gótico", "type": "Religión", "image": "https://images.unsplash.com/photo-1565067692138-348295249c0c?auto=format&fit=crop&q=80&w=500" },
  { "id": 24, "title": "Plaça Catalunya", "lat": 41.3870, "lng": 2.1700, "author": "Urbanismo", "type": "Plaza", "image": "https://images.unsplash.com/photo-1587135941948-670b381f08ce?auto=format&fit=crop&q=80&w=500" },

  // --- BADALONA (AMPLIADO) ---
  { "id": 30, "title": "Pont del Petroli", "lat": 41.4325, "lng": 2.2530, "author": "Ingeniería", "type": "Icono", "image": "https://images.unsplash.com/photo-1620749565072-779936507485?auto=format&fit=crop&q=80&w=500" },
  { "id": 31, "title": "Fàbrica Anís del Mono", "lat": 41.4348, "lng": 2.2460, "author": "Modernista", "type": "Industria", "image": "https://images.unsplash.com/photo-1572297794908-f00462907341?auto=format&fit=crop&q=80&w=500" },
  { "id": 32, "title": "Parc de Pompeu Fabra", "lat": 41.4465, "lng": 2.2425, "author": "Jardín", "type": "Parque", "image": "https://images.unsplash.com/photo-1598885511444-def9d638d0a2?auto=format&fit=crop&q=80&w=500" },
  { "id": 33, "title": "Museu de Badalona", "lat": 41.4510, "lng": 2.2475, "author": "Romano", "type": "Museo", "image": "https://images.unsplash.com/photo-1590664216212-62e7637d1699?auto=format&fit=crop&q=80&w=500" },
  { "id": 34, "title": "Dalt de la Vila", "lat": 41.4525, "lng": 2.2470, "author": "Histórico", "type": "Barrio", "image": "https://images.unsplash.com/photo-1558694440-03a7c15698dd?auto=format&fit=crop&q=80&w=500" },
  { "id": 35, "title": "Parc de Can Solei", "lat": 41.4550, "lng": 2.2520, "author": "Ca l'Arnús", "type": "Parque", "image": "https://images.unsplash.com/photo-1500964757637-c85e8a162699?auto=format&fit=crop&q=80&w=500" },
  { "id": 36, "title": "Magic Badalona", "lat": 41.4410, "lng": 2.2360, "author": "Basket", "type": "Deporte", "image": "https://images.unsplash.com/photo-1546519638-68e109498ee2?auto=format&fit=crop&q=80&w=500" },

  // --- SANTA COLOMA DE GRAMENET (AMPLIADO) ---
  { "id": 40, "title": "Església Major", "lat": 41.4528, "lng": 2.2085, "author": "Neogótico", "type": "Religión", "image": "https://images.unsplash.com/photo-1548544149-4835e62ee5b3?auto=format&fit=crop&q=80&w=500" },
  { "id": 41, "title": "Parc Fluvial Besòs", "lat": 41.4450, "lng": 2.2000, "author": "Naturaleza", "type": "Río", "image": "https://images.unsplash.com/photo-1597934035381-487d919c4796?auto=format&fit=crop&q=80&w=500" },
  { "id": 42, "title": "Can Roig i Torres", "lat": 41.4515, "lng": 2.2098, "author": "Modernista", "type": "Auditorio", "image": "https://images.unsplash.com/photo-1518134972081-8d993270029c?auto=format&fit=crop&q=80&w=500" },
  { "id": 43, "title": "Museu Torre Balldovina", "lat": 41.4512, "lng": 2.2070, "author": "Medieval", "type": "Museo", "image": "https://images.unsplash.com/photo-1583851743028-f716308825a7?auto=format&fit=crop&q=80&w=500" },
  { "id": 44, "title": "Recinte Torribera", "lat": 41.4610, "lng": 2.2160, "author": "Noucentisme", "type": "Arquitectura", "image": "https://images.unsplash.com/photo-1466273913337-8f3e2c563995?auto=format&fit=crop&q=80&w=500" },

  // --- SANT FELIU DE LLOBREGAT (AMPLIADO) ---
  { "id": 50, "title": "Palau Falguera", "lat": 41.3835, "lng": 2.0430, "author": "Histórico", "type": "Palacio", "image": "https://images.unsplash.com/photo-1568605114967-8130f3a36994?auto=format&fit=crop&q=80&w=500" },
  { "id": 51, "title": "La Catedral", "lat": 41.3810, "lng": 2.0465, "author": "Religión", "type": "Catedral", "image": "https://images.unsplash.com/photo-1572506943368-68f272653854?auto=format&fit=crop&q=80&w=500" },
  { "id": 52, "title": "Parc de Torreblanca", "lat": 41.3775, "lng": 2.0580, "author": "Romántico", "type": "Jardín", "image": "https://images.unsplash.com/photo-1596896437629-c15491079c87?auto=format&fit=crop&q=80&w=500" },
  { "id": 53, "title": "Parc de les Roses", "lat": 41.3860, "lng": 2.0490, "author": "Rosaleda", "type": "Parque", "image": "https://images.unsplash.com/photo-1496857239036-1fb137683000?auto=format&fit=crop&q=80&w=500" },
  { "id": 54, "title": "Ruta Modernista", "lat": 41.3825, "lng": 2.0450, "author": "Raspall", "type": "Cultura", "image": "https://images.unsplash.com/photo-1555685812-4b943f1cb0eb?auto=format&fit=crop&q=80&w=500" },

  // --- L'HOSPITALET DE LLOBREGAT (AMPLIADO) ---
  { "id": 60, "title": "Fira Gran Via", "lat": 41.3545, "lng": 2.1270, "author": "Toyo Ito", "type": "Feria", "image": "https://images.unsplash.com/photo-1486325212027-8081e485255e?auto=format&fit=crop&q=80&w=500" },
  { "id": 61, "title": "Torres Porta Fira", "lat": 41.3560, "lng": 2.1255, "author": "Ito/b720", "type": "Rascacielos", "image": "https://images.unsplash.com/photo-1479839672679-a46483c0e7c8?auto=format&fit=crop&q=80&w=500" },
  { "id": 62, "title": "Parc de Bellvitge", "lat": 41.3510, "lng": 2.1120, "author": "Urbano", "type": "Parque", "image": "https://images.unsplash.com/photo-1588524286879-22df98722655?auto=format&fit=crop&q=80&w=500" },
  { "id": 63, "title": "Centre d'Art Tecla Sala", "lat": 41.3630, "lng": 2.1180, "author": "Fàbrica", "type": "Arte", "image": "https://images.unsplash.com/photo-1507643179173-39db4f9719ae?auto=format&fit=crop&q=80&w=500" },
  { "id": 64, "title": "Parc de Can Buxeres", "lat": 41.3680, "lng": 2.1050, "author": "Palacete", "type": "Jardín", "image": "https://images.unsplash.com/photo-1585938389612-a552a28d6914?auto=format&fit=crop&q=80&w=500" },
  { "id": 65, "title": "Plaça d'Europa", "lat": 41.3585, "lng": 2.1230, "author": "Negocios", "type": "Urbanismo", "image": "https://images.unsplash.com/photo-1465809873722-b4bf7208d2b1?auto=format&fit=crop&q=80&w=500" },

  // --- CORNELLÀ DE LLOBREGAT (NUEVO) ---
  { "id": 70, "title": "RCDE Stadium", "lat": 41.3470, "lng": 2.0750, "author": "RCD Espanyol", "type": "Deporte", "image": "https://images.unsplash.com/photo-1522778119026-d647f0565c6a?auto=format&fit=crop&q=80&w=500" },
  { "id": 71, "title": "Parc de Can Mercader", "lat": 41.3580, "lng": 2.0850, "author": "Romántico", "type": "Trenet", "image": "https://images.unsplash.com/photo-1449034446853-66c86144b0ad?auto=format&fit=crop&q=80&w=500" },
  { "id": 72, "title": "Museu Agbar de les Aigües", "lat": 41.3550, "lng": 2.0650, "author": "Amargós", "type": "Modernismo", "image": "https://images.unsplash.com/photo-1565619624098-e6598cb1df0c?auto=format&fit=crop&q=80&w=500" },
  { "id": 73, "title": "La Pirámide (Fira)", "lat": 41.3520, "lng": 2.0780, "author": "Icono", "type": "Evento", "image": "https://images.unsplash.com/photo-1470058869958-2a77ade41c02?auto=format&fit=crop&q=80&w=500" },

  // --- EL PRAT DE LLOBREGAT (NUEVO) ---
  { "id": 80, "title": "Mirador dels Avions", "lat": 41.2950, "lng": 2.1080, "author": "AENA", "type": "Spotting", "image": "https://images.unsplash.com/photo-1436491865332-7a61a109cc05?auto=format&fit=crop&q=80&w=500" },
  { "id": 81, "title": "CRAM (Fauna Marina)", "lat": 41.2850, "lng": 2.1150, "author": "Fundación", "type": "Naturaleza", "image": "https://images.unsplash.com/photo-1582967788606-a171f1080cae?auto=format&fit=crop&q=80&w=500" },
  { "id": 82, "title": "La Ricarda (Casa Gomis)", "lat": 41.2900, "lng": 2.1020, "author": "A. Bonet", "type": "Arquitectura", "image": "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&q=80&w=500" },

  // --- SANT CUGAT DEL VALLÈS (NUEVO) ---
  { "id": 90, "title": "Monestir de Sant Cugat", "lat": 41.4730, "lng": 2.0850, "author": "Románico", "type": "Historia", "image": "https://images.unsplash.com/photo-1548625361-a8a1e7f540a9?auto=format&fit=crop&q=80&w=500" },
  { "id": 91, "title": "Mercantic", "lat": 41.4680, "lng": 2.0750, "author": "Vintage", "type": "Mercado", "image": "https://images.unsplash.com/photo-1550505095-81378a674395?auto=format&fit=crop&q=80&w=500" },
  { "id": 92, "title": "Parc de Collserola (Nord)", "lat": 41.4550, "lng": 2.0900, "author": "Naturaleza", "type": "Montaña", "image": "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&q=80&w=500" },

  // --- CASTELLDEFELS (NUEVO) ---
  { "id": 100, "title": "Castell de Castelldefels", "lat": 41.2840, "lng": 1.9770, "author": "Medieval", "type": "Castillo", "image": "https://images.unsplash.com/photo-1599579111200-7c697d3f5043?auto=format&fit=crop&q=80&w=500" },
  { "id": 101, "title": "Platja de Castelldefels", "lat": 41.2660, "lng": 1.9900, "author": "Costa", "type": "Playa", "image": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&q=80&w=500" },
  { "id": 102, "title": "Canal Olímpic", "lat": 41.2750, "lng": 1.9880, "author": "JJOO 92", "type": "Deporte", "image": "https://images.unsplash.com/photo-1545560826-4f9532030b89?auto=format&fit=crop&q=80&w=500" },
];
List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pedir permisos ANTES de arrancar para evitar conflictos
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
// 2. PANTALLA DE LOGIN
// ==========================================
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
            const Text("Crea, explora y conecta con arte.", style: TextStyle(color: Colors.grey)),
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

// ==========================================
// 3. LAYOUT PRINCIPAL
// ==========================================
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

// ==========================================
// 4. PANTALLA DEL MAPA
// ==========================================
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
        distanceFilter: 2, 
      )
    ).listen((pos) {
      currentPosition = pos;
      userLat = pos.latitude;
      userLng = pos.longitude;
      
      if(mounted && isLoading) {
        setState(() => isLoading = false);
        // Solo centrar la primera vez o si el mapa ya cargó
        if (mapboxMap != null) {
             mapboxMap!.setCamera(CameraOptions(
                center: Point(coordinates: Position(pos.longitude, pos.latitude)),
                zoom: 17.0, 
                pitch: 60.0,
                bearing: 0.0
             ));
        }
      }
      // Actualizar ubicación del muñeco
      if (mapboxMap != null) {
          mapboxMap!.location.updateSettings(LocationComponentSettings(
            enabled: true, 
            pulsingEnabled: false,
            puckBearingEnabled: true
          ));
      }
    });
  }

  _onMapCreated(MapboxMap map) async {
    print("🗺️ Mapa creado");
    mapboxMap = map;
    
    // 1. ESTILO (Outdoors)
    try {
       await mapboxMap!.loadStyleURI("mapbox://styles/mapbox/outdoors-v12");
    } catch (e) { print("Error estilo: $e"); }

    // 2. AVATAR 3D
    try {
      await mapboxMap?.location.updateSettings(LocationComponentSettings(
        enabled: true,
        pulsingEnabled: false,
        puckBearingEnabled: true,
        locationPuck: LocationPuck(
          locationPuck3D: LocationPuck3D(
            modelUri: "asset://assets/avatar.glb", 
            modelScale: [2.5, 2.5, 2.5], // Escala normal
            modelRotation: [0.0, 0.0, 0.0],
          )
        )
      ));
    } catch(e) { print("Error avatar: $e"); }

    // 3. PUNTOS ROJOS
    circleAnnotationManager = await map.annotations.createCircleAnnotationManager();
    await _drawPoints(); 

    // 4. CLICS EN PUNTOS
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
          // IMPORTANTE PARA EVITAR PANTALLA NEGRA/BLANCA EN ANDROID
          textureView: true, 
          styleUri: "mapbox://styles/mapbox/outdoors-v12", 
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

        // TARJETA DE INFORMACIÓN
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
                      errorWidget: (c, u, e) => Container(color: Colors.grey, child: Icon(Icons.error)),
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
} // 👈 AQUÍ ESTABA EL ERROR: Faltaba esta llave para cerrar _MapGameScreenState

// CLASE AUXILIAR (AHORA SÍ ESTÁ FUERA DE LA OTRA CLASE)
class MyAnnotationClickListener implements OnCircleAnnotationClickListener {
  final Function(CircleAnnotation) onTap;
  MyAnnotationClickListener({required this.onTap});
  @override
  void onCircleAnnotationClick(CircleAnnotation annotation) {
    onTap(annotation);
  }
}

// ==========================================
// 5. PANTALLA AR
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

// ==========================================
// 6. PANTALLA PERFIL
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