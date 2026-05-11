import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ar_model_viewer_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _selectedType = "Todo"; // "Todo", "Imágenes", "3D"
  bool _sortByDateDesc = true;
  List<Map<String, dynamic>> _contentList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      final content = await _userService.getUserContent(userId);
      if (mounted) {
        setState(() {
          _contentList = content;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _deleteItem(String docId, String contentType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Obra"),
        content: const Text("¿Estás seguro de que quieres eliminar esta creación de tu galería?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Sí, eliminar")),
        ],
      ),
    );

    if (confirm == true) {
      final collection = contentType == 'ar_object' ? 'ar_objects' : 'sitios';
      await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Obra eliminada")));
        _loadContent();
      }
    }
  }

  List<Map<String, dynamic>> get _filteredAndSortedContent {
    List<Map<String, dynamic>> filtered = _contentList.where((item) {
      if (_selectedType == "Imágenes") return item['contentType'] == 'site';
      if (_selectedType == "3D") return item['contentType'] == 'ar_object';
      return true;
    }).toList();

    filtered.sort((a, b) {
      final Timestamp? tA = a['timestamp'] ?? a['createdAt'];
      final Timestamp? tB = b['timestamp'] ?? b['createdAt'];
      if (tA == null && tB == null) return 0;
      if (tA == null) return 1;
      if (tB == null) return -1;
      return _sortByDateDesc ? tB.compareTo(tA) : tA.compareTo(tB);
    });

    return filtered;
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.arteRed : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
          boxShadow: isSelected 
            ? [BoxShadow(color: AppTheme.arteRed.withAlpha(80), blurRadius: 8, offset: const Offset(0, 4))] 
            : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: const BackButton(),
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text("Mi Galería", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip("Todo", _selectedType == "Todo", () => setState(() => _selectedType = "Todo")),
                const SizedBox(width: 10),
                _buildFilterChip("Imágenes", _selectedType == "Imágenes", () => setState(() => _selectedType = "Imágenes")),
                const SizedBox(width: 10),
                _buildFilterChip("3D", _selectedType == "3D", () => setState(() => _selectedType = "3D")),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => setState(() => _sortByDateDesc = !_sortByDateDesc),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Text("Fecha", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(width: 4),
                        Icon(_sortByDateDesc ? Icons.arrow_downward : Icons.arrow_upward, size: 16, color: Colors.grey.shade700)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Mis Creaciones", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              ],
            ),
          ),

          // Dynamic Grid from Firestore
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.arteRed))
                : RefreshIndicator(
                    color: AppTheme.arteRed,
                    onRefresh: _loadContent,
                    child: _filteredAndSortedContent.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20)]),
                                      child: Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey.shade400)
                                    ),
                                    const SizedBox(height: 20),
                                    const Text("Galería vacía", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    const SizedBox(height: 8),
                                    const Text("Aún no tienes creaciones de este tipo.", style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              int columns = 2;
                              if (constraints.maxWidth > 600) columns = 3;
                              if (constraints.maxWidth > 900) columns = 4;
                              
                              return GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.75,
                                ),
                                itemCount: _filteredAndSortedContent.length,
                                itemBuilder: (context, index) {
                                  final data = _filteredAndSortedContent[index];
                                  final docId = data['id'];
                                  final contentType = data['contentType'];
                                  return _GalleryCard(
                                    title: data['content'] ?? data['title'] ?? data['name'] ?? "Sin título",
                                    imageUrl: data['imageUrl'] ?? "https://picsum.photos/seed/$docId/600/600",
                                    docId: docId,
                                    contentType: contentType,
                                    modelUrl: data['url'],
                                    onDelete: () => _deleteItem(docId, contentType),
                                  );
                                },
                              );
                            }
                          ),
                  ),
          ),


        ],
      ),
     ),
    );
  }
}

class _GalleryCard extends StatefulWidget {
  final String title;
  final String imageUrl;
  final String docId;
  final String contentType;
  final String? modelUrl;
  final VoidCallback onDelete;

  const _GalleryCard({
    required this.title,
    required this.imageUrl,
    required this.docId,
    required this.contentType,
    this.modelUrl,
    required this.onDelete,
  });

  @override
  State<_GalleryCard> createState() => _GalleryCardState();
}

class _GalleryCardState extends State<_GalleryCard> {
  bool _showOverlay = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showOverlay = !_showOverlay),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))
          ],
          image: DecorationImage(image: NetworkImage(widget.imageUrl), fit: BoxFit.cover),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Bottom Gradient for text readability
              Positioned(
                bottom: 0, left: 0, right: 0, height: 80,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withAlpha(200), Colors.transparent]
                    )
                  ),
                ),
              ),
              
              // Badge based on contentType
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(150),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.contentType == 'ar_object' ? Icons.view_in_ar : Icons.image, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(widget.contentType == 'ar_object' ? '3D' : 'IMG', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                ),
              ),
              
              // Glassmorphism Overlay
              if (_showOverlay)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.black.withAlpha(80),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.contentType == 'ar_object' && widget.modelUrl != null) ...[
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ArModelViewerScreen(
                                        modelUrl: widget.modelUrl,
                                        title: widget.title,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(color: AppTheme.arteYellow, shape: BoxShape.circle),
                                  child: const Icon(Icons.view_in_ar, color: Colors.black87, size: 28),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text("Ver en AR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 20),
                            ],
                            GestureDetector(
                              onTap: widget.onDelete,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.delete_outline, color: AppTheme.arteRed, size: 28),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text("Eliminar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
