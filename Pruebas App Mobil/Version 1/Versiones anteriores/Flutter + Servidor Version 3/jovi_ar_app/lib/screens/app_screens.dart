// lib/screens/app_screens.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size; 
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
// 1. PANTALLA INICIO
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
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 130,
                    child: _DashboardCard(
                      title: "Escanear AR",
                      icon: LucideIcons.scanLine,
                      color: const Color(0xFFFFD6E0), 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ARScannerScreen())),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 130,
                    child: _DashboardCard(
                      title: "Feed Social",
                      icon: LucideIcons.users,
                      color: const Color(0xFFC3F3F7), 
                      onTap: () => tabController.animateTo(1), 
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
        child: Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
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
// 2. PANTALLA SOCIAL (CON FOLLOWERS)
// ==========================================

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return const Center(child: Text("Debes iniciar sesión."));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, userSnapshot) {
        
        if (userSnapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator(color: JoviTheme.yellow));
        }

        List<dynamic> rawFollowing = [];
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          if (userData != null && userData.containsKey('following')) {
            rawFollowing = userData['following'];
          }
        }

        final List<String> followingIds = List<String>.from(rawFollowing);

        if (followingIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.users, size: 60, color: Colors.grey),
                const SizedBox(height: 20),
                const Text("No sigues a nadie aún.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                TextButton(
                  onPressed: () => DefaultTabController.of(context)?.animateTo(4),
                  child: const Text("Buscar gente para seguir", style: TextStyle(color: JoviTheme.blue))
                )
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Tus Seguidos"), 
            backgroundColor: JoviTheme.gray, 
            elevation: 0
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sitios')
                .where('authorId', whereIn: followingIds)
                .orderBy('createdAt', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, sitiosSnapshot) {
              if (sitiosSnapshot.hasError) {
                 return Center(
                   child: SingleChildScrollView(
                     padding: const EdgeInsets.all(16),
                     child: SelectableText(
                       "⚠️ ERROR DE FIREBASE:\n\n${sitiosSnapshot.error}",
                       style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                       textAlign: TextAlign.center,
                     ),
                   ),
                 );
              }
              if (sitiosSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: JoviTheme.yellow));
              }
              if (!sitiosSnapshot.hasData || sitiosSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Tus seguidos no han subido nada reciente."));
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
                          subtitle: Text("Descubrió: ${data['title']}"),
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
// 3. PANTALLA MAPA (OPTIMIZADA)
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
  bool _mapInitialized = false; // Flag para evitar reinicios
  
  double userLat = 41.4036;
  double userLng = 2.1874;

  List<Map<String, dynamic>> liveStops = [];
  
  StreamSubscription? _firestoreSubscription;
  StreamSubscription? _locationSubscription;
  
  final ApiService _apiService = ApiService();

  String _filter = 'all'; 
  List<String> _myFollowingIds = [];
  String? _myUid;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid;
    _initLocation();
    _loadFollowingAndListen();
  }

  Future<void> _loadFollowingAndListen() async {
    _myFollowingIds = await _apiService.getFollowingList();
    _listenToFirestore();
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  _initLocation() async {
    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if(mounted) setState(() => isLoading = false);
      return;
    }

    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        if(mounted) setState(() => isLoading = false);
        return;
      }
    }

    try {
      final initialPosition = await geo.Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          currentPosition = initialPosition;
          userLat = initialPosition.latitude;
          userLng = initialPosition.longitude;
          isLoading = false;
        });
        
        if (_mapInitialized && mapboxMap != null) {
          mapboxMap?.setCamera(CameraOptions(
            center: Point(coordinates: Position(userLng, userLat)), 
            zoom: 17.0
          ));
        }
      }

      _locationSubscription = geo.Geolocator.getPositionStream(
        locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high, distanceFilter: 10)
      ).listen((pos) {
        if (mounted) {
          currentPosition = pos;
          userLat = pos.latitude;
          userLng = pos.longitude;
          // No llamamos setState aquí para no saturar
        }
      });
    } catch (e) {
      print("Error GPS: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _listenToFirestore() {
    _firestoreSubscription = FirebaseFirestore.instance.collection('sitios').snapshots().listen((snapshot) {
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

        liveStops = fetchedStops;
        
        if (_mapInitialized && circleAnnotationManager != null) {
          _drawPoints();
        }
    });
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    mapboxMap = map;
    try { await mapboxMap!.loadStyleURI("mapbox://styles/mapbox/outdoors-v12"); } catch (e) { print("Error estilo mapa: $e"); }
    
    mapboxMap?.location.updateSettings(LocationComponentSettings(enabled: true));
    
    circleAnnotationManager = await map.annotations.createCircleAnnotationManager();
    
    circleAnnotationManager?.addOnCircleAnnotationClickListener(
      MyAnnotationClickListener(onTap: (annotation) {
        final stop = liveStops.firstWhere((s) =>
          (s['lat'] - annotation.geometry.coordinates.lat).abs() < 0.0001 &&
          (s['lng'] - annotation.geometry.coordinates.lng).abs() < 0.0001,
          orElse: () => {}
        );
        if (stop.isNotEmpty && mounted) {
          setState(() => selectedStop = stop);
        }
      })
    );

    _mapInitialized = true;

    if (currentPosition != null) {
      mapboxMap?.setCamera(CameraOptions(center: Point(coordinates: Position(userLng, userLat)), zoom: 17.0));
    }
    
    await _drawPoints();
  }

  Future<void> _drawPoints() async {
    if (circleAnnotationManager == null || !_mapInitialized) return;
    await circleAnnotationManager?.deleteAll();

    for (var stop in liveStops) {
      bool shouldShow = false;
      int color = JoviTheme.yellow.value;

      if (_filter == 'all') {
        shouldShow = true;
        if (_myFollowingIds.contains(stop['authorId'])) color = Colors.blue.value;
        if (stop['authorId'] == _myUid) color = Colors.green.value;
      } else if (_filter == 'following') {
        if (_myFollowingIds.contains(stop['authorId'])) {
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

  void _changeFilter(String newFilter) {
    if (_filter != newFilter) {
      setState(() => _filter = newFilter);
      _drawPoints();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapWidget(
          key: const ValueKey("mapWidget"),
          styleUri: "mapbox://styles/mapbox/outdoors-v12",
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
                _FilterChip(label: "Todos", isSelected: _filter == 'all', onTap: () => _changeFilter('all')),
                _FilterChip(label: "Seguidos", isSelected: _filter == 'following', onTap: () => _changeFilter('following')),
                _FilterChip(label: "Yo", isSelected: _filter == 'me', onTap: () => _changeFilter('me')),
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esperando GPS...')));
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
        decoration: BoxDecoration(color: isSelected ? JoviTheme.blue : Colors.transparent, borderRadius: BorderRadius.circular(20)),
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
                    Expanded(child: Text("Has usado $count/5 espacios.", style: const TextStyle(fontWeight: FontWeight.bold))),
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
                        ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: data['imageUrl'], fit: BoxFit.cover)),
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
// 5. NUEVA PANTALLA: LISTA DE USUARIOS (SEGUIDORES/SEGUIDOS)
// ==========================================
class UsersListScreen extends StatelessWidget {
  final String title;
  final List<String> userIds;

  const UsersListScreen({super.key, required this.title, required this.userIds});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: JoviTheme.yellow,
        foregroundColor: JoviTheme.blue,
      ),
      body: userIds.isEmpty
          ? const Center(child: Text("La lista está vacía."))
          : ListView.builder(
              itemCount: userIds.length,
              itemBuilder: (context, index) {
                final uid = userIds[index];
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const ListTile(title: Text("Cargando..."));
                    
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final nickname = data?['nickname'] ?? data?['email'] ?? "Usuario Desconocido";

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: JoviTheme.blue,
                        child: Text(nickname.isNotEmpty ? nickname[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(nickname, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data?['email'] ?? ""),
                    );
                  },
                );
              },
            ),
    );
  }
}

// ==========================================
// 6. PERFIL (CON CLICS EN NÚMEROS)
// ==========================================

class ProfileScreen extends StatefulWidget {
  final VoidCallback onSignOut;
  const ProfileScreen({super.key, required this.onSignOut});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _followController = TextEditingController();
  final String myUid = FirebaseAuth.instance.currentUser!.uid;

  void _followUserDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Seguir Usuario"),
        content: TextField(
          controller: _followController,
          decoration: const InputDecoration(labelText: "Nickname", hintText: "Ej: explorador99", prefixIcon: Icon(LucideIcons.search)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: JoviTheme.blue, foregroundColor: Colors.white),
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop(); 

              if (_followController.text.isNotEmpty) {
                final error = await _apiService.followUser(_followController.text);
                messenger.showSnackBar(SnackBar(
                  content: Text(error == null ? "✅ Siguiendo a ${_followController.text}" : "❌ $error"),
                  backgroundColor: error == null ? Colors.green : Colors.red,
                ));
                _followController.clear();
              }
            },
            child: const Text("Seguir"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(myUid).snapshots(),
      builder: (context, snapshot) {
        
        List<String> followers = [];
        List<String> following = [];

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          followers = List<String>.from(data['followers'] ?? []);
          following = List<String>.from(data['following'] ?? []);
        }

        return Scaffold(
          appBar: AppBar(title: const Text("Mi Perfil"), actions: [
            IconButton(icon: const Icon(LucideIcons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())))
          ]),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(radius: 50, backgroundColor: JoviTheme.blue, child: Icon(LucideIcons.user, size: 50, color: Colors.white)),
                const SizedBox(height: 10),
                Text(user?.displayName ?? "Usuario", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(user?.email ?? "", style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem("Seguidores", followers, context),
                    Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.5)),
                    _buildStatItem("Seguidos", following, context),
                  ],
                ),
                const SizedBox(height: 30),

                ElevatedButton.icon(
                  onPressed: _followUserDialog,
                  icon: const Icon(LucideIcons.userPlus),
                  label: const Text("Buscar y Seguir"),
                  style: ElevatedButton.styleFrom(backgroundColor: JoviTheme.yellow, foregroundColor: JoviTheme.blue, minimumSize: const Size(double.infinity, 50)),
                ),
                const SizedBox(height: 15),
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
    );
  }

  Widget _buildStatItem(String label, List<String> list, BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UsersListScreen(title: label, userIds: list))
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          Text(list.length.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: JoviTheme.blue)),
          Text(label, style: const TextStyle(color: Colors.grey, decoration: TextDecoration.underline)),
        ]),
      ),
    );
  }
}

// ==========================================
// 7. AR SCANNER
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
  void dispose() { controller?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) return const Scaffold(backgroundColor: Colors.black);
    return Scaffold(body: Stack(children: [CameraPreview(controller!), Positioned(top: 40, left: 20, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)))]));
  }
}

// ==========================================
// 8. AÑADIR SITIO
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
    final picker = ip.ImagePicker();
    final pickedFile = await picker.pickImage(source: ip.ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate() || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falta foto o datos.')));
      return;
    }

    setState(() => _isUploading = true);
    
    final currentUser = FirebaseAuth.instance.currentUser;
    final authorId = currentUser?.uid ?? 'anonimo_offline'; 

    final newStop = NewStopData(
      title: _titleController.text,
      author: currentUser?.displayName ?? "Anónimo",
      type: _typeController.text,
      lat: widget.currentPosition.latitude,
      lng: widget.currentPosition.longitude,
      imageFile: _imageFile!,
      authorId: authorId,
    );
    
    final success = await apiService.uploadNewStop(newStop);
    setState(() => _isUploading = false);

    if (mounted && success) {
       Navigator.pop(context);
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Sitio subido.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Sitio'), backgroundColor: JoviTheme.yellow),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Título'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _typeController, decoration: const InputDecoration(labelText: 'Categoría'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 20),
              ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.camera), label: Text(_imageFile == null ? 'Foto' : 'Foto OK')),
              if (_imageFile != null) Image.file(_imageFile!, height: 150),
              const SizedBox(height: 20),
              _isUploading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _submitData, child: const Text("SUBIR"))
            ],
          ),
        ),
      ),
    );
  }
}