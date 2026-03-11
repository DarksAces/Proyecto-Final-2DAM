import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
        text: widget.initialData?['displayName'] ??
            widget.initialData?['name'] ??
            '');
    _bioController =
        TextEditingController(text: widget.initialData?['bio'] ?? '');
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
        child: Column(
          children: [
            TextField(
              controller: _nameController,
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
            const Spacer(),
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
    );
  }
}
