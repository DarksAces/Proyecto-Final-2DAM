import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'add_stop_screen.dart';
import '../widgets/util_widgets.dart';

// ==========================================
// 3. PANTALLA MAPA (OPTIMIZADA)
// ==========================================

/// Pantalla Principal del Mapa Interactivo.
///
/// Utiliza Mapbox Maps para mostrar:
/// - Ubicación en tiempo real del usuario.
/// - Marcadores de sitios (Puntos de interés) obtenidos de Firebase.
/// - Marcadores de amigos (Social) en tiempo real.
///
/// Permite añadir nuevos sitios mediante pulsación larga en el mapa.
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

  // ==========================================
  // INICIALIZACIÓN DE LA UBICACIÓN Y PERMISOS
  // ==========================================
  
  // Solicita permisos de GPS durante el inicio.
  // 1. Comprueba si el servicio está habilitado.
  // 2. Comprueba si tenemos permisos (denied/always/whileInUse).
  // 3. Obtiene la posición inicial y configura un stream para actualizaciones.
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
        
        // Mover la cámara a la posición inicial si el mapa ya cargó
        if (_mapInitialized && mapboxMap != null) {
          mapboxMap?.setCamera(CameraOptions(
            center: Point(coordinates: Position(userLng, userLat)), 
            zoom: 17.0
          ));
        }
      }

      // Escuchar cambios de posición para mover el "puntero azul" (interno de mapbox o custom)
      _locationSubscription = geo.Geolocator.getPositionStream(
        locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high, distanceFilter: 10)
      ).listen((pos) {
        if (mounted) {
          currentPosition = pos;
          userLat = pos.latitude;
          userLng = pos.longitude;
          // No llamamos setState aquí para no saturar el renderizado
        }
      });
    } catch (e) {
      print("Error GPS: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ==========================================
  // CARGA DE DATOS DE FIRESTORE
  // ==========================================
  
  // Escucha cambios en la colección 'sitios' en tiempo real.
  // Filtra solo los sitios con status='approved'.
  // Al recibir datos, actualiza `liveStops` y redibuja los marcadores.
  void _listenToFirestore() {
    _firestoreSubscription = FirebaseFirestore.instance.collection('sitios')
        .where('status', isEqualTo: 'approved') // SOLO APROBADOS
        .snapshots().listen((snapshot) {
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
          _drawPoints(); // Refrescar mapa
        }
    });
  }

  // ==========================================
  // CONFIGURACIÓN DE MAPBOX
  // ==========================================
  
  // Se llama cuando el widget de Mapbox está listo.
  // Configura el estilo, el location component (punto azul) y el gestor de anotaciones.
  Future<void> _onMapCreated(MapboxMap map) async {
    mapboxMap = map;
    try { await mapboxMap!.loadStyleURI("mapbox://styles/mapbox/outdoors-v12"); } catch (e) { print("Error estilo mapa: $e"); }
    
    if (!mounted) return; // 🛡️ SAFETY CHECK

    mapboxMap?.location.updateSettings(LocationComponentSettings(enabled: true));
    
    // Crear gestor de círculos
    circleAnnotationManager = await map.annotations.createCircleAnnotationManager();
    
    if (!mounted) return; // 🛡️ SAFETY CHECK

    // Listener de clics en marcadores
    circleAnnotationManager?.addOnCircleAnnotationClickListener(
      MyAnnotationClickListener(onTap: (annotation) {
        // Buscar qué sitio corresponde a estas coordenadas
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

  // ==========================================
  // DIBUJADO DE MARCADORES (PUNTOS)
  // ==========================================

  // Dibuja los círculos en el mapa basándose en `liveStops` y el filtro seleccionado.
  // Colores:
  // - Azul: Sitios de gente que sigo.
  // - Verde: Mis sitios.
  // - Amarillo: Resto de sitios (Comunidad).
  Future<void> _drawPoints() async {
    if (circleAnnotationManager == null || !_mapInitialized || !mounted) return; // 🛡️ SAFETY CHECK
    await circleAnnotationManager?.deleteAll();

    if (!mounted) return; // 🛡️ SAFETY CHECK

    for (var stop in liveStops) {
      bool shouldShow = false;
      int color = JoviTheme.yellow.value; // Color por defecto (Todos)

      // LÓGICA DE FILTRADO
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

  // Recentrar la cámara en la posición actual del usuario
  void _recenterMap() {
    if (currentPosition != null && mapboxMap != null) {
      mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(userLng, userLat)),
          zoom: 17.0,
          pitch: 0,
          bearing: 0,
        ),
        MapAnimationOptions(duration: 1000)
      );
    } else {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ubicación no disponible')));
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
        
        // BOTÓN AGREGAR (ARRIBA)
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

        // BOTÓN RECENTRAR (NUEVO)
        Positioned(
          bottom: 100, right: 15, 
          child: FloatingActionButton(
            heroTag: 'recenter_btn',
            backgroundColor: Colors.white,
            foregroundColor: JoviTheme.blue,
            onPressed: _recenterMap,
            child: const Icon(LucideIcons.crosshair),
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
