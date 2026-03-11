import 'dart:io';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../theme/app_theme.dart';

class ArModelViewerScreen extends StatelessWidget {
  final File? modelFile;
  final String? modelUrl;
  final String title;

  const ArModelViewerScreen({
    super.key,
    this.modelFile,
    this.modelUrl,
    this.title = "Visualizador AR",
  }) : assert(modelFile != null || modelUrl != null,
            "Must provide either a file or a URL");

  @override
  Widget build(BuildContext context) {
    // Prefer Local File to avoid CORS issues in WebView
    final String source =
        modelFile != null ? 'file://${modelFile!.path}' : modelUrl!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Loading Indicator behind the model
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.joviRed),
                SizedBox(height: 20),
                Text("Cargando modelo 3D...",
                    style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),

          ModelViewer(
            key: ValueKey(source),
            backgroundColor: Colors.transparent, // Allow loader to show behind
            src: source,
            alt: "Un modelo 3D generado",
            ar: true,
            autoRotate: true,
            cameraControls: true,
            disableZoom: false,
            loading: Loading.eager,
          ),

          // Helper Overlay
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.joviRed.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.view_in_ar, color: AppTheme.joviRed, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Toca el icono AR para verlo en tu espacio",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Fallback info if black screen persists
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                modelUrl != null
                    ? "Cargando desde la nube..."
                    : "Cargando archivo local...",
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
