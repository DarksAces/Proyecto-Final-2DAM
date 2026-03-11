import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ar_service.dart';
import '../main.dart'; // For JoviTheme

class UploadARModelScreen extends StatefulWidget {
  const UploadARModelScreen({super.key});

  @override
  State<UploadARModelScreen> createState() => _UploadARModelScreenState();
}

class _UploadARModelScreenState extends State<UploadARModelScreen> {
  File? _selectedFile;
  String? _fileName;
  final _nameController = TextEditingController();
  final ARService _arService = ARService();
  bool _isUploading = false;
  String? _uploadStatus;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Changed from custom to any to avoid filtering issues
        // allowedExtensions: ['glb', 'gltf'], // Removed to allow all files for now
      );

      if (result != null) {
        if (result.files.single.path != null) {
          final path = result.files.single.path!;
          final name = result.files.single.name;
          
          // Basic validation check
          if (!name.toLowerCase().endsWith('.glb') && !name.toLowerCase().endsWith('.gltf')) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Aviso: El archivo seleccionado no parece ser .glb o .gltf')),
            );
          }

          setState(() {
            _selectedFile = File(path);
            _fileName = name;
            // Auto-fill name if empty
            if (_nameController.text.isEmpty) {
              _nameController.text = _fileName!.split('.').first;
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir selector: $e')),
      );
    }
  }

  Future<void> _uploadModel() async {
    if (_selectedFile == null || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un archivo y ponle un nombre')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadStatus = "Obteniendo ubicación...";
    });

    try {
      // 1. Get Location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
           throw Exception("Permisos de ubicación denegados");
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() => _uploadStatus = "Subiendo modelo...");

      final user = FirebaseAuth.instance.currentUser;
      final authorId = user?.uid ?? 'anonymous';

      // 2. Upload
      bool success = await _arService.uploadModel(
        file: _selectedFile!,
        name: _nameController.text,
        lat: position.latitude,
        lng: position.longitude,
        authorId: authorId,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Modelo subido correctamente')),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception("Error al subir a Firebase");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadStatus = "Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoviTheme.gray,
      appBar: AppBar(
        title: const Text("Subir Modelo AR"),
        backgroundColor: JoviTheme.yellow,
        foregroundColor: JoviTheme.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: JoviTheme.blue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Selecciona un archivo .glb o .gltf de tu dispositivo. Este modelo se ubicará en tu posición GPS actual.",
                        style: TextStyle(color: JoviTheme.blue),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
        
              // File Picker Area
              GestureDetector(
                onTap: _isUploading ? null : _pickFile,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedFile != null ? Colors.green : Colors.grey.shade300, 
                      width: 2
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.check_circle : Icons.upload_file,
                        size: 60,
                        color: _selectedFile != null ? Colors.green : JoviTheme.blue,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _fileName ?? "Toca para seleccionar archivo",
                        style: TextStyle(
                          color: _selectedFile != null ? Colors.black : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedFile == null)
                        const Text(
                          "(Formatos: .glb, .gltf)",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
        
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nombre del Modelo",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                enabled: !_isUploading,
              ),
              const SizedBox(height: 30),
        
              if (_uploadStatus != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Center(child: Text(_uploadStatus!, style: const TextStyle(color: JoviTheme.blue, fontWeight: FontWeight.bold))),
                ),
        
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadModel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JoviTheme.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            SizedBox(width: 10),
                            Text("SUBIENDO...")
                          ],
                        )
                      : const Text("SUBIR MODELO", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
