import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../services/contest_service.dart';
import 'participation_screen.dart';
import 'ranking_screen.dart';

class ContestScreen extends StatefulWidget {
  const ContestScreen({super.key});

  @override
  State<ContestScreen> createState() => _ContestScreenState();
}

class _ContestScreenState extends State<ContestScreen> {
  final UserService _userService = UserService();
  final ContestService _contestService = ContestService();
  Map<String, dynamic>? _userData;
  String _selectedCategory = "Todo";

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        top: false, // Let SliverAppBar handle the top
        child: CustomScrollView(
        slivers: [
          // Colorful Premium Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF6C63FF), // Modern Purple
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("GALERÍA DE GENIOS", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)
                  ),
                  Text("LAS MEJORES CREACIONES", 
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 6, letterSpacing: 0.5)
                  ),
                ],
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    "https://images.unsplash.com/photo-1541963463532-d68292c34b19?q=80&w=1200&auto=format&fit=crop", // Artistic Library/Art image
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(80),
                          const Color(0xFF6C63FF).withAlpha(180),
                        ],
                      ),
                    ),
                  ),
                  // Decorative shapes
                  Positioned(
                    top: -20, right: -20,
                    child: CircleAvatar(radius: 60, backgroundColor: Colors.white.withAlpha(20)),
                  ),
                ],
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RankingScreen(initialTabIndex: 0)));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(220),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
                        SizedBox(width: 4),
                        Text("RANKING", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Filters/Categories Row (Mock)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 0, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(label: "Todo", isSelected: _selectedCategory == "Todo", color: const Color(0xFF6C63FF), onTap: () => setState(() => _selectedCategory = "Todo")),
                    _FilterChip(label: "Digital", isSelected: _selectedCategory == "Digital", color: Colors.blue, onTap: () => setState(() => _selectedCategory = "Digital")),
                    _FilterChip(label: "Óleo", isSelected: _selectedCategory == "Óleo", color: Colors.amber, onTap: () => setState(() => _selectedCategory = "Óleo")),
                    _FilterChip(label: "Escultura", isSelected: _selectedCategory == "Escultura", color: Colors.teal, onTap: () => setState(() => _selectedCategory = "Escultura")),
                    _FilterChip(label: "IA Art", isSelected: _selectedCategory == "IA Art", color: Colors.purple, onTap: () => setState(() => _selectedCategory = "IA Art")),
                  ],
                ),
              ),
            ),
          ),

          // Main Artwork Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: _ArtworkGridSliver(stream: _contestService.getGlobalArtworks(category: _selectedCategory)),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 130)),
        ],
      ),
     ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ParticipationScreen()));
        },
        label: const Text("CREAR OBRA", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.brush_rounded),
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 8,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isSelected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200),
          boxShadow: isSelected ? [BoxShadow(color: color.withAlpha(80), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}

class _ArtworkGridSliver extends StatelessWidget {
  final Stream<QuerySnapshot> stream;

  const _ArtworkGridSliver({required this.stream});

  void _showArtworkPopup(BuildContext context, String docId, Map<String, dynamic> data) {
    final imageUrl = data['imageUrl'] ?? '';
    final title = data['title'] ?? 'Obra Maestra';
    final artist = data['artistName'] ?? data['userName'] ?? data['username'] ?? data['fullName'] ?? data['displayName'] ?? 'Genio Anónimo';
    final description = data['description'] ?? '';
    final votes = (data['votes'] ?? data['likes'] ?? 0) as int;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ArtworkPopup(
        docId: docId,
        imageUrl: imageUrl,
        title: title,
        artist: artist,
        description: description,
        initialVotes: votes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return SliverToBoxAdapter(child: Center(child: Text('Error: ${snapshot.error}')));
        if (snapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.palette_outlined, size: 80, color: Colors.grey.withAlpha(100)),
                  const SizedBox(height: 16),
                  const Text("¡AÚN NO HAY OBRAS!", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text("Sé el primero en subir tu creación al concurso.", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParticipationScreen())),
                    icon: const Icon(Icons.rocket_launch_rounded),
                    label: const Text("PARTICIPAR AHORA"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
        });

        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.78, // Adjusted for better adaptation
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final imageUrl = data['imageUrl'] ?? 'https://picsum.photos/seed/art_$index/600/800';
              final title = data['title'] ?? 'Obra Maestra';
              final category = data['category'] ?? 'General';
              final votes = data['votes'] ?? data['likes'] ?? 0;
              
              final artist = data['artistName'] ?? data['userName'] ?? data['username'] ?? data['fullName'] ?? data['displayName'] ?? 'Genio Anónimo';

              return GestureDetector(
                onTap: () => _showArtworkPopup(context, doc.id, data),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(imageUrl, fit: BoxFit.cover),
                        // Category Badge
                        Positioned(
                          top: 10, left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(120),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(category.toUpperCase(), 
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                            ),
                          ),
                        ),
                        // Votes Badge
                        Positioned(
                          top: 10, right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withAlpha(200),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_fire_department, color: Colors.white, size: 10),
                                const SizedBox(width: 2),
                                Text('$votes', 
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Info at bottom
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withAlpha(220)],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.person, color: Colors.white.withAlpha(150), size: 10),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 10, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            childCount: docs.length,
          ),
        );
      },
    );
  }
}

// ── Popup de la obra ─────────────────────────────────────────────────────────
class _ArtworkPopup extends StatefulWidget {
  final String docId;
  final String imageUrl;
  final String title;
  final String artist;
  final String description;
  final int initialVotes;

  const _ArtworkPopup({
    required this.docId,
    required this.imageUrl,
    required this.title,
    required this.artist,
    required this.description,
    required this.initialVotes,
  });

  @override
  State<_ArtworkPopup> createState() => _ArtworkPopupState();
}

class _ArtworkPopupState extends State<_ArtworkPopup> {
  late int _votes;
  bool _hasVoted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _votes = widget.initialVotes;
    _checkIfVoted();
  }

  Future<void> _checkIfVoted() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('contest_entries')
        .doc(widget.docId)
        .collection('voters')
        .doc(uid)
        .get();
    if (mounted) setState(() => _hasVoted = doc.exists);
  }

  Future<void> _recommend() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _hasVoted || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final entryRef = FirebaseFirestore.instance
          .collection('contest_entries')
          .doc(widget.docId);

      String? authorId;
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(entryRef);
        final currentVotes = (snap.data()?['votes'] ?? 0) as int;
        authorId = snap.data()?['userId'] as String?;
        tx.update(entryRef, {'votes': currentVotes + 1});
        tx.set(entryRef.collection('voters').doc(uid), {'votedAt': FieldValue.serverTimestamp()});
      });

      // Award +5 points to the artwork author (not to the voter)
      if (authorId != null && authorId != uid) {
        await UserService().addPoints(authorId!, 5);
      }

      if (mounted) {
        setState(() {
          _votes++;
          _hasVoted = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      height: screenH * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
              ),
            ),
  
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: widget.imageUrl.isNotEmpty
                    ? Image.network(
                        widget.imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        loadingBuilder: (ctx, child, prog) =>
                            prog == null ? child : const Center(child: CircularProgressIndicator()),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_outlined, size: 80, color: Colors.grey),
                      ),
              ),
            ),
  
            // Info + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.title,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(widget.artist,
                              style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      // Vote counter chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: Color(0xFF6C63FF), size: 16),
                            const SizedBox(width: 4),
                            Text('$_votes', style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w900, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(widget.description,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Recommend button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _hasVoted || _isLoading ? null : _recommend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasVoted ? Colors.grey.shade300 : const Color(0xFF6C63FF),
                        foregroundColor: _hasVoted ? Colors.grey.shade600 : Colors.white,
                        elevation: _hasVoted ? 0 : 8,
                        shadowColor: const Color(0xFF6C63FF).withAlpha(80),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        disabledBackgroundColor: Colors.grey.shade200,
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_hasVoted ? Icons.check_rounded : Icons.recommend_rounded, size: 22),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _hasVoted ? 'YA RECOMENDASTE ESTA OBRA' : 'RECOMENDAR ESTA OBRA',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
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
