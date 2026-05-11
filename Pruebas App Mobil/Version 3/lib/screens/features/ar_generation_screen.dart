import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/ar_generation_service.dart';
import '../../services/user_service.dart';
import 'ar_model_viewer_screen.dart';

class ArGenerationScreen extends StatefulWidget {
  const ArGenerationScreen({super.key});

  @override
  State<ArGenerationScreen> createState() => _ArGenerationScreenState();
}

class _ArGenerationScreenState extends State<ArGenerationScreen> {
  final ArGenerationService _arService = ArGenerationService();
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isGenerating = false;
  String? _statusMessage;
  bool _showSuccess = false;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _showSuccess = false;
        _statusMessage = null;
      });
    }
  }

  Future<void> _generate3D() async {
    if (_selectedImage == null) return;

    // 1. Check if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _statusMessage = "Debes iniciar sesión para generar modelos AR.";
      });
      return;
    }

    // 2. Check if user can generate more
    final canMore = await _arService.canGenerateMore();
    if (!canMore) {
      if (mounted) {
        _showLimitDialog();
      }
      return;
    }

    setState(() {
      _isGenerating = true;
      _statusMessage = "Analizando imagen...";
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
      // 3. Generate and Sync to Firebase
      final localFile = await _arService.generateAndUpload3DModel(_selectedImage!);

      if (mounted) {
        if (localFile != null) {
          setState(() {
            _showSuccess = true;
            _statusMessage = "¡Modelo 3D generado y guardado! +50 pts";
          });

          // Award +50 points for generating AR content
          await _userService.addPoints(user.uid, 50);

          // 4. Navigate to Viewer
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArModelViewerScreen(
                modelFile: localFile,
                title: "Modelo AR Generado",
              ),
            ),
          );
        } else {
          setState(() {
            _statusMessage =
                "Error al generar el modelo. Reintenta en unos segundos.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = "Error: ${e.toString().replaceAll("Exception: ", "")}";
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
          "Has alcanzado el límite de 5 objetos AR generados. Elimina alguno en tu galería para crear más.",
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
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Generar AR',
                style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.arteRed.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppTheme.arteRed.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: AppTheme.arteRed, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        "Conversor 2D a 3D",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Sube una imagen y nuestra IA generará un modelo 3D (.glb) para tu experiencia AR.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
    
                // Image Selection Area
                GestureDetector(
                  onTap: _isGenerating ? null : () => _showPickerOptions(context),
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _selectedImage != null
                            ? AppTheme.arteRed
                            : Colors.grey.shade300,
                        width: 2,
                        style: _selectedImage != null
                            ? BorderStyle.solid
                            : BorderStyle.none,
                      ),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(_selectedImage!, fit: BoxFit.cover),
                                if (!_isGenerating)
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      child: IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.white),
                                        onPressed: () => _showPickerOptions(context),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                "Toca para capturar o seleccionar",
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),
    
                // Status Section
                if (_statusMessage != null && !_isGenerating)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: _showSuccess
                          ? Colors.green.withValues(alpha: 0.1)
                          : AppTheme.arteYellow.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _showSuccess ? Icons.check_circle : Icons.info_outline,
                          color: _showSuccess ? Colors.green : AppTheme.arteYellow,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              color: _showSuccess
                                  ? Colors.green.shade700
                                  : Colors.orange.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
    
                // Action Button
                ElevatedButton(
                  onPressed: (_selectedImage == null || _isGenerating)
                      ? null
                      : _generate3D,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.arteRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text(
                    "GENERAR MODELO 3D",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2),
                  ),
                ),
    
                if (_showSuccess) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.view_in_ar),
                    label: const Text("PROBAR EN SCANNER AR"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.arteRed,
                      side: const BorderSide(color: AppTheme.arteRed),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
    
                const SizedBox(height: 40),
    
                // Helpful Tip
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Tip: Usa imágenes con fondos simples y objetos bien definidos para mejores resultados.",
                          style:
                              TextStyle(fontSize: 13, color: Colors.blue.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Full screen processing overlay
        if (_isGenerating)
          _buildProcessingOverlay(),
      ],
    );
  }

  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.arteRed),
              title: const Text('Tomar Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.arteRed),
              title: const Text('Seleccionar de Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withAlpha(200),
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
                "¡Ya puedes soltar tu móvil! Estamos trabajando en tu obra maestra.",
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
}
