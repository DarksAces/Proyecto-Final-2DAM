import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:camera/camera.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';

// 🔒 IMPORTS DE FIREBASE
import 'package:firebase_core/firebase_core.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; 
import 'api_service.dart'; 
import 'package:image_picker/image_picker.dart' as ip; 
import 'dart:io'; 

// ==========================================
// 1. CONFIGURACIÓN
// ==========================================
// NOTA: Reemplaza esto con tu token real
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

// DATOS MOCK - ESPAÑA Y BARCELONA EXPANDIDA
final List<Map<String, dynamic>> MOCK_STOPS = [
  { "id": 1, "title": "Torre Glòries", "lat": 41.403629, "lng": 2.187406, "author": "Jean Nouvel", "type": "Arquitectura", "image": "https://images.unsplash.com/photo-1583422409516-2895a77efded?auto=format&fit=crop&q=80&w=500" },
  { "id": 2, "title": "Disseny Hub", "lat": 41.402465, "lng": 2.188835, "author": "Museo", "type": "Diseño", "image": "https://images.unsplash.com/photo-1580666836703-65e796b93417?auto=format&fit=crop&q=80&w=500" },
  { "id": 3, "title": "Westfield Glòries", "lat": 41.4065, "lng": 2.1915, "author": "Centro", "type": "Ocio", "image": "https://images.unsplash.com/photo-1519567241046-7f570eee3c9e?auto=format&fit=crop&q=80&w=500" },
  { "id": 4, "title": "Els Encants", "lat": 41.4010, "lng": 2.1860, "author": "Mercado", "type": "Cultura", "image": "https://images.unsplash.com/photo-1561344640-2453889cde5b?auto=format&fit=crop&q=80&w=500" },
  { "id": 20, "title": "Sagrada Família", "lat": 41.4036, "lng": 2.1744, "author": "Gaudí", "type": "Monumento", "image": "https://images.unsplash.com/photo-1545443761-1a8698a56f18?auto=format&fit=crop&q=80&w=500" },
  { "id": 21, "title": "Casa Batlló", "lat": 41.3917, "lng": 2.1649, "author": "Gaudí", "type": "Modernismo", "image": "https://images.unsplash.com/photo-1513374200575-4e647896530e?auto=format&fit=crop&q=80&w=500" },
  { "id": 22, "title": "Arc de Triomf", "lat": 41.3910, "lng": 2.1806, "author": "Vilaseca", "type": "Historia", "image": "https://images.unsplash.com/photo-1564663427023-422448627773?auto=format&fit=crop&q=80&w=500" },
  { "id": 23, "title": "Catedral de Barcelona", "lat": 41.3839, "lng": 2.1762, "author": "Gótico", "type": "Religión", "image": "https://images.unsplash.com/photo-1565067692138-348295249c0c?auto=format&fit=crop&q=80&w=500" },
  { "id": 30, "title": "Puerta del Sol", "lat": 40.4168, "lng": -3.7038, "author": "Madrid", "type": "Plaza", "image": "https://images.unsplash.com/photo-1549309019-a1d77ae910fc?auto=format&fit=crop&q=80&w=500" },
  { "id": 31, "title": "Museo del Prado", "lat": 40.4138, "lng": -3.6921, "author": "Villanueva", "type": "Museo", "image": "https://images.unsplash.com/photo-1559563665-c9500072a02b?auto=format&fit=crop&q=80&w=500" },
  { "id": 40, "title": "Ciudad de las Artes", "lat": 39.4549, "lng": -0.3505, "author": "Calatrava", "type": "Ciencia", "image": "https://images.unsplash.com/photo-1532596733622-f63555624e0a?auto=format&fit=crop&q=80&w=500" },
  { "id": 50, "title": "Plaza de España", "lat": 37.3772, "lng": -5.9869, "author": "A. González", "type": "Historia", "image": "https://images.unsplash.com/photo-1555881400-74d7acaacd81?auto=format&fit=crop&q=80&w=500" },
  { "id": 60, "title": "Museo Guggenheim", "lat": 43.2687, "lng": -2.9340, "author": "Gehry", "type": "Arte", "image": "https://images.unsplash.com/photo-1526524806212-477e51c7a43a?auto=format&fit=crop&q=80&w=500" },
];

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🚀 INICIALIZACIÓN DE FIREBASE
  try {
    print('🔥 Inicializando Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase Core inicializado');
  } catch (e, stackTrace) {
    print("❌ Error al inicializar Firebase: $e");
    print("Stack: $stackTrace");
  }
  
  await Permission.location.request();
  await Permission.camera.request();
  try { 
    cameras = await availableCameras(); 
    print('📷 Cámaras disponibles: ${cameras.length}');
  } catch (e) { 
    print("Error cámara: $e"); 
  }
  
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
          onPressed: () => Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => const MainLayout(username: "User"))
          ),
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
  final List<Widget> _pages = [
    const MapGameScreen(), 
    const ARScannerScreen(), 
    const Center(child: Text("Perfil"))
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

  // 🌍 DATOS VIVOS DE FIRESTORE
  List<Map<String, dynamic>> liveStops = []; 
  StreamSubscription? _firestoreSubscription; 

  @override
  void initState() {
    super.initState();
    _initLocation();
    _listenToFirestore();
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }

  void _listenToFirestore() {
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('sitios')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        final List<Map<String, dynamic>> fetchedStops = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            "id": doc.id, 
            "title": data['title'] ?? 'Sitio Anónimo',
            "lat": (data['lat'] as num).toDouble(),
            "lng": (data['lng'] as num).toDouble(),
            "author": data['author'] ?? 'Comunidad',
            "type": data['type'] ?? 'Genérico',
            "image": data['imageUrl'] ?? data['image'] ?? 'https://images.unsplash.com/placeholder.jpg',
          };
        }).toList();

        setState(() {
          liveStops = [...MOCK_STOPS, ...fetchedStops]; 
          _drawPoints();
        });
      }
    });
  }

  _initLocation() async {
    geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high, 
        distanceFilter: 2
      )
    ).listen((pos) {
      currentPosition = pos;
      userLat = pos.latitude;
      userLng = pos.longitude;
      
      if(mounted && isLoading) {
        setState(() => isLoading = false);
        mapboxMap?.setCamera(CameraOptions(
          center: Point(coordinates: Position(pos.longitude, pos.latitude)),
          zoom: 17.0, 
          pitch: 60.0, 
          bearing: 0.0
        ));
      }
    });
  }

  _onMapCreated(MapboxMap map) async {
    mapboxMap = map;

    // 1. Estilo Outdoors
    try { 
      await mapboxMap!.loadStyleURI("mapbox://styles/mapbox/outdoors-v12"); 
      print("✅ Estilo de mapa cargado"); 
    } catch (e) {
      print("❌ ERROR: Mapbox style load failed: $e"); 
    }

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
      print("✅ Avatar 3D configurado"); 
    } catch(e) {
      print("⚠️ Avatar 3D no disponible: $e"); 
    }

    // 3. Puntos en el mapa
    circleAnnotationManager = await map.annotations.createCircleAnnotationManager();
    await _drawPoints(); // <-- CORREGIDO: Usar _drawPoints sin *

    // 4. Clics en puntos
    circleAnnotationManager?.addOnCircleAnnotationClickListener(
      MyAnnotationClickListener(onTap: (annotation) {
        try {
          final stop = liveStops.firstWhere((s) => 
            (s['lat'] - annotation.geometry.coordinates.lat).abs() < 0.0001 &&
            (s['lng'] - annotation.geometry.coordinates.lng).abs() < 0.0001
          );
          setState(() => selectedStop = stop); 
        } catch (e) { // <-- CORREGIDO: Usar 'e' para la excepción
          print("Error al encontrar parada: $e");
        }
      })
    );
  }

  _drawPoints() async {
    if (circleAnnotationManager == null) return;
    
    await circleAnnotationManager?.deleteAll();
    for (var stop in liveStops) {
      await circleAnnotationManager?.create(CircleAnnotationOptions(
        geometry: Point(coordinates: Position(stop['lng'], stop['lat'])),
        circleColor: JoviTheme.red.value,
        circleRadius: 15.0, 
        circleStrokeWidth: 4.0,
        circleStrokeColor: Colors.white.value,
      ));
    }
    print("✅ ${liveStops.length} puntos dibujados en el mapa");
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapWidget(
          key: const ValueKey("mapWidget"),
          styleUri: "mapbox://styles/mapbox/outdoors-v12",
          textureView: true, 
          cameraOptions: CameraOptions(
            center: Point(coordinates: Position(userLng, userLat)), 
            zoom: 15.0,
            pitch: 0.0
          ), 
          onMapCreated: _onMapCreated, // <-- CORREGIDO: Usar _onMapCreated sin *
        ),
        
        if (isLoading) 
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: JoviTheme.yellow)
            ),
          ),

        // 🟢 BOTÓN AÑADIR SITIO
        Positioned(
          top: 60,
          right: 15,
          child: FloatingActionButton(
            heroTag: 'add_stop_btn',
            backgroundColor: JoviTheme.yellow,
            foregroundColor: JoviTheme.blue,
            onPressed: () {
              if (currentPosition != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddStopScreen(currentPosition: currentPosition!) // <-- CORREGIDO: Usar '_'
                  ), 
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Esperando ubicación GPS...')),
                );
              }
            },
            child: const Icon(LucideIcons.plus),
          ),
        ),

        if (selectedStop != null) 
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)
                    ),
                    child: CachedNetworkImage(
                      imageUrl: selectedStop!['image'],
                      height: 150, 
                      width: double.infinity, 
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Container(color: Colors.grey[300]),
                    ),
                  ),
                  ListTile(
                    title: Text(
                      selectedStop!['title'], 
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 20
                      )
                    ),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: JoviTheme.yellow, 
                          foregroundColor: JoviTheme.blue, 
                          padding: const EdgeInsets.all(12)
                        ),
                        icon: const Icon(LucideIcons.scanLine),
                        label: const Text("Ver en AR"),
                        onPressed: () => Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (_) => const ARScannerScreen()
                          )
                        ),
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

// AR SCREEN
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
      controller!.initialize().then((_) { if (mounted) setState(() {}); }); // <-- CORREGIDO: Llaves y punto y coma
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
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: JoviTheme.yellow)
        ),
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(controller!),
          Positioned(
            top: 40, 
            left: 20, 
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white), 
              onPressed: () => Navigator.pop(context)
            )
          )
        ]
      ),
    );
  }
}

// AÑADIR SITIO SCREEN
class AddStopScreen extends StatefulWidget {
  final geo.Position currentPosition;
  const AddStopScreen({super.key, required this.currentPosition});
  @override State<AddStopScreen> createState() => _AddStopScreenState();
}

class _AddStopScreenState extends State<AddStopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _typeController = TextEditingController();
  
  File? _imageFile;
  bool _isUploading = false;
  
  final apiService = ApiService(); 
  
  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ip.ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(LucideIcons.camera),
                title: const Text('Tomar Foto'),
                onTap: () => Navigator.pop(context, ip.ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(LucideIcons.image),
                title: const Text('Galería'),
                onTap: () => Navigator.pop(context, ip.ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      final picker = ip.ImagePicker(); 
      final pickedFile = await picker.pickImage(
        source: source, 
        imageQuality: 70
      ); 

      if (pickedFile != null) {
        setState(() { 
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _submitData() async {
    if (_formKey.currentState!.validate() && _imageFile != null) {
      setState(() => _isUploading = true); 

      final newStop = NewStopData(
        title: _titleController.text,
        author: _authorController.text.isEmpty ? 'Anónimo' : _authorController.text,
        type: _typeController.text,
        lat: widget.currentPosition.latitude,
        lng: widget.currentPosition.longitude,
        imageFile: _imageFile!,
      );

      final success = await apiService.uploadNewStop(newStop); 

      setState(() => _isUploading = false); 

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Sitio añadido con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error al subir. Revisa los logs de consola.'),
              duration: Duration(seconds: 5),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos y añade una foto.')
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Nuevo Sitio'),
        backgroundColor: JoviTheme.yellow,
        foregroundColor: JoviTheme.blue,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ubicación actual (GPS):\nLat ${widget.currentPosition.latitude.toStringAsFixed(4)}, Lng ${widget.currentPosition.longitude.toStringAsFixed(4)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: JoviTheme.blue
                ),
              ),
              const Divider(height: 30),

              TextFormField(
                controller: _titleController, 
                decoration: const InputDecoration(
                  labelText: 'Título del Sitio/Monumento',
                  border: OutlineInputBorder(),
                ), 
                validator: (v) => v!.isEmpty ? 'Introduce un título' : null,
              ),
              const SizedBox(height: 15),
              
              TextFormField(
                controller: _authorController, 
                decoration: const InputDecoration(
                  labelText: 'Autor o Creador (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              
              TextFormField(
                controller: _typeController, 
                decoration: const InputDecoration(
                  labelText: 'Categoría (Ej: Arte, Historia, Gastronomía)',
                  border: OutlineInputBorder(),
                ), 
                validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: _pickImage, 
                icon: Icon(
                  _imageFile == null ? LucideIcons.image : LucideIcons.check
                ),
                label: Text(
                  _imageFile == null 
                    ? 'Seleccionar Foto' 
                    : 'Foto: ${_imageFile!.path.split('/').last}'
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: JoviTheme.gray, 
                  foregroundColor: JoviTheme.blue,
                  padding: const EdgeInsets.all(15)
                ),
              ),
              const SizedBox(height: 10),

              if (_imageFile != null) 
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _imageFile!, 
                        height: 200, 
                        fit: BoxFit.cover
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 30),
              
              if (_isUploading)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: JoviTheme.yellow),
                      SizedBox(height: 10),
                      Text('Subiendo...', style: TextStyle(color: JoviTheme.blue)),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _submitData,
                  icon: const Icon(LucideIcons.upload),
                  label: const Text('SUBIR SITIO A JOVI AR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JoviTheme.yellow, 
                    foregroundColor: JoviTheme.blue, 
                    padding: const EdgeInsets.all(15),
                    textStyle: JoviTheme.fontBaloo.copyWith(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}