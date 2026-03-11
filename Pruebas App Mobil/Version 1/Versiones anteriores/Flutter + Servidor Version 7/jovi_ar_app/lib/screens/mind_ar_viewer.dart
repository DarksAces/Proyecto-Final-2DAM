import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart'; // For rootBundle

class MindARViewer extends StatefulWidget {
  final String modelPath; // Path to the 3D model (asset or local file)

  const MindARViewer({super.key, required this.modelPath});

  @override
  State<MindARViewer> createState() => _MindARViewerState();
}

class _MindARViewerState extends State<MindARViewer> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            _injectModel();
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadFlutterAsset('assets/mindar/index.html');
  }

  Future<void> _injectModel() async {
    try {
      String modelSrc;
      
      if (widget.modelPath.startsWith('http')) {
        modelSrc = widget.modelPath;
      } else {
        // Load file bytes (either from assets or filesystem)
        Uint8List bytes;
        if (widget.modelPath.startsWith('assets/')) {
          final byteData = await rootBundle.load(widget.modelPath);
          bytes = byteData.buffer.asUint8List();
        } else {
           final file = File(widget.modelPath);
           if (await file.exists()) {
             bytes = await file.readAsBytes();
           } else {
             debugPrint("File not found: ${widget.modelPath}");
             return;
           }
        }
        
        // Convert to Base64 Data URI
        final base64String = base64Encode(bytes);
        modelSrc = "data:model/gltf-binary;base64,$base64String";
      }

      // Inject into WebView
      // Note: We delay slightly to ensure A-Frame is ready, though onPageFinished is usually safe enough.
      // But A-Frame scenes render async.
      final js = "loadCustomModel('$modelSrc');";
      await _controller.runJavaScript(js);
      debugPrint("Injected model into MindAR");

    } catch (e) {
      debugPrint("Error injecting model: $e");
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
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
          
          // Info Overlay
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                   const Text(
                    "Apunta a la imagen objetivo (card.png)",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Modelo: ${widget.modelPath.split('/').last}",
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                    textAlign: TextAlign.center,
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
