import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../services/contest_service.dart';

class ParticipationScreen extends StatefulWidget {
  const ParticipationScreen({super.key});

  @override
  State<ParticipationScreen> createState() => _ParticipationScreenState();
}

class _ParticipationScreenState extends State<ParticipationScreen> {
  String _selectedScope = 'Global'; // 'Global' or 'Mi Colegio'
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _submitEntry() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Por favor completa el título y la descripción")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = await UserService().getCurrentUser();
      // Use a placeholder image or select random
      const imageUrl =
          "https://images.unsplash.com/photo-1549887552-93f954d716d7?q=80&w=1035&auto=format&fit=crop";

      final entry = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'imageUrl': imageUrl,
        'artistName': user?.name ?? "Artista Anónimo",
        'userId': user?.id ?? "anon_user", // Fallback if no user
        'schoolId': user?.schoolId, // Can be null if generic
        'scope': _selectedScope,
        'likes': 0,
      };

      await ContestService().addContestEntry(entry);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Obra enviada con éxito!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al enviar: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Participar en Concurso",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black),
            onPressed: () {
              // Show info dialog
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Image with Timer
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: NetworkImage(
                      "https://images.unsplash.com/photo-1549887552-93f954d716d7?q=80&w=1035&auto=format&fit=crop"), // Placeholder lynx/cat
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      // Removed gradient as text is gone
                    ),
                  ),
                  // Removed Positioned with Text and Timer
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "ZONA DE CARGA",
              style: TextStyle(
                  color: AppTheme.auraRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2),
            ),
            const SizedBox(height: 10),

            // Upload Zone
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.auraRed.withValues(alpha: 0.3),
                    width: 2,
                    style: BorderStyle
                        .solid), // Should be dashed but solid for simplicity
                color: Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: AppTheme.auraRed.withValues(alpha: 0.1),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.cloud_upload_outlined,
                          color: AppTheme.auraRed, size: 32)),
                  const SizedBox(height: 16),
                  const Text("Sube tu creación",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text("Formatos: JPG, PNG o Video AR",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _UploadButton(
                        icon: Icons.photo_library_outlined,
                        label: "Galería",
                        color: AppTheme.auraRed.withValues(alpha: 0.1),
                        textColor: AppTheme.auraRed,
                        onTap: () {},
                      ),
                      const SizedBox(width: 16),
                      _UploadButton(
                        icon: Icons.camera_alt_outlined,
                        label: "Cámara AR",
                        color: AppTheme.auraRed,
                        textColor: Colors.white,
                        onTap: () {},
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Form Fields
            const Text("Título de tu obra",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: "Ponle un nombre a tu arte...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 20),

            const Text("Descripción creativa",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Cuéntanos la historia detrás de tu obra...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 20),

            // Scope Selector
            const Text("Ubicación del Concurso",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedScope = 'Global'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedScope == 'Global'
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedScope == 'Global'
                              ? [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4)
                                ]
                              : [],
                        ),
                        child: Text(
                          "Global",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedScope == 'Global'
                                ? AppTheme.auraRed
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedScope = 'Mi Colegio'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedScope == 'Mi Colegio'
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedScope == 'Mi Colegio'
                              ? [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4)
                                ]
                              : [],
                        ),
                        child: Text(
                          "Mi Colegio",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedScope == 'Mi Colegio'
                                ? AppTheme.auraRed
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.auraRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  shadowColor: AppTheme.auraRed.withValues(alpha: 0.4),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "ENVIAR MI OBRA",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.send_rounded,
                              color: Colors.white, size: 20)
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _UploadButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
