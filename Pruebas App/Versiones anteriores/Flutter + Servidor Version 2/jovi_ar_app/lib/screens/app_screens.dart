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
// 1. PERFIL AVANZADO (EDICIÓN Y ELIMINACIÓN)
// ==========================================

class ProfileScreen extends StatefulWidget {
  final VoidCallback onSignOut;
  const ProfileScreen({super.key, required this.onSignOut});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _nicknameController = TextEditingController();
  String? _errorMessage;
  bool _isEditing = false;
  bool _isDeleting = false;
  bool _isLoading = false; 

  @override
  void initState() {
    super.initState();
    _nicknameController.text = FirebaseAuth.instance.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _updateNickname() async {
    if (_nicknameController.text.trim().isEmpty) {
      setState(() => _errorMessage = "El nickname no puede estar vacío.");
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await _authService.updateNickname(_nicknameController.text.trim());

    setState(() {
      _isLoading = false;
      if (error == null) {
        _isEditing = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Nickname actualizado con éxito!')),
        );
      } else {
        _errorMessage = error;
      }
    });
  }

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);

    final nickname = FirebaseAuth.instance.currentUser?.displayName ?? '';
    final error = await _authService.deleteAccount(nickname);

    if (error != null) {
      setState(() {
        _errorMessage = error;
        _isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al eliminar: $error')),
      );
    } else {
      // Éxito: Navegación por StreamBuilder
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar Eliminación"),
        content: const Text("¿Estás seguro de que quieres eliminar tu cuenta permanentemente? Esta acción es irreversible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: JoviTheme.red),
            child: const Text("Eliminar", style: TextStyle(color: JoviTheme.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser; 
    final userEmail = user?.email ?? "Usuario";
    final userNickname = user?.displayName ?? "Sin Nickname";
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(LucideIcons.userCircle, size: 80, color: JoviTheme.blue),
            const SizedBox(height: 20),
            
            Text("Perfil de Usuario", style: JoviTheme.fontBaloo.copyWith(fontSize: 36, color: JoviTheme.blue, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            
            // EMAIL DE USUARIO
            Text("Email: $userEmail", style: JoviTheme.fontPoppins.copyWith(fontSize: 16)),
            const SizedBox(height: 10),

            // INPUT DE NICKNAME
            if (_isEditing)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Nickname:", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      hintText: userNickname,
                      suffixIcon: _isLoading 
                          ? const CircularProgressIndicator(color: JoviTheme.blue) 
                          : IconButton(
                              icon: const Icon(LucideIcons.check, color: Colors.green),
                              onPressed: _updateNickname,
                            ),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Nickname: $userNickname", style: JoviTheme.fontPoppins.copyWith(fontSize: 16)),
                  IconButton(
                    icon: const Icon(LucideIcons.edit, size: 20),
                    onPressed: () => setState(() {
                      _isEditing = true;
                      _errorMessage = null; // Limpiar error al empezar a editar
                    }),
                  ),
                ],
              ),
            
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Text(_errorMessage!, style: const TextStyle(color: JoviTheme.red)),
              ),

            const SizedBox(height: 40),
            
            // BOTÓN CERRAR SESIÓN
            ElevatedButton.icon(
              onPressed: widget.onSignOut,
              icon: const Icon(LucideIcons.logOut),
              label: const Text("Cerrar Sesión"),
              style: ElevatedButton.styleFrom(
                backgroundColor: JoviTheme.yellow,
                foregroundColor: JoviTheme.blue,
                padding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 15),
            
            // BOTÓN DE CONFIGURACIÓN DE SUBIDA (NUEVO)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              icon: const Icon(LucideIcons.settings),
              label: const Text("Preferencias de Subida"),
              style: ElevatedButton.styleFrom(
                backgroundColor: JoviTheme.gray,
                foregroundColor: JoviTheme.blue,
                padding: const EdgeInsets.all(12),
              ),
            ),

            const SizedBox(height: 15),
            
            // BOTÓN ELIMINAR CUENTA
            TextButton(
              onPressed: _showDeleteConfirmation,
              child: _isDeleting 
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: JoviTheme.red), 
                      SizedBox(width: 8), 
                      Text("Eliminando...", style: TextStyle(color: JoviTheme.red))
                    ],
                  )
                : const Text("Eliminar Cuenta", style: TextStyle(color: JoviTheme.red)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. PANTALLA MAPA Y LISTENER
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

    try {
      await mapboxMap!.loadStyleURI("mapbox://styles/mapbox/outdoors-v12");
    } catch (e) {
      print("❌ ERROR: Mapbox style load failed: $e");
    }

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
    } catch(e) {
      print("⚠️ Avatar 3D no disponible: $e");
    }

    circleAnnotationManager = await map.annotations.createCircleAnnotationManager();
    await _drawPoints();

    circleAnnotationManager?.addOnCircleAnnotationClickListener(
      MyAnnotationClickListener(onTap: (annotation) {
        try {
          final stop = liveStops.firstWhere((s) =>
            (s['lat'] - annotation.geometry.coordinates.lat).abs() < 0.0001 &&
            (s['lng'] - annotation.geometry.coordinates.lng).abs() < 0.0001
          );
          setState(() => selectedStop = stop);
        } catch (e) {
          print("Error al encontrar parada: $e");
        }
      })
    );
  }

 // lib/screens/app_screens.dart (Fragmento de _MapGameScreenState)

_drawPoints() async {
    if (circleAnnotationManager == null) return;

    await circleAnnotationManager?.deleteAll();
    for (var stop in liveStops) {
      await circleAnnotationManager?.create(CircleAnnotationOptions(
        geometry: Point(coordinates: Position(stop['lng'], stop['lat'])),
        
        // 💡 CAMBIOS CLAVE PARA HACERLOS PEQUEÑOS Y DISCRETOS
        circleColor: JoviTheme.yellow.value, // Cambiamos a amarillo (JoviTheme)
        circleRadius: 6.0,                   // Reducido drásticamente (antes 15.0)
        circleStrokeWidth: 1.5,              // Borde más fino (antes 4.0)
        circleStrokeColor: JoviTheme.blue.value, // Color de borde a azul (JoviTheme)
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
          onMapCreated: _onMapCreated,
        ),

        if (isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: JoviTheme.yellow)
            ),
          ),

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
                    builder: (_) => AddStopScreen(currentPosition: currentPosition!)
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
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenImageScreen(
                              imageUrl: selectedStop!['image'],
                              title: selectedStop!['title'],
                            ),
                          ),
                        );
                      },
                      child: CachedNetworkImage(
                        imageUrl: selectedStop!['image'],
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (c, u) => Container(color: Colors.grey[300]),
                      ),
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
                    subtitle: Text(
                      '${selectedStop!['type']} | Creado por: ${selectedStop!['author']}'
                    ),
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

// ==========================================
// 3. PANTALLA AR
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

// ==========================================
// 4. AÑADIR SITIO (ADD STOP) - CON GESTIÓN OFFLINE
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

  // Lógica para verificar si se permite la subida en el estado actual de la red
  Future<bool> _isUploadAllowed() async {
    final preference = await _settingsService.getUploadPreference();
    final connectivityResult = await (Connectivity().checkConnectivity());
    
    if (preference == 'both') return connectivityResult != ConnectivityResult.none;
    if (preference == 'wifi') return connectivityResult == ConnectivityResult.wifi;
    if (preference == 'cellular') return connectivityResult == ConnectivityResult.mobile;
    
    return false;
  }

  Future<void> _submitData() async {
    if (_formKey.currentState!.validate() && _imageFile != null) {
      
      final isAllowed = await _isUploadAllowed();
      
      final currentUser = FirebaseAuth.instance.currentUser;
      final authorNickname = currentUser?.displayName ?? "Anónimo"; 
      // 💡 OBTENER EL UID DEL USUARIO
      final authorId = currentUser?.uid ?? 'anonimo_offline'; 
      
      final newStop = NewStopData(
        title: _titleController.text,
        author: authorNickname,
        type: _typeController.text,
        lat: widget.currentPosition.latitude,
        lng: widget.currentPosition.longitude,
        imageFile: _imageFile!,
        authorId: authorId, // PROPORCIONAR EL authorId
      );
      
      if (!isAllowed) {
          // Opción OFF-LINE: Notificamos al usuario y salimos
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Guardado localmente. Se subirá al cumplir las preferencias de red.'),
              backgroundColor: JoviTheme.blue,
            ),
          );
          Navigator.pop(context); 
          return; 
      }
      
      // Opción ON-LINE: Intentamos la subida inmediatamente
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
          // Si falla a pesar de tener conexión, es un error de servidor/permisos
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error de servidor o permisos. Revisa las reglas de Firebase.'),
              duration: Duration(seconds: 5),
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
                'Autor: ${FirebaseAuth.instance.currentUser?.displayName ?? "Anónimo"}', // Muestra el nickname del autor
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: JoviTheme.blue
                ),
              ),
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