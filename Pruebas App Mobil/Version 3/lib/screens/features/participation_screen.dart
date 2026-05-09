import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../services/contest_service.dart';

class ParticipationScreen extends StatefulWidget {
  const ParticipationScreen({super.key});

  @override
  State<ParticipationScreen> createState() => _ParticipationScreenState();
}

class _ParticipationScreenState extends State<ParticipationScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ContestService _contestService = ContestService();
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();
  
  File? _imageFile;
  String? _selectedExternalImageUrl;
  String _selectedCategory = 'Digital';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Digital', 'icon': Icons.computer, 'color': Colors.blue},
    {'name': 'Óleo', 'icon': Icons.palette, 'color': Colors.amber},
    {'name': 'Escultura', 'icon': Icons.format_paint, 'color': Colors.teal},
    {'name': 'IA Art', 'icon': Icons.auto_awesome, 'color': Colors.purple},
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _selectedExternalImageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al seleccionar imagen: $e")),
        );
      }
    }
  }

  Future<void> _selectFromMyArtworks() async {
    final userId = _userService.currentUserId;
    if (userId == null) return;

    setState(() => _isSubmitting = true);
    final artworks = await _userService.getUserContent(userId);
    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (artworks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aún no tienes obras en tu galería")),
      );
      return;
    }

    final Map<String, dynamic>? selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("MIS OBRAS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: artworks.length,
                itemBuilder: (context, index) {
                  final item = artworks[index];
                  final url = item['imageUrl'] ?? "";
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, item),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withAlpha(150), Colors.transparent],
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        alignment: Alignment.bottomLeft,
                        child: Text(item['title'] ?? item['content'] ?? "Sin título", 
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedExternalImageUrl = selected['imageUrl'];
        _imageFile = null;
        if (_titleController.text.isEmpty) {
          _titleController.text = selected['title'] ?? selected['content'] ?? "";
        }
      });
    }
  }

  Future<void> _submitEntry() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor completa el título y la descripción")),
      );
      return;
    }

    if (_imageFile == null && _selectedExternalImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor selecciona o captura una imagen de tu obra")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = await UserService().getCurrentUser();
      
      String imageUrl;
      if (_imageFile != null) {
        imageUrl = await _contestService.uploadContestImage(_imageFile!);
      } else {
        imageUrl = _selectedExternalImageUrl!;
      }

      final entry = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'imageUrl': imageUrl,
        'artistName': user?.name ?? "Artista Anónimo",
        'userId': user?.id ?? "anon_user",
        'scope': 'Global',
        'likes': 0,
      };

      await _contestService.addContestEntry(entry);

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
      backgroundColor: const Color(0xFFF8F9FE),
      body: CustomScrollView(
        slivers: [
          // Premium Header
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF6C63FF),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withAlpha(200),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("SUBIR CREACIÓN", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    "https://images.unsplash.com/photo-1547891319-1842047e098d?q=80&w=1200&auto=format&fit=crop",
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(100),
                          const Color(0xFF6C63FF).withAlpha(150),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step Items
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StepItem(icon: Icons.lightbulb_outline, label: "Idea", color: Colors.amber),
                      _StepItem(icon: Icons.view_in_ar_rounded, label: "Crea", color: Colors.blue),
                      _StepItem(icon: Icons.cloud_upload_outlined, label: "Sube", color: const Color(0xFF6C63FF)),
                      _StepItem(icon: Icons.emoji_events_outlined, label: "Gana", color: Colors.orange),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Upload Zone / Preview
                  const Text("TU OBRA", 
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5)
                  ),
                  const SizedBox(height: 16),
                  
                  GestureDetector(
                    onTap: () => _showImageSourceActionSheet(context),
                    child: Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.grey.shade200, width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                        image: _imageFile != null 
                            ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) 
                            : (_selectedExternalImageUrl != null 
                                ? DecorationImage(image: NetworkImage(_selectedExternalImageUrl!), fit: BoxFit.cover) 
                                : null),
                      ),
                      child: (_imageFile == null && _selectedExternalImageUrl == null)
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C63FF).withAlpha(20),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_a_photo_rounded, color: Color(0xFF6C63FF), size: 40),
                              ),
                              const SizedBox(height: 16),
                              const Text("Toca para añadir tu obra", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              const Text("Galería, Cámara o Mis Obras", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          )
                        : Stack(
                            children: [
                              Positioned(
                                bottom: 12, right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Category Selector
                  const Text("CATEGORÍA", 
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat['name'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat['name']),
                          child: Container(
                            width: 90,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? cat['color'] : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: isSelected ? [BoxShadow(color: (cat['color'] as Color).withAlpha(60), blurRadius: 10, offset: const Offset(0, 4))] : [],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(cat['icon'], color: isSelected ? Colors.white : cat['color'], size: 24),
                                const SizedBox(height: 6),
                                Text(cat['name'], style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 11)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Form Section
                  const Text("DETALLES", 
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _titleController,
                    label: "Título",
                    hint: "¿Cómo se llama tu creación?",
                    icon: Icons.title_rounded,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _descriptionController,
                    label: "Descripción",
                    hint: "Cuéntanos la historia de tu obra...",
                    icon: Icons.notes_rounded,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 40),

                  // Submit Button
                  SizedBox(
                    height: 65,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        elevation: 12,
                        shadowColor: const Color(0xFF6C63FF).withAlpha(100),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("CONFIRMAR Y SUBIR", 
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)
                              ),
                              SizedBox(width: 12),
                              Icon(Icons.rocket_launch_rounded),
                            ],
                          ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.auto_awesome_motion_rounded, color: Color(0xFF6C63FF)),
              title: const Text('Mis Obras (Galería App)', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _selectFromMyArtworks();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF6C63FF)),
              title: const Text('Cámara', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF6C63FF)),
              title: const Text('Galería del Móvil', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 22),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StepItem({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
