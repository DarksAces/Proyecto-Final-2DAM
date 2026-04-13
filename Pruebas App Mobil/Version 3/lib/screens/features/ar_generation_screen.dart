import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/ar_generation_service.dart';

class ArGenerationScreen extends StatefulWidget {
  const ArGenerationScreen({super.key});

  @override
  State<ArGenerationScreen> createState() => _ArGenerationScreenState();
}

class _ArGenerationScreenState extends State<ArGenerationScreen> {
  final ArGenerationService _arService = ArGenerationService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isGenerating = false;
  String? _statusMessage;
  bool _showSuccess = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
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

    setState(() {
      _isGenerating = true;
      _statusMessage =
          "Despertando servidor y procesando... (puede tardar 50s+)";
      _showSuccess = false;
    });

    try {
      final result = await _arService.generate3DModel(_selectedImage!);

      if (mounted) {
        if (result != null) {
          setState(() {
            _showSuccess = true;
            _statusMessage = "¡Modelo 3D generado con éxito!";
          });
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
          _statusMessage = "Error de conexión: $e";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                color: AppTheme.auraRed.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppTheme.auraRed.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppTheme.auraRed, size: 40),
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
              onTap: _isGenerating ? null : _pickImage,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _selectedImage != null
                        ? AppTheme.auraRed
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
                                    onPressed: _pickImage,
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
                            "Toca para seleccionar imagen",
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
            if (_statusMessage != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: _showSuccess
                      ? Colors.green.withValues(alpha: 0.1)
                      : AppTheme.auraYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _showSuccess ? Icons.check_circle : Icons.info_outline,
                      color: _showSuccess ? Colors.green : AppTheme.auraYellow,
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
                backgroundColor: AppTheme.auraRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: _isGenerating
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3),
                    )
                  : const Text(
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
                  // This could navigate back to AR Scanner or a specific viewer
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.view_in_ar),
                label: const Text("PROBAR EN SCANNER AR"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.auraRed,
                  side: const BorderSide(color: AppTheme.auraRed),
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
    );
  }
}
