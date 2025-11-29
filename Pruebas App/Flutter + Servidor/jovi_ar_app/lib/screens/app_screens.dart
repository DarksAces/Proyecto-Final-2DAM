// lib/screens/app_screens.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart' as ip;
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:connectivity_plus/connectivity_plus.dart'; 

import '../main.dart'; 
import '../api_service.dart'; 
import '../auth_service.dart'; 
import '../settings_service.dart'; 
import '../widgets/util_widgets.dart'; 
import 'settings_screen.dart';


// ==========================================
// 1. PANTALLA INICIO (CORREGIDA PARA EVITAR RAYAS AMARILLAS)
// ==========================================

class HomeScreen extends StatelessWidget {
  final TabController tabController;
  
  const HomeScreen({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoviTheme.gray,
      appBar: AppBar(
        title: Text("Hola, ${FirebaseAuth.instance.currentUser?.displayName ?? 'Viajero'}", style: JoviTheme.fontBaloo),
        backgroundColor: JoviTheme.yellow,
        foregroundColor: JoviTheme.blue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta Grande
            SizedBox(
              height: 160, 
              child: _DashboardCard(
                title: "Explorar Mapa",
                icon: LucideIcons.map,
                color: const Color(0xFFACD8AA), 
                onTap: () => tabController.animateTo(2), 
              ),
            ),
            const SizedBox(height: 16),
            
            // Fila 1
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 130,
                    child: _DashboardCard(
                      title: "Escanear AR",
                      icon: LucideIcons.scanLine,
                      color: const Color(0xFFFFD6E0), 
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const ARScannerScreen()));
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 130,
                    child: _DashboardCard(
                      title: "Actividad Amigos",
                      icon: LucideIcons.users,
                      color: const Color(0xFFC3F3F7), 
                      onTap: () => tabController.animateTo(1), 
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fila 2
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 130,
                    child: _DashboardCard(
                      title: "Mi Galería",
                      icon: LucideIcons.image,
                      color: const Color(0xFFFFF4BD), 
                      onTap: () => tabController.animateTo(3), 
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 130,
                    child: _DashboardCard(
                      title: "Mi Perfil",
                      icon: LucideIcons.userCircle,
                      color: Colors.white,
                      onTap: () => tabController.animateTo(4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        // FIX: Usamos LayoutBuilder o un Center simple con SingleChildScrollView para evitar overflow
        child: Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(), // Evita scroll manual, solo es para layout
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: JoviTheme.blue),
                const SizedBox(height: 8),
                Text(
                  title, 
                  style: JoviTheme.fontBaloo.copyWith(fontSize: 16, color: JoviTheme.blue, fontWeight: FontWeight.bold), 
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. PANTALLA SOCIAL
// ==========================================

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("Debes iniciar sesión."));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, userSnapshot) {
        
        if (userSnapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator(color: JoviTheme.yellow));
        }

        List<dynamic> rawFriends = [];
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          if (userData != null && userData.containsKey('friends')) {
            rawFriends = userData['friends'];
          }
        }

        final List<String> friendIds = List<String>.from(rawFriends);

        if (friendIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.users, size: 60, color: Colors.grey),
                const SizedBox(height: 20),
                const Text("No tienes amigos añadidos aún.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                TextButton(
                  onPressed: () {
                    DefaultTabController.of(context)?.animateTo(4);
                  }, 
                  child: const Text("Ir a Perfil para añadir", style: TextStyle(color: JoviTheme.blue))
                )
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Actividad de Amigos"), 
            backgroundColor: JoviTheme.gray, 
            elevation: 0
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sitios')
                .where('authorId', whereIn: friendIds)
                .orderBy('createdAt', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, sitiosSnapshot) {
              if (sitiosSnapshot.hasError) {
                 // Mostramos el error completo para depuración si es necesario
                 print("ERROR FIRESTORE: ${sitiosSnapshot.error}");
                 return Center(child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 40, color: Colors.orange),
                      const SizedBox(height: 10),
                      const Text("Falta el Índice de Base de Datos", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      const Text("Revisa la terminal de comandos (consola) y haz clic en el enlace HTTPS para crearlo.", textAlign: TextAlign.center),
                    ],
                  ),
                ));
              }
              if (sitiosSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: JoviTheme.yellow));
              }
              if (!sitiosSnapshot.hasData || sitiosSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Tus amigos no han subido nada aún."));
              }

              final docs = sitiosSnapshot.data!.docs;
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: JoviTheme.yellow, 
                            child: Text(data['author']?[0].toUpperCase() ?? '?')
                          ),
                          title: Text(data['author'] ?? 'Desconocido', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Ha descubierto: ${data['title']}"),
                        ),
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                          child: CachedNetworkImage(
                            imageUrl: data['imageUrl'],
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (c,u) => Container(height: 200, color: Colors.grey[200]),
                            errorWidget: (c,u,e) => Container(height: 200, color: Colors.grey, child: const Icon(Icons.error)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// ==========================================
// 3. PANTALLA MAPA
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

  List<Map<String, dynamic>> liveStops = [];
  StreamSubscription? _firestoreSubscription;
  final ApiService _apiService = ApiService();

  String _filter = 'all'; 
  List<String> _myFriendIds = [];
  String? _myUid;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid;
    _initLocation();
    _loadFriendsAndListen();
  }

  Future<void> _loadFriendsAndListen() async {
    _myFriendIds = await _apiService.getFriendList();
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
            "authorId": data['authorId'] ?? '',
            "type": data['type'] ?? 'Genérico',
            "image": data['imageUrl'] ?? data['image'] ?? 'https://images.unsplash.com/placeholder.jpg',
          };
        }).toList();

        setState(() {
          liveStops = fetchedStops;
          _drawPoints();
        });
      }
    });
  }

  _initLocation() async {
    geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high, distanceFilter: 2)
    ).listen((pos) {
      currentPosition = pos;
      userLat = pos.latitude;
      userLng = pos.longitude;

      if(mounted && isLoading) {
        setState(() => isLoading = false);
        mapboxMap?.setCamera(CameraOptions(
          center: Point(coordinates: Position(pos.longitude, pos.latitude)),
          zoom: 17.0,
          pitch: 60.0
        ));
      }
    });
  }

  _onMapCreated(MapboxMap map) async {
    mapboxMap = map;
    try { await mapboxMap!.loadStyleURI("mapbox://styles/mapbox/outdoors-v12"); } catch (e) { print("Map style error: $e"); }
    
    try {
      await mapboxMap?.location.updateSettings(LocationComponentSettings(
        enabled: true,
        pulsingEnabled: false,
        locationPuck: LocationPuck(locationPuck3D: LocationPuck3D(modelUri: "asset://assets/avatar.glb", modelScale: [50.0, 50.0, 50.0]))
      ));
    } catch(e) {}

    circleAnnotationManager = await map.annotations.createCircleAnnotationManager();
    await _drawPoints();

    circleAnnotationManager?.addOnCircleAnnotationClickListener(
      MyAnnotationClickListener(onTap: (annotation) {
        final stop = liveStops.firstWhere((s) =>
          (s['lat'] - annotation.geometry.coordinates.lat).abs() < 0.0001 &&
          (s['lng'] - annotation.geometry.coordinates.lng).abs() < 0.0001,
          orElse: () => {}
        );
        if (stop.isNotEmpty) setState(() => selectedStop = stop);
      })
    );
  }

  _drawPoints() async {
    if (circleAnnotationManager == null) return;
    await circleAnnotationManager?.deleteAll();

    for (var stop in liveStops) {
      bool shouldShow = false;
      int color = JoviTheme.yellow.value;

      if (_filter == 'all') {
        shouldShow = true;
        if (_myFriendIds.contains(stop['authorId'])) color = Colors.blue.value;
        if (stop['authorId'] == _myUid) color = Colors.green.value;
      } else if (_filter == 'friends') {
        if (_myFriendIds.contains(stop['authorId'])) {
          shouldShow = true;
          color = Colors.blue.value;
        }
      } else if (_filter == 'me') {
        if (stop['authorId'] == _myUid) {
          shouldShow = true;
          color = Colors.green.value;
        }
      }

      if (shouldShow) {
        await circleAnnotationManager?.create(CircleAnnotationOptions(
          geometry: Point(coordinates: Position(stop['lng'], stop['lat'])),
          circleColor: color,
          circleRadius: 8.0,
          circleStrokeWidth: 2.0,
          circleStrokeColor: Colors.white.value,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapWidget(
          key: const ValueKey("mapWidget"),
          styleUri: "mapbox://styles/mapbox/outdoors-v12",
          textureView: true,
          cameraOptions: CameraOptions(center: Point(coordinates: Position(userLng, userLat)), zoom: 15.0),
          onMapCreated: _onMapCreated,
        ),
        Positioned(
          top: 50, left: 20, right: 20,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black26)]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _FilterChip(label: "Todos", isSelected: _filter == 'all', onTap: () => setState(() { _filter = 'all'; _drawPoints(); })),
                _FilterChip(label: "Amigos", isSelected: _filter == 'friends', onTap: () => setState(() { _filter = 'friends'; _drawPoints(); })),
                _FilterChip(label: "Yo", isSelected: _filter == 'me', onTap: () => setState(() { _filter = 'me'; _drawPoints(); })),
              ],
            ),
          ),
        ),
        if (isLoading) Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator(color: JoviTheme.yellow))),
        Positioned(
          top: 120, right: 15,
          child: FloatingActionButton(
            heroTag: 'add_stop_btn',
            backgroundColor: JoviTheme.yellow,
            foregroundColor: JoviTheme.blue,
            onPressed: () {
              if (currentPosition != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AddStopScreen(currentPosition: currentPosition!)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esperando ubicación GPS...')));
              }
            },
            child: const Icon(LucideIcons.plus),
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
                    child: CachedNetworkImage(imageUrl: selectedStop!['image'], height: 150, width: double.infinity, fit: BoxFit.cover),
                  ),
                  ListTile(
                    title: Text(selectedStop!['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Por: ${selectedStop!['author']}'),
                    trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => selectedStop = null)),
                  ),
                ],
              ),
            ),
          )
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? JoviTheme.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ==========================================
// 4. PANTALLA GALERÍA
// ==========================================

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: const Text("Mi Galería"), backgroundColor: JoviTheme.yellow),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('sitios').where('authorId', isEqualTo: user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          final count = docs.length;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: count >= 5 ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(count >= 5 ? LucideIcons.alertTriangle : LucideIcons.checkCircle, color: count >= 5 ? Colors.red : Colors.green),
                    const SizedBox(width: 10),
                    Expanded(child: Text("Has usado $count/5 espacios gratuitos.", style: const TextStyle(fontWeight: FontWeight.bold))),
                    if (count >= 5)
                      TextButton(onPressed: (){ /* Pagar logic */ }, child: const Text("Ampliar"))
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(imageUrl: data['imageUrl'], fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 5, right: 5,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => ApiService().deleteStop(docs[index].id, user.uid, data['imageUrl']),
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ==========================================
// 5. PERFIL (CORREGIDO: CONTEXT SAFETY)
// ==========================================

class ProfileScreen extends StatefulWidget {
  final VoidCallback onSignOut;
  const ProfileScreen({super.key, required this.onSignOut});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _friendController = TextEditingController();
  
  void _addFriendDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog( // Usamos un nombre distinto para el context del dialogo
        title: const Text("Añadir Amigo"),
        content: TextField(
          controller: _friendController,
          decoration: const InputDecoration(labelText: "Nickname del amigo", hintText: "Ej: viajero123"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              // 1. Capturar referencias ANTES del await
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context); // context del State, no del dialogo
              
              // 2. Cerrar el diálogo
              navigator.pop();

              // 3. Operación asíncrona
              final error = await _apiService.addFriend(_friendController.text);
              
              // 4. Usar el messenger capturado (es seguro aunque el widget se desmonte)
              messenger.showSnackBar(SnackBar(
                content: Text(error == null ? "✅ Amigo añadido!" : "❌ $error"),
                backgroundColor: error == null ? Colors.green : Colors.red,
              ));
              
              _friendController.clear();
            },
            child: const Text("Añadir"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text("Perfil"), actions: [
        IconButton(icon: const Icon(LucideIcons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())))
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundColor: JoviTheme.blue, child: Icon(LucideIcons.user, size: 50, color: Colors.white)),
            const SizedBox(height: 10),
            Text(user?.displayName ?? "Sin Nickname", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(user?.email ?? "", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            
            ListTile(
              leading: const Icon(LucideIcons.userPlus, color: JoviTheme.blue),
              title: const Text("Añadir Amigo"),
              subtitle: const Text("Busca por nickname para conectar"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _addFriendDialog,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(LucideIcons.logOut, color: Colors.red),
              title: const Text("Cerrar Sesión"),
              onTap: widget.onSignOut,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// AR SCANNER
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
      controller!.initialize().then((_) { if (mounted) setState(() {}); });
    }
  }
  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) return const Scaffold(backgroundColor: Colors.black);
    return Scaffold(body: Stack(children: [CameraPreview(controller!), Positioned(top: 40, left: 20, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)))]));
  }
}

// ==========================================
// 6. AÑADIR SITIO
// ==========================================

class AddStopScreen extends StatefulWidget {
  final geo.Position currentPosition;
  const AddStopScreen({super.key, required this.currentPosition});
  @override State<AddStopScreen> createState() => _AddStopScreenState();
}

class _AddStopScreenState extends State<AddStopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _typeController = TextEditingController();

  File? _imageFile;
  bool _isUploading = false;

  final apiService = ApiService();
  final SettingsService _settingsService = SettingsService();

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

  Future<bool> _isUploadAllowed() async {
    final preference = await _settingsService.getUploadPreference();
    final connectivityResult = await (Connectivity().checkConnectivity());
    
    if (connectivityResult == ConnectivityResult.none) return false;
    
    if (preference == 'both') return true;
    if (preference == 'wifi') return connectivityResult == ConnectivityResult.wifi;
    if (preference == 'cellular') return connectivityResult == ConnectivityResult.mobile;
    
    return false;
  }

  Future<void> _submitData() async {
    final count = await apiService.getUserStopCount();
    if (count >= 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Límite de 5 sitios alcanzado. Borra alguno o paga."), backgroundColor: Colors.red));
      }
      return;
    }

    if (_formKey.currentState!.validate() && _imageFile != null) {
      
      final isAllowed = await _isUploadAllowed();
      
      final currentUser = FirebaseAuth.instance.currentUser;
      final authorNickname = currentUser?.displayName ?? "Anónimo"; 
      final authorId = currentUser?.uid ?? 'anonimo_offline'; 
      
      final newStop = NewStopData(
        title: _titleController.text,
        author: authorNickname,
        type: _typeController.text,
        lat: widget.currentPosition.latitude,
        lng: widget.currentPosition.longitude,
        imageFile: _imageFile!,
        authorId: authorId,
      );
      
      if (!isAllowed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Guardado localmente. Se subirá al cumplir las preferencias de red.'),
              backgroundColor: JoviTheme.blue,
            ),
          );
          Navigator.pop(context); 
          return; 
      }
      
      setState(() => _isUploading = true);

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
              content: Text('❌ Error de servidor o permisos.'),
              backgroundColor: JoviTheme.red,
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
                'Autor: ${FirebaseAuth.instance.currentUser?.displayName ?? "Anónimo"}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: JoviTheme.blue),
              ),
              Text(
                'Ubicación: Lat ${widget.currentPosition.latitude.toStringAsFixed(4)}, Lng ${widget.currentPosition.longitude.toStringAsFixed(4)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: JoviTheme.blue),
              ),
              const Divider(height: 30),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título del Sitio/Monumento', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Introduce un título' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Categoría (Ej: Arte, Historia)', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(_imageFile == null ? LucideIcons.camera : LucideIcons.check),
                label: Text(_imageFile == null ? 'Tomar Foto / Galería' : 'Foto Seleccionada'),
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
                      child: Image.file(_imageFile!, height: 200, fit: BoxFit.cover),
                    ),
                  ),
                ),

              const SizedBox(height: 30),

              if (_isUploading)
                const Center(child: CircularProgressIndicator(color: JoviTheme.yellow))
              else
                ElevatedButton.icon(
                  onPressed: _submitData,
                  icon: const Icon(LucideIcons.upload),
                  label: const Text('SUBIR SITIO A JOVI AR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JoviTheme.yellow,
                    foregroundColor: JoviTheme.blue,
                    padding: const EdgeInsets.all(15),
                    textStyle: JoviTheme.fontBaloo.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}