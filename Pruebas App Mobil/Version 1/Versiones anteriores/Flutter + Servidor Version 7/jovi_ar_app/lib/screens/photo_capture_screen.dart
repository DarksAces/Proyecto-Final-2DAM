import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ar_service.dart';
import '../main.dart'; // For JoviTheme

class PhotoCaptureScreen extends StatefulWidget {
  const PhotoCaptureScreen({super.key});

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  final List<XFile> _capturedImages = [];
  bool _isInit = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInit = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    try {
      setState(() => _isCapturing = true);
      final image = await _controller!.takePicture();
      setState(() {
        _capturedImages.add(image);
        _isCapturing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Foto ${_capturedImages.length} capturada"), duration: const Duration(milliseconds: 500)),
      );

    } catch (e) {
      debugPrint("Capture error: $e");
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al capturar: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _finishCapture() async {
    if (_capturedImages.length < 3) return;

    setState(() => _isCapturing = true); 

    try {
      final List<File> files = _capturedImages.map((e) => File(e.path)).toList();
      final arService = ARService(); 
      final String? batchId = await arService.uploadPhotosForProcessing(files);

      setState(() => _isCapturing = false); // Stop local spinner

      if (batchId != null) {
        // TRIGGER SIMULATION (Acting as the backend)
        // In a real app, the server would do this automatically.
        arService.simulateBackendProcessing(batchId);

        // Show Stream Dialog to wait for server
        _showProcessingDialog(arService, batchId);
      } else {
        throw Exception("Fallo al subir las fotos.");
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showProcessingDialog(ARService arService, String batchId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StreamBuilder<DocumentSnapshot>(
          stream: arService.listenToProcessingJob(batchId),
          builder: (context, snapshot) {
             String status = "pending";
             String? modelUrl;
             
             if (snapshot.hasData && snapshot.data!.exists) {
               final data = snapshot.data!.data() as Map<String, dynamic>;
               status = data['status'] ?? 'pending';
               modelUrl = data['model_url']; // Backend should set this
             }

             if (status == 'completed' && modelUrl != null) {
               // Close dialog after a brief delay and return result
               Future.delayed(Duration.zero, () {
                 if (Navigator.canPop(context)) Navigator.pop(context); // Close dialog
                 if (Navigator.canPop(context)) Navigator.pop(context, modelUrl); // Close Screen with result
               });
               return const SizedBox(); // Invisible while closing
             }

             return Dialog(
               backgroundColor: Colors.black87,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
               child: Padding(
                 padding: const EdgeInsets.all(24),
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     const CircularProgressIndicator(color: JoviTheme.blue),
                     const SizedBox(height: 20),
                     const Text("Procesando en la nube...", style: TextStyle(color: Colors.white, fontSize: 18)),
                     const SizedBox(height: 10),
                     Text("Estado: $status", style: const TextStyle(color: Colors.white70)),
                     const SizedBox(height: 20),
                     const Text("Puedes cerrar la app, te avisaremos cuando esté listo.", 
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12)
                     ),
                     const SizedBox(height: 10),
                     TextButton(
                       onPressed: () => Navigator.pop(context),
                       child: const Text("Cancelar / Esperar en segundo plano"),
                     )
                   ],
                 ),
               ),
             );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          SizedBox.expand(
            child: CameraPreview(_controller!),
          ),

          // Top Bar
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
          
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${_capturedImages.length} Fotos",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thumbnails
                  if (_capturedImages.isNotEmpty)
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _capturedImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: JoviTheme.yellow, width: 2),
                              ),
                              child: Image.file(
                                File(_capturedImages[index].path),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Generate Button (Visible only if enough photos)
                      if (_capturedImages.length >= 3)
                        ElevatedButton.icon(
                          onPressed: _finishCapture,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text("GENERAR 3D"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: JoviTheme.blue,
                            foregroundColor: Colors.white,
                          ),
                        )
                      else
                        // Show counter/instruction instead of empty space
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                             "Faltan ${3 - _capturedImages.length}", 
                             style: const TextStyle(color: Colors.white70)
                          ),
                        ),

                      // Capture Button
                      GestureDetector(
                        onTap: _takePicture,
                        child: _isCapturing 
                          ? const SizedBox(
                              width: 80, 
                              height: 80, 
                              child: CircularProgressIndicator(color: JoviTheme.yellow)
                            )
                          : Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 80), // Balance the row
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
