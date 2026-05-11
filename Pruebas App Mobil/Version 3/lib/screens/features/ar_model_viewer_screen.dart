import 'dart:io';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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

    print("DEBUG: ModelViewer loading source: $source");
    if (modelFile != null) {
      print("DEBUG: File exists: ${modelFile!.existsSync()}");
      print("DEBUG: File size: ${modelFile!.lengthSync()} bytes");
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (modelUrl != null)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: "Descargar modelo .glb",
              onPressed: () => _downloadModel(context),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Loading Indicator behind the model
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.arteRed),
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
                      color: AppTheme.arteRed.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.view_in_ar, color: AppTheme.arteRed, size: 20),
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

  Future<void> _downloadModel(BuildContext context) async {
    try {
      if (modelUrl == null) return;

      // 1. Request Permission
      if (Platform.isAndroid) {
        // For Android 13+, storage permission is split, but for saving to Downloads 
        // sometimes no permission is needed if using MediaStore, 
        // but here we use direct file access for simplicity in the Download folder.
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          // Try to continue anyway as some devices allow it
          debugPrint("Storage permission not granted, attempting download anyway...");
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Iniciando descarga del modelo 3D..."),
          duration: Duration(seconds: 2),
        ),
      );

      // 2. Download
      final response = await http.get(Uri.parse(modelUrl!));
      if (response.statusCode == 200) {
        // 3. Determine save path
        Directory? dir;
        if (Platform.isAndroid) {
          // Standard Android Downloads folder
          dir = Directory('/storage/emulated/0/Download');
          if (!await dir.exists()) {
            dir = await getExternalStorageDirectory();
          }
        } else {
          dir = await getApplicationDocumentsDirectory();
        }

        if (dir == null) throw Exception("No se pudo encontrar una ruta para guardar");

        final cleanTitle = title.replaceAll(RegExp(r'[^\w\s]+'), '_').trim();
        final fileName = "ARte_${cleanTitle}_${DateTime.now().millisecondsSinceEpoch}.glb";
        final filePath = "${dir.path}/$fileName";
        final file = File(filePath);
        
        await file.writeAsBytes(response.bodyBytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Modelo guardado en: $fileName"),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: "CERRAR",
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      } else {
        throw Exception("Error del servidor: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error downloading: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error al descargar: $e"),
            backgroundColor: AppTheme.arteRed,
          ),
        );
      }
    }
  }
}
