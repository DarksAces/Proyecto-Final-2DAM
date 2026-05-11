import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_theme.dart';
import '../../services/ar_generation_service.dart';
import 'ar_model_viewer_screen.dart';

class ArScannerScreen extends StatefulWidget {
  const ArScannerScreen({super.key});

  @override
  State<ArScannerScreen> createState() => _ArScannerScreenState();
}

class _ArScannerScreenState extends State<ArScannerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  final ArGenerationService _arService = ArGenerationService();

  bool _isGenerating = false;
  String? _statusMessage;
  bool _showSuccess = false;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        setState(() => _statusMessage = "Permiso de cámara denegado");
      }
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = "Error al iniciar cámara: $e");
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureAndGenerate() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _initializeCamera();
      return;
    }

    // 1. Check if user can generate more
    final canMore = await _arService.canGenerateMore();
    if (!canMore) {
      if (mounted) {
        _showLimitDialog();
      }
      return;
    }

    setState(() {
      _isGenerating = true;
      _statusMessage = "Analizando escena...";
      _showSuccess = false;
    });

    // Dynamic message rotation
    final List<String> messages = [
      "¡Captura lista! Ya puedes bajar el móvil.",
      "Analizando formas y texturas...",
      "Nuestra IA está esculpiendo el 3D...",
      "Generando malla poligonal...",
      "Optimizando para Realidad Aumentada...",
      "Sincronizando con tu nube personal...",
    ];
    
    int msgIndex = 0;
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isGenerating || !mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        msgIndex = (msgIndex + 1) % messages.length;
        _statusMessage = messages[msgIndex];
      });
    });

    try {
      // 2. Take Picture
      final XFile photo = await _cameraController!.takePicture();

      // 3. Generate and Sync to Firebase
      final File? localFile =
          await _arService.generateAndUpload3DModel(File(photo.path));

      if (localFile != null) {
        if (mounted) {
          setState(() {
            _showSuccess = true;
            _statusMessage = "¡Listo! Abriendo visor...";
          });
        }

        // 4. Navigate to Viewer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArModelViewerScreen(
              modelFile: localFile,
              title: "Obra AR Generada",
            ),
          ),
        );
      } else {
        if (mounted) {
          setState(() {
            _statusMessage = "Error en la generación. Reintenta.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage =
              "Error: ${e.toString().replaceAll("Exception: ", "")}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Límite Alcanzado",
            style: TextStyle(color: Colors.white)),
        content: const Text(
          "Has alcanzado el límite de 5 objetos AR generados. Elimina alguno o contacta con soporte para ampliar tu cuenta.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ENTENDIDO",
                style: TextStyle(color: AppTheme.arteRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Real Camera Feed or Placeholder
              _isCameraInitialized && _cameraController != null
                  ? SizedBox.expand(
                      child: CameraPreview(_cameraController!),
                    )
                  : Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 100,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Iniciando cámara...",
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    ),
    
              // Scanner Overlay
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5), width: 1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    _buildCorner(Alignment.topLeft),
                    _buildCorner(Alignment.topRight),
                    _buildCorner(Alignment.bottomLeft),
                    _buildCorner(Alignment.bottomRight),
    
                    // Pulsing Scan Line
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset:
                              Offset(0, 140 * (_animationController.value * 2 - 1)),
                          child: Container(
                            width: 260,
                            height: 2,
                            decoration:
                                BoxDecoration(color: AppTheme.arteRed, boxShadow: [
                              BoxShadow(
                                  color: AppTheme.arteRed.withValues(alpha: 0.6),
                                  blurRadius: 10,
                                  spreadRadius: 2)
                            ]),
                          ),
                        );
                      },
                    )
                  ],
                ),
              ),
    
              // UI Overlay
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 30),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _isGenerating ? "Procesando..." : "Cámara AR",
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 48), // Spacer
                        ],
                      ),
                    ),
    
                    const Spacer(),
    
                    // Status Message
                    if (_statusMessage != null && !_isGenerating)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    _showSuccess ? Colors.green : AppTheme.arteRed),
                          ),
                          child: Text(
                            _statusMessage!,
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
    
                    const SizedBox(height: 20),
    
                    // Action Button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 50),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _isGenerating ? null : _captureAndGenerate,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: const BoxDecoration(
                                  color: AppTheme.arteRed,
                                  shape: BoxShape.circle,
                                ),
                                child: _isGenerating
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                            color: Colors.white))
                                    : const Icon(Icons.auto_awesome,
                                        color: Colors.white, size: 35),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "DISPARAR Y GENERAR 3D",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Processing Overlay
        if (_isGenerating)
          _buildProcessingOverlay(),
      ],
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withAlpha(220),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 80, height: 80,
                child: CircularProgressIndicator(
                  color: AppTheme.arteRed,
                  strokeWidth: 6,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                _statusMessage ?? "Procesando...",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "¡Ya puedes bajar el móvil! Tu obra se está esculpiendo en la nube.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: alignment.y == -1
                ? const BorderSide(color: AppTheme.arteRed, width: 4)
                : BorderSide.none,
            bottom: alignment.y == 1
                ? const BorderSide(color: AppTheme.arteRed, width: 4)
                : BorderSide.none,
            left: alignment.x == -1
                ? const BorderSide(color: AppTheme.arteRed, width: 4)
                : BorderSide.none,
            right: alignment.x == 1
                ? const BorderSide(color: AppTheme.arteRed, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
