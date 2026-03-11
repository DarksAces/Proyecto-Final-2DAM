import 'dart:async';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../services/api_service.dart';
import '../models/capture_session.dart';

class ModelViewerScreen extends StatefulWidget {
  final String sessionId;

  const ModelViewerScreen({super.key, required this.sessionId});

  @override
  State<ModelViewerScreen> createState() => _ModelViewerScreenState();
}

class _ModelViewerScreenState extends State<ModelViewerScreen> {
  final ApiService _apiService = ApiService();
  CaptureSession? _session;
  Timer? _pollTimer;
  bool _isModelReady = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final session = await _apiService.getSession(widget.sessionId);
        if (mounted) {
          setState(() {
            _session = session;
          });
          
          if (session.status == 'completed' && session.modelUrl != null) {
            timer.cancel();
            setState(() => _isModelReady = true);
          } else if (session.status == 'failed') {
            timer.cancel();
            // Handle error
          }
        }
      } catch (e) {
        print("Polling error: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('3D Model')),
      body: _isModelReady && _session?.modelUrl != null
          ? ModelViewer(
              src: _apiService.getModelUrl(_session!.modelUrl!),
              alt: "A 3D model of the captured object",
              ar: true,
              autoRotate: true,
              cameraControls: true,
              backgroundColor: Colors.black12,
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text('Processing: ${_session?.status ?? "Initializing"}...'),
                ],
              ),
            ),
    );
  }
}
