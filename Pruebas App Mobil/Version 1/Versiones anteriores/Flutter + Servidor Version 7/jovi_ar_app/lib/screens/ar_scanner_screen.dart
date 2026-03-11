import 'package:ar_flutter_plugin_flutterflow/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_flutterflow/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_flutterflow/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/models/ar_node.dart';
import 'package:ar_flutter_plugin_flutterflow/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_flutterflow/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_flutterflow/datatypes/hittest_result_types.dart'; // Sometimes needed

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // For loading assets
import 'dart:io'; // For File
import 'package:path_provider/path_provider.dart'; // For temp directory
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:geolocator/geolocator.dart';
import '../services/ar_service.dart';
import '../screens/upload_ar_model_screen.dart';
import '../screens/photo_capture_screen.dart';
import '../screens/mind_ar_viewer.dart';
import '../main.dart'; // For JoviTheme

// ==========================================
// 7. AR SCANNER (VIEWER & SELECTOR)
// ==========================================

class ARScannerScreen extends StatefulWidget {
  const ARScannerScreen({super.key});
  @override
  State<ARScannerScreen> createState() => _ARScannerScreenState();
}

class _ARScannerScreenState extends State<ARScannerScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  final ARService _arService = ARService();
  List<ARModel> _allModels = [];
  List<ARModel> _nearbyModels = [];
  int? _selectedModelIndex; // Track selected model

  bool _isLoading = true;
  Position? _userPosition;
  String _statusMessage = "Buscando ubicación...";
  String? _error;

  // Show all models regardless of distance effectively (world is large)
  final double _activationRadiusMeters = 50000; 

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    try {
      Position position = await _determinePosition();
      if (!mounted) return;

      setState(() {
        _userPosition = position;
        _statusMessage = "Cargando modelos...";
      });

      _fetchModels();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _statusMessage = "Error de GPS: $e";
        _error = e.toString();
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Servicios de ubicación desactivados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permisos de ubicación denegados.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permisos denegados permanentemente.');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  void _fetchModels() {
    // Listen to stream of models
    _arService.getNearbyModels().listen((models) {
      if (!mounted) return;
      setState(() {
        _allModels = models;
      });
      _filterNearbyModels();
    }, onError: (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = "Error cargando modelos";
        _error = e.toString();
        _isLoading = false;
      });
    });
  }

  void _filterNearbyModels() {
    if (_userPosition == null) return;

    // Filter by loose radius just to avoid loading models from other countries if we wanted
    final filtered = _allModels.where((model) {
      double distance = Geolocator.distanceBetween(
        _userPosition!.latitude,
        _userPosition!.longitude,
        model.latitude,
        model.longitude,
      );
      return distance <= _activationRadiusMeters;
    }).toList();

    setState(() {
      _nearbyModels = filtered;
      _isLoading = false;
      _statusMessage = filtered.isEmpty
          ? "No hay modelos cerca."
          : "¡${filtered.length} modelos encontrados! Selecciona uno.";
    });
  }

  void _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;

    arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true, 
      customPlaneTexturePath: "Images/triangle.png",
      showWorldOrigin: false,
      handleTaps: false, // DISABLE TAPS per user request
    );
    arObjectManager!.onInitialize();
  }

  ARNode? _currentNode; 

  // Select a model to display -> Spawn immediately
  Future<void> _selectModel(int index) async {
    if (arObjectManager == null) return;

    // 1. Clear previous
    if (_currentNode != null) {
      await arObjectManager!.removeNode(_currentNode!);
      _currentNode = null;
    }

    setState(() {
      _selectedModelIndex = index;
    });

    final model = _nearbyModels[index];
    
    // User feedback
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text("Cargando: ${model.name}...")),
       );
    }

    // 2. Prepare Model Path
    NodeType nodeType = NodeType.webGLB;
    String finalUri = model.url;

    if (!model.url.startsWith("http")) {
      try {
         final absolutePath = await _copyAssetToLocal(model.url); 
         finalUri = absolutePath.split('/').last; 
         nodeType = NodeType.fileSystemAppFolderGLB;
         
         final checkFile = File(absolutePath);
         if (!await checkFile.exists()) {
             throw Exception("Archivo no encontrado: $absolutePath");
         }
      } catch (e) {
        debugPrint("Error preparing local file: $e");
        return;
      }
    }

    // 3. Spawn Node Floating in front of camera
    // Note: We use rotation 0 to face camera usually, but might need adjustment.
    var newNode = ARNode(
      type: nodeType,
      uri: finalUri,
      scale: vector.Vector3(0.5, 0.5, 0.5),
      position: vector.Vector3(0, 0, -1.0), // 1 meter in front (-Z is usually forward in common AR)
      rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0),
    );

    bool? success = await arObjectManager!.addNode(newNode);
    if (success == true) {
      _currentNode = newNode;
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Mostrando: ${model.name}")),
        );
      }
    } else {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error mostrando el modelo")),
        );
       }
    }
  }

  // Tap handler removed as we are auto-placing
  Future<void> _onPlaneOrPointTap(List<ARHitTestResult> hitTestResults) async {}

  // Helper to copy bundled asset to a persistent file usable by AR plugin
  Future<String> _copyAssetToLocal(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    // Use ApplicationDocumentsDirectory instead of Temp (more reliable for some plugins)
    final docDir = await getApplicationDocumentsDirectory();
    final fileName = assetPath.split('/').last;
    final file = File('${docDir.path}/$fileName');
    
    await file.writeAsBytes(byteData.buffer.asUint8List(
      byteData.offsetInBytes, 
      byteData.lengthInBytes
    ));
    
    return file.path;
  }

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
          ),

          // Back Button
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Debug/Status Overlay
          if (_isLoading || _error != null)
             Positioned(
               top: 100,
               left: 20, 
               right: 20,
               child: Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: Colors.black54,
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Text(
                   _error ?? _statusMessage,
                   style: TextStyle(color: _error != null ? Colors.redAccent : Colors.white),
                   textAlign: TextAlign.center,
                 ),
               )
             ),

          // MODEL CAROUSEL (Bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 160, // Height for carousel + button
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                )
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   // Carousel
                   if (!_isLoading && _nearbyModels.isNotEmpty)
                     SizedBox(
                       height: 100,
                       child: ListView.builder(
                         scrollDirection: Axis.horizontal,
                         padding: const EdgeInsets.symmetric(horizontal: 16),
                         itemCount: _nearbyModels.length,
                         itemBuilder: (context, index) {
                           final model = _nearbyModels[index];
                           final isSelected = _selectedModelIndex == index;
                           
                           return GestureDetector(
                             onTap: () => _selectModel(index),
                             child: Container(
                               width: 80,
                               margin: const EdgeInsets.only(right: 12),
                               decoration: BoxDecoration(
                                 color: isSelected ? JoviTheme.yellow : Colors.white,
                                 borderRadius: BorderRadius.circular(12),
                                 border: isSelected ? Border.all(color: JoviTheme.blue, width: 2) : null,
                               ),
                               child: Column(
                                 mainAxisAlignment: MainAxisAlignment.center,
                                 children: [
                                   const Icon(Icons.view_in_ar, size: 30, color: Colors.black87),
                                   const SizedBox(height: 4),
                                   Text(
                                     model.name,
                                     maxLines: 1,
                                     overflow: TextOverflow.ellipsis,
                                     style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                     textAlign: TextAlign.center,
                                   ),
                                 ],
                               ),
                             ),
                           );
                         },
                       ),
                     ),
                   
                   // Upload Button Area
                   Padding(
                     padding: const EdgeInsets.all(12.0),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         // Refresh Button
                         IconButton(
                           icon: const Icon(Icons.refresh, color: Colors.white),
                           onPressed: _initializeScanner,
                         ),
                         // Create 3D Button (Camera)
                         FloatingActionButton.small(
                            heroTag: "create3dBtn",
                            backgroundColor: Colors.orange,
                            child: const Icon(Icons.camera_alt, color: Colors.white),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const PhotoCaptureScreen()),
                              );
                              
                              if (result != null && result is String) {
                                // 1. Añadir a la lista de "cercanos"
                                final newModel = ARModel(
                                  id: "generated_01",
                                  name: "Modelo Generado",
                                  // description: "Modelo creado por fotogrametría", // Removed
                                  url: result, // "assets/avatar.glb"
                                  latitude: _userPosition?.latitude ?? 0,
                                  longitude: _userPosition?.longitude ?? 0,
                                  authorId: "me",
                                  // thumbnailUrl: "", // Removed
                                  timestamp: DateTime.now(),
                                );

                                setState(() {
                                  _nearbyModels.add(newModel);
                                });

                                // 2. Seleccionarlo automáticamente para verlo
                                // Esperamos un frame para que la lista se actualice
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  _selectModel(_nearbyModels.length - 1);
                                });

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("¡Modelo 3D Generado! Se ha añadido a tu escena."),
                                      backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                         ),
                         const SizedBox(width: 8),
                       // Upload Button
                         FloatingActionButton.small(
                            heroTag: "uploadBtn",
                            backgroundColor: JoviTheme.blue,
                            child: const Icon(Icons.add, color: Colors.white),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const UploadARModelScreen()),
                              );
                              _initializeScanner(); // Refresh on return
                            },
                         ),
                         
                         // MindAR Button (Image Tracking) - NEW
                         if (_selectedModelIndex != null)
                           Padding(
                             padding: const EdgeInsets.only(left: 8.0),
                             child: FloatingActionButton.small(
                               heroTag: "mindArBtn",
                               backgroundColor: Colors.purple,
                               child: const Icon(Icons.qr_code_scanner, color: Colors.white),
                               onPressed: () {
                                 final model = _nearbyModels[_selectedModelIndex!];
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => MindARViewer(modelPath: model.url),
                                   ),
                                 );
                               },
                             ),
                           ),
                       ],
                     ),
                   ),
                ],
              ),
            ),
          ),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
