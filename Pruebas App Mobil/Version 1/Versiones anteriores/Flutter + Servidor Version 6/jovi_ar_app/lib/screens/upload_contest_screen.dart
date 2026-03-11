import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../main.dart'; // Para JoviTheme

class UploadContestEntryScreen extends StatefulWidget {
  final String? school;
  final String? classId;

  const UploadContestEntryScreen({super.key, this.school, this.classId});

  @override
  State<UploadContestEntryScreen> createState() => _UploadContestEntryScreenState();
}

class _UploadContestEntryScreenState extends State<UploadContestEntryScreen> {
  File? _image;
  final _titleController = TextEditingController();
  final _picker = ImagePicker();
  bool _isUploading = false;
  final ApiService _apiService = ApiService();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitEntry() async {
    if (_image == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Añade imagen y título')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 1. Obtener ubicación actual (necesaria para fase local abierta o simple registro)
      Position position = await Geolocator.getCurrentPosition();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final data = NewStopData(
        title: _titleController.text,
        author: user.displayName ?? "Anónimo",
        type: "contest_art",
        lat: position.latitude,
        lng: position.longitude,
        imageFile: _image!,
        authorId: user.uid,
      );

      bool success = await _apiService.uploadContestEntry(data, school: widget.school, classId: widget.classId);

      if (success) {
        if (mounted) Navigator.pop(context); // Volver al concurso
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al subir')));
        }
      }
    } catch (e) {
      print("Error upload: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoviTheme.gray,
      appBar: AppBar(
        title: const Text("Subir al Concurso"),
        backgroundColor: JoviTheme.yellow,
        foregroundColor: JoviTheme.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // IMAGE PREVIEW
            GestureDetector(
              onTap: () => _showPickerOptions(),
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                  image: _image != null 
                    ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
                    : null
                ),
                child: _image == null 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Toca para añadir foto"),
                      ],
                    )
                  : null,
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Título de la Obra",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            if (widget.school != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFFF4BD), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                     const Icon(Icons.school, color: JoviTheme.blue),
                     const SizedBox(width: 10),
                     Text("Participando en: ${widget.school} (${widget.classId})", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            else
               Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: const Row(
                  children: [
                     Icon(Icons.public, color: JoviTheme.blue),
                     SizedBox(width: 10),
                     Text("Participando en Concurso Global", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

             const SizedBox(height: 30),

             SizedBox(
               width: double.infinity,
               height: 50,
               child: ElevatedButton(
                 onPressed: _isUploading ? null : _submitEntry,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: JoviTheme.blue,
                   foregroundColor: Colors.white,
                 ),
                 child: _isUploading 
                   ? const CircularProgressIndicator(color: Colors.white)
                   : const Text("ENVIAR A CONCURSO"),
               ),
             )
          ],
        ),
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(context: context, builder: (_) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
          ],
        ),
      );
    });
  }
}
