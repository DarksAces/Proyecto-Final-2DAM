import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/capture_session.dart';
import '../services/camera_service.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'model_viewer_screen.dart';

class CaptureScreen extends StatefulWidget {
  final CaptureSession session;

  const CaptureScreen({super.key, required this.session});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final CameraService _cameraService = CameraService();
  final ApiService _apiService = ApiService();
  final List<String> _capturedImages = [];
  bool _isInitialized = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _cameraService.initialize();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final xFile = await _cameraService.takePicture();
    if (xFile != null) {
      setState(() {
        _capturedImages.add(xFile.path);
      });
    }
  }

  Future<void> _finishCapture() async {
    if (_capturedImages.isEmpty) return;

    setState(() => _isUploading = true);
    try {
      await _apiService.uploadImages(widget.session.id, _capturedImages);
      await _apiService.startProcessing(widget.session.id);
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ModelViewerScreen(sessionId: widget.session.id),
        ),
      );
    } catch (e) {
      if (mounted) showSnackBar(context, "Error uploading: $e", isError: true);
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Capture (${_capturedImages.length}/${AppConstants.requiredPhotos})'),
        actions: [
          if (_capturedImages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _isUploading ? null : _finishCapture,
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                CameraPreview(_cameraService.controller!),
                // Guide overlay
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                if (_isUploading)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          Container(
            height: 120,
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery preview
                SizedBox(
                  width: 60,
                  height: 60,
                  child: _capturedImages.isNotEmpty
                      ? Image.file(File(_capturedImages.last), fit: BoxFit.cover)
                      : Container(color: Colors.grey),
                ),
                // Capture button
                GestureDetector(
                  onTap: _isUploading ? null : _takePicture,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 4),
                    ),
                  ),
                ),
                const SizedBox(width: 60), // Spacer for symmetry
              ],
            ),
          ),
        ],
      ),
    );
  }
}
