import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/user_service.dart';

class NicknameBioScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const NicknameBioScreen({super.key, this.initialData});

  @override
  State<NicknameBioScreen> createState() => _NicknameBioScreenState();
}

class _NicknameBioScreenState extends State<NicknameBioScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  final UserService _userService = UserService();
  bool _isSaving = false;
  File? _imageFile;
  String? _photoUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
        text: widget.initialData?['displayName'] ??
            widget.initialData?['name'] ??
            '');
    _bioController =
        TextEditingController(text: widget.initialData?['bio'] ?? '');
    _photoUrl = widget.initialData?['photoUrl'];
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 400,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    final String? uid = _userService.currentUserId;
    if (uid != null) {
      // Upload image if selected
      if (_imageFile != null) {
        await _userService.uploadProfileImage(_imageFile!);
      }

      final bool success = await _userService.updateUserData(uid, {
        'displayName': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
      });
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado con éxito')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al actualizar el perfil')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nickname y Bio"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_photoUrl != null
                                ? NetworkImage(_photoUrl!)
                                : null) as ImageProvider?,
                        child: _imageFile == null && _photoUrl == null
                            ? const Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: "Nickname / Nombre",
                hintText: "Tu nombre público",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Bio",
                hintText: "Escribe algo sobre ti...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text("GUARDAR CAMBIOS"),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
