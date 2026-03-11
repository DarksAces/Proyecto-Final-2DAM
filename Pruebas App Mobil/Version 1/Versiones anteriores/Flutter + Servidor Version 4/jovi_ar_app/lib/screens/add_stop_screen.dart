import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:image_picker/image_picker.dart' as ip;
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../api_service.dart';
import '../settings_service.dart';

// ==========================================
// 8. AÑADIR SITIO
// ==========================================

class AddStopScreen extends StatefulWidget {
  final geo.Position currentPosition;
  const AddStopScreen({super.key, required this.currentPosition});
  @override State<AddStopScreen> createState() => _AddStopScreenState();
}

class _AddStopScreenState extends State<AddStopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _typeController = TextEditingController();
  File? _imageFile;
  bool _isUploading = false;
  final apiService = ApiService();
  final SettingsService _settingsService = SettingsService();

  Future<void> _pickImage() async {
    final picker = ip.ImagePicker();
    final pickedFile = await picker.pickImage(source: ip.ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate() || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falta foto o datos.')));
      return;
    }

    setState(() => _isUploading = true);
    
    final currentUser = FirebaseAuth.instance.currentUser;
    final authorId = currentUser?.uid ?? 'anonimo_offline'; 

    final newStop = NewStopData(
      title: _titleController.text,
      author: currentUser?.displayName ?? "Anónimo",
      type: _typeController.text,
      lat: widget.currentPosition.latitude,
      lng: widget.currentPosition.longitude,
      imageFile: _imageFile!,
      authorId: authorId,
    );
    
    final success = await apiService.uploadNewStop(newStop);
    setState(() => _isUploading = false);

    if (mounted && success) {
       Navigator.pop(context);
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Sitio subido.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Sitio'), backgroundColor: JoviTheme.yellow),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Título'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _typeController, decoration: const InputDecoration(labelText: 'Categoría'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 20),
              ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.camera), label: Text(_imageFile == null ? 'Foto' : 'Foto OK')),
              if (_imageFile != null) Image.file(_imageFile!, height: 150),
              const SizedBox(height: 20),
              _isUploading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _submitData, child: const Text("SUBIR"))
            ],
          ),
        ),
      ),
    );
  }
}
