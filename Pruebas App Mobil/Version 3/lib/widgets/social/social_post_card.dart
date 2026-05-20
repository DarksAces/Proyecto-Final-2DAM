import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart'; // provides SharePlus.instance, ShareParams
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../screens/features/profile_screen.dart';

class SocialPostCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String postId;

  const SocialPostCard({
    super.key,
    required this.data,
    required this.postId,
  });

  @override
  State<SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<SocialPostCard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  bool _isLiked = false;
  bool _isFollowing = false;
  int _likeCount = 0;
  final ChatService _chatService = ChatService();
  String? _authorPhotoUrl;
  String? _authorTitle;

  @override
  void initState() {
    super.initState();
    _likeCount = ((widget.data['likes'] ?? widget.data['likesCount'] ?? 0) as num).toInt();
    if (_likeCount < 0) _likeCount = 0; // clamp, never show negatives
    _checkIfLiked();
    _checkIfFollowing();
  }

  void _checkIfFollowing() async {
    final user = _auth.currentUser;
    final postUserId = widget.data['userId'];
    if (user == null || postUserId == null) return;
    
    // Fetch author data for real-time photo and title
    final authorData = await _userService.getUserData(postUserId);
    if (mounted) {
      setState(() {
        _authorPhotoUrl = authorData?['photoUrl'];
        _authorTitle = authorData?['userTitle'];
      });
    }

    if (user.uid == postUserId) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('following')
        .doc(postUserId)
        .get();

    if (mounted) {
      setState(() {
        _isFollowing = doc.exists;
      });
    }
  }

  void _toggleFollow() async {
    final postUserId = widget.data['userId'];
    if (postUserId == null) return;
    
    setState(() => _isFollowing = !_isFollowing);
    if (_isFollowing) {
      await _userService.followUser(postUserId);
    } else {
      await _userService.unfollowUser(postUserId);
    }
  }

  void _checkIfLiked() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('sitios')
        .doc(widget.postId)
        .collection('likes')
        .doc(user.uid)
        .get();

    if (mounted) {
      setState(() {
        _isLiked = doc.exists;
      });
    }
  }

  void _toggleLike() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final postRef = FirebaseFirestore.instance.collection('sitios').doc(widget.postId);
    final likeRef = postRef.collection('likes').doc(user.uid);

    if (_isLiked) {
      // Unlike / Quitar recomendación
      setState(() {
        _isLiked = false;
        _likeCount--;
        if (_likeCount < 0) _likeCount = 0;
      });

      await likeRef.delete();
      await postRef.update({'likes': FieldValue.increment(-1), 'likesCount': FieldValue.increment(-1)});

      // Remove the +3 points from the post author
      final authorId = widget.data['userId'] as String?;
      if (authorId != null && authorId != user.uid) {
        await _userService.addPoints(authorId, -3);
      }
    } else {
      // Like / Añadir recomendación
      setState(() {
        _isLiked = true;
        _likeCount++;
      });

      await likeRef.set({'timestamp': FieldValue.serverTimestamp()});
      await postRef.update({'likes': FieldValue.increment(1), 'likesCount': FieldValue.increment(1)});

      // Award +3 points to the post author (not to the liker)
      final authorId = widget.data['userId'] as String?;
      if (authorId != null && authorId != user.uid) {
        await _userService.addPoints(authorId, 3);
      }
    }
  }

  void _sharePost() {
    final String title = widget.data['title'] ?? 'Obra AR';
    final String username = widget.data['username'] ?? 'Artista';
    final String description = widget.data['description'] ?? widget.data['content'] ?? '';
    final String? imageUrl = widget.data['imageUrl'];

    final StringBuffer shareText = StringBuffer();
    shareText.writeln('🎨 "$title" por $username en ARte');
    if (description.isNotEmpty) {
      shareText.writeln();
      shareText.writeln(description);
    }
    shareText.writeln();
    shareText.writeln('Descubre arte en realidad aumentada con la app ARte 🌐✨');
    if (imageUrl != null) {
      shareText.writeln(imageUrl);
    }

    SharePlus.instance.share(
      ShareParams(
        text: shareText.toString().trim(),
        subject: 'Mira esta obra AR: $title',
      ),
    );
  }

  void _shareToChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  const Text("Enviar publicación", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _chatService.getUserChats(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final chats = snapshot.data!.docs;
                        if (chats.isEmpty) return const Center(child: Text("No hay chats activos"));
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: chats.length,
                          itemBuilder: (context, index) {
                            final chat = chats[index];
                            final data = chat.data() as Map<String, dynamic>;
                            final currentUserId = _auth.currentUser?.uid ?? '';
                            final participants = List<String>.from(data['participants'] ?? []);
                            final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
                            final names = data['participantNames'] as Map<String, dynamic>?;
                            final name = names?[otherUserId] ?? "Usuario";
                            final avatars = data['participantAvatars'] as Map<String, dynamic>?;
                            final avatarUrl = avatars?[otherUserId];

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFF0F0FF),
                                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                child: avatarUrl == null ? Text(name[0], style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)) : null,
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: TextButton(
                                onPressed: () async {
                                  await _chatService.sendMessage(chat.id, '', postId: widget.postId, postImageUrl: widget.data['imageUrl'], postTitle: widget.data['title'] ?? 'Obra AR');
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enviado correctamente")));
                                  }
                                },
                                child: const Text("ENVIAR", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF6C63FF))),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return "Hace un momento";
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return "Hace un momento";
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } else if (difference.inDays >= 1) {
      return "Hace ${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}";
    } else if (difference.inHours >= 1) {
      return "Hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}";
    } else if (difference.inMinutes >= 1) {
      return "Hace ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}";
    } else if (difference.inSeconds >= 5) {
      return "Hace ${difference.inSeconds} segundos";
    } else {
      return "Ahora mismo";
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.arteRed),
                title: const Text("Eliminar publicación", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.arteRed)),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost();
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text("Cancelar"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar publicación?"),
        content: const Text("Esta acción no se puede deshacer y el post desaparecerá del mapa y del feed."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("ELIMINAR", style: TextStyle(color: AppTheme.arteRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('sitios').doc(widget.postId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Publicación eliminada correctamente")));
      }
    }
  }

  void _navigateToProfile() {
    final postUserId = widget.data['userId'];
    if (postUserId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(userId: postUserId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String username = widget.data['username'] ?? 'Artista';
    final String? imageUrl = widget.data['imageUrl'];
    final String title = widget.data['title'] ?? '';
    final String description = widget.data['description'] ?? widget.data['content'] ?? '';
    final String userTitle = widget.data['userTitle'] ?? 'Creador AR';
    final String degree = widget.data['userDegree'] ?? '• 1º';

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header (LinkedIn style)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _navigateToProfile,
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.arteGreen.withOpacity(0.1),
                    backgroundImage: _authorPhotoUrl != null ? NetworkImage(_authorPhotoUrl!) : null,
                    child: _authorPhotoUrl == null 
                      ? Text(username[0].toUpperCase(), style: const TextStyle(color: AppTheme.arteGreen, fontWeight: FontWeight.bold, fontSize: 18))
                      : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _navigateToProfile,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(username, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(degree, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                        Text(_authorTitle ?? userTitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text("${_getTimeAgo(widget.data['timestamp'])} • 🌎", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                if (widget.data['userId'] != _auth.currentUser?.uid)
                  TextButton(
                    onPressed: _toggleFollow,
                    child: Text(_isFollowing ? "SIGUIENDO" : "+ SEGUIR", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppTheme.arteGreen)),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                    onPressed: () => _showOptions(context),
                  ),
              ],
            ),
          ),

          // Title & Description
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Text(description, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.3)),
            ),

          // Image Content
          if (imageUrl != null)
            Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(height: 300, color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator()));
              },
            ),

          // Engagement Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: AppTheme.arteGreen, size: 14),
                const SizedBox(width: 4),
                Text("$_likeCount recomendaciones", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 0.5),

          // Action Bar — Recommend, Share & Send
          Row(
            children: [
              _ActionBarItem(
                icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                label: "Recomendar",
                active: _isLiked,
                onTap: _toggleLike,
              ),
              _ActionBarItem(
                icon: Icons.share_rounded,
                label: "Compartir",
                onTap: _sharePost,
              ),
              _ActionBarItem(
                icon: Icons.ios_share_rounded,
                label: "Enviar",
                onTap: _shareToChat,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ActionBarItem({required this.icon, required this.label, this.active = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: active ? AppTheme.arteGreen : Colors.grey.shade700, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: active ? AppTheme.arteGreen : Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
