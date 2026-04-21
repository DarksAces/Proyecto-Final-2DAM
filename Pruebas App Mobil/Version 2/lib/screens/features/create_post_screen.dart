import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final UserService _userService = UserService();
  bool _isLoading = false;
  Map<String, dynamic>? _userData;

  // Attachments state
  String? _selectedImage;
  String? _selectedVideo;
  String? _selectedLocation;
  String? _selectedWorkId; // ID of the selected "User Work"

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await _userService.getCurrentUserData();
    if (mounted) {
      setState(() {
        _userData = data;
      });
    }
  }

  // Simulated Media Pickers
  void _pickImage() {
    setState(() {
      // Toggle a random image
      _selectedImage = _selectedImage == null
          ? 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/600/400'
          : null;
    });
  }

  void _pickVideo() {
    setState(() {
      _selectedVideo = _selectedVideo == null ? 'assets/videos/demo.mp4' : null;
    });
    if (_selectedVideo != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video adjuntado (Simulado)')));
    }
  }

  void _pickLocation() {
    setState(() {
      _selectedLocation =
          _selectedLocation == null ? 'Plaza Mayor, Madrid' : null;
    });
  }

  void _selectWork(String postId, String imageUrl) {
    setState(() {
      if (_selectedWorkId == postId) {
        _selectedWorkId = null; // Deselect
        // Optional: Remove image if it was the work's image
        if (_selectedImage == imageUrl) _selectedImage = null;
      } else {
        _selectedWorkId = postId;
        _selectedImage = imageUrl; // Auto-attach work image
      }
    });
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedImage == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('sitios').add({
        'userId': user.uid,
        'username': _userData?['displayName'] ?? 'Usuario',
<<<<<<< HEAD
=======
        'userTitle': 'Creator',
        'userAvatarColor': 0xFFE30613,
>>>>>>> 08759375c10047997d9cde5eccddac3892898c94
        'content': content,
        'imageUrl': _selectedImage, // Use selected or work image
        'videoUrl': _selectedVideo,
        'location': _selectedLocation ?? 'Madrid, Spain',
        'latitude': 40.4168,
        'longitude': -3.7038,
        'status': 'pending_review',
<<<<<<< HEAD
        'referenceWorkId': _selectedWorkId,
=======
        'badge': _selectedWorkId != null ? 'WORK UPDATE' : 'NEW',
        'referenceWorkId': _selectedWorkId,
        'likes': 0,
        'comments': 0,
        'shares': 0,
>>>>>>> 08759375c10047997d9cde5eccddac3892898c94
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Publicado con éxito! 🎉'),
            backgroundColor: AppTheme.arteRed,
          ),
        );
      }
    } catch (e) {
      print('Error publishing post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al publicar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Crear publicación',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.arteRed,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Publicar'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User + Input
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            AppTheme.arteRed.withValues(alpha: 0.1),
                        backgroundImage: _userData?['avatarUrl'] != null
                            ? NetworkImage(_userData!['avatarUrl'])
                            : null,
                        child: _userData?['avatarUrl'] == null
                            ? const Icon(Icons.person, color: AppTheme.arteRed)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _contentController,
                          autofocus: true,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: '¿Qué estás creando hoy?',
                            border: InputBorder.none,
                            hintStyle:
                                TextStyle(color: Colors.grey, fontSize: 18),
                          ),
                          style: const TextStyle(
                              fontSize: 18, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Attachments Display
                  if (_selectedImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _selectedImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            onPressed: () => setState(() {
                              _selectedImage = null;
                              _selectedWorkId = null;
                            }),
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                                backgroundColor: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  if (_selectedLocation != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Chip(
                        avatar: const Icon(Icons.location_on,
                            size: 16, color: AppTheme.arteRed),
                        label: Text(_selectedLocation!),
                        onDeleted: () =>
                            setState(() => _selectedLocation = null),
                        deleteIconColor: Colors.grey,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // My Works Slider
                  const Text(
                    "Mis Obras Recientes",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _userService.getUserPosts(user?.uid ?? ''),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return Center(
                            child: Text(
                              "No tienes obras aún",
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                          );
                        }
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;
                            final imageUrl = data['imageUrl'];
                            final isSelected =
                                _selectedWorkId == docs[index].id;

                            if (imageUrl == null)
                              return const SizedBox.shrink();

                            return GestureDetector(
                              onTap: () =>
                                  _selectWork(docs[index].id, imageUrl),
                              child: Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? Border.all(
                                          color: AppTheme.arteRed, width: 3)
                                      : null,
                                  image: DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: isSelected
                                    ? Container(
                                        decoration: BoxDecoration(
                                          color: AppTheme.arteRed
                                              .withValues(alpha: 0.3),
                                          borderRadius:
                                              BorderRadius.circular(9),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.check,
                                              color: Colors.white, size: 32),
                                        ),
                                      )
                                    : null,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          // Bottom Actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon:
                      _selectedImage != null ? Icons.photo : Icons.photo_camera,
                  color: AppTheme.arteRed,
                  onTap: _pickImage,
                  isActive: _selectedImage != null,
                ),
                _ActionButton(
                  icon: Icons.videocam,
                  color: AppTheme.arteBlue,
                  onTap: _pickVideo,
                  isActive: _selectedVideo != null,
                ),
                _ActionButton(
                  icon: Icons.event,
                  color: AppTheme.arteYellow,
                  onTap: () {},
                ),
                _ActionButton(
                  icon: Icons.location_on,
                  color: _selectedLocation != null
                      ? Colors.green
                      : Colors.grey.shade600,
                  onTap: _pickLocation,
                  isActive: _selectedLocation != null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isActive
          ? BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            )
          : null,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
