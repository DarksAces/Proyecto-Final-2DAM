import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
  File? _imageFile;
  File? _videoFile;
  String? _selectedImage; // URL after upload (if needed) or simulation
  String? _selectedVideo;
  String? _selectedLocation;
  String? _selectedWorkId; // ID of the selected "User Work"
  DateTime? _eventDate;
  
  final ImagePicker _picker = ImagePicker();

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

  // Media Pickers
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Cámara'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  setState(() {
                    _imageFile = File(image.path);
                    _selectedImage = image.path; // Local path for preview
                    _selectedWorkId = null;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() {
                    _imageFile = File(image.path);
                    _selectedImage = image.path; // Local path for preview
                    _selectedWorkId = null;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickVideo() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Grabar Video'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
                if (video != null) {
                  setState(() {
                    _videoFile = File(video.path);
                    _selectedVideo = video.path;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Galería de Videos'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
                if (video != null) {
                  setState(() {
                    _videoFile = File(video.path);
                    _selectedVideo = video.path;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pickLocation() {
    final TextEditingController locationController = TextEditingController(text: _selectedLocation);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Dónde estás?'),
        content: TextField(
          controller: locationController,
          decoration: const InputDecoration(hintText: 'Ej: Puerta del Sol, Madrid'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedLocation = locationController.text.isNotEmpty ? locationController.text : null;
              });
              Navigator.pop(context);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickEvent() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _eventDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
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
    if (content.isEmpty && _selectedImage == null && _selectedVideo == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      String? finalImageUrl = _selectedImage;
      String? finalVideoUrl = _selectedVideo;

      // 1. Upload Image if local file exists
      if (_imageFile != null) {
        final String fileName = 'post_img_${DateTime.now().millisecondsSinceEpoch}.jpg';
        finalImageUrl = await _userService.uploadFile(_imageFile!, 'post_images', fileName);
      }

      // 2. Upload Video if local file exists
      if (_videoFile != null) {
        final String fileName = 'post_vid_${DateTime.now().millisecondsSinceEpoch}.mp4';
        finalVideoUrl = await _userService.uploadFile(_videoFile!, 'post_videos', fileName);
      }

      // 3. Create Firestore Document
      await FirebaseFirestore.instance.collection('sitios').add({
        'userId': user.uid,
        'username': _userData?['displayName'] ?? 'Usuario',
        'userTitle': 'Creator',
        'userAvatarColor': 0xFFE30613,
        'content': content,
        'imageUrl': finalImageUrl,
        'videoUrl': finalVideoUrl,
        'location': _selectedLocation,
        'eventDate': _eventDate != null ? Timestamp.fromDate(_eventDate!) : null,
        'latitude': 40.4168,
        'longitude': -3.7038,
        'status': 'published', // Direct publish for now
        'badge': _selectedWorkId != null ? 'OBRA AR' : (_eventDate != null ? 'EVENTO' : 'NUEVO'),
        'referenceWorkId': _selectedWorkId,
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Award +10 points for creating a post
      await _userService.addPoints(user.uid, 10);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Publicado con éxito! 🎉'),
            backgroundColor: AppTheme.arteRed,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error publishing post: $e');
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
      body: SafeArea(
        child: Column(
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
                          child: _imageFile != null
                              ? Image.file(
                                  _imageFile!,
                                  height: 250,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  _selectedImage!,
                                  height: 250,
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
                              _imageFile = null;
                              _selectedWorkId = null;
                            }),
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                                backgroundColor: Colors.black54),
                          ),
                        ),
                      ],
                    ),

                  if (_selectedVideo != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.arteBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.videocam, color: AppTheme.arteBlue),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Video adjuntado')),
                          IconButton(
                            onPressed: () => setState(() {
                              _selectedVideo = null;
                              _videoFile = null;
                            }),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),

                  if (_selectedLocation != null || _eventDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          if (_selectedLocation != null)
                            Chip(
                              avatar: const Icon(Icons.location_on,
                                  size: 16, color: Colors.green),
                              label: Text(_selectedLocation!),
                              onDeleted: () =>
                                  setState(() => _selectedLocation = null),
                              deleteIconColor: Colors.grey,
                            ),
                          if (_eventDate != null)
                            Chip(
                              avatar: const Icon(Icons.event,
                                  size: 16, color: AppTheme.arteYellow),
                              label: Text(DateFormat('dd/MM HH:mm').format(_eventDate!)),
                              onDeleted: () =>
                                  setState(() => _eventDate = null),
                              deleteIconColor: Colors.grey,
                            ),
                        ],
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
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _userService.getUserContent(user?.uid ?? ''),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppTheme.arteRed));
                        }
                        if (snapshot.hasError) {
                          return const Center(child: Text('Error al cargar obras'));
                        }
                        
                        final works = snapshot.data ?? [];
                        if (works.isEmpty) {
                          return Center(
                            child: Text(
                              "No tienes obras aún",
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                          );
                        }
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: works.length,
                          itemBuilder: (context, index) {
                            final work = works[index];
                            final imageUrl = work['imageUrl'];
                            final postId = work['id'];
                            final isSelected = _selectedWorkId == postId;

                            if (imageUrl == null) return const SizedBox.shrink();

                            return GestureDetector(
                              onTap: () => _selectWork(postId, imageUrl),
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
                  color: _eventDate != null ? AppTheme.arteYellow : Colors.grey.shade600,
                  onTap: _pickEvent,
                  isActive: _eventDate != null,
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
