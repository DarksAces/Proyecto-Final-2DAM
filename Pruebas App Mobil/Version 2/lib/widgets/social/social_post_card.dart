import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart';

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
  bool _isLiked = false;
  int _likeCount = 0;
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _likeCount = widget.data['likes'] ?? 0;
    _checkIfLiked();
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

    final postRef =
        FirebaseFirestore.instance.collection('sitios').doc(widget.postId);
    final likeRef = postRef.collection('likes').doc(user.uid);

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    if (_isLiked) {
      await likeRef.set({'timestamp': FieldValue.serverTimestamp()});
      await postRef.update({'likes': FieldValue.increment(1)});
    } else {
      await likeRef.delete();
      await postRef.update({'likes': FieldValue.increment(-1)});
    }
  }

  void _shareToChat() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enviar a...",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.getUserChats(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text("No tienes chats activos"));
                    }

                    final chats = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final data = chat.data() as Map<String, dynamic>;

                        // Get name (simplified)
                        final currentUserId = _auth.currentUser?.uid ?? '';
                        final participants =
                            List<String>.from(data['participants'] ?? []);
                        final otherUserId = participants.firstWhere(
                            (id) => id != currentUserId,
                            orElse: () => '');
                        final names =
                            data['participantNames'] as Map<String, dynamic>?;
                        final name = names?[otherUserId] ?? "Usuario";
                        final avatars =
                            data['participantAvatars'] as Map<String, dynamic>?;
                        final avatarUrl = avatars?[otherUserId];

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null ? Text(name[0]) : null,
                          ),
                          title: Text(name),
                          trailing: ElevatedButton(
                            onPressed: () {
                              _chatService.sendMessage(
                                chat.id,
                                '', // Empty text for post share
                                postId: widget.postId,
                                postImageUrl: widget.data['imageUrl'],
                                postTitle:
                                    widget.data['content'] ?? 'Publicación',
                              );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Enviado al chat")),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.joviRed,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Enviar"),
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
  }

  @override
  Widget build(BuildContext context) {
    // Data extraction
    final String username = widget.data['username'] ?? 'Usuario';
<<<<<<< HEAD
    final String? imageUrl = widget.data['imageUrl'];
    final String content = widget.data['content'] ?? '';
    final String location = widget.data['location'] ?? '';
=======
    final String userTitle = widget.data['userTitle'] ?? 'Creator';
    final String userDegree = widget.data['userDegree'] ?? '• 2º';
    final int userAvatarColor = widget.data['userAvatarColor'] ?? 0xFFEEEEEE;
    final String? imageUrl = widget.data['imageUrl'];
    final String content = widget.data['content'] ?? '';
    final bool isVideo = widget.data['isVideo'] ?? false;
    final String? videoDuration = widget.data['videoDuration'];
    final String? reproCount = widget.data['reproCount'];
    final String? badge = widget.data['badge'];
>>>>>>> 08759375c10047997d9cde5eccddac3892898c94

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
<<<<<<< HEAD
                  radius: 20,
                  backgroundColor: AppTheme.joviRed.withValues(alpha: 0.1),
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : 'U',
                    style: const TextStyle(
                        color: AppTheme.joviRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
=======
                  radius: 24,
                  backgroundColor: Color(userAvatarColor),
                  child: Text(
                    username[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
>>>>>>> 08759375c10047997d9cde5eccddac3892898c94
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
<<<<<<< HEAD
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
=======
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            userDegree,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (badge == null)
                            const Icon(Icons.add,
                                color: AppTheme.joviRed, size: 20),
                          if (badge != null)
                            const Icon(Icons.more_horiz,
                                color: Colors.grey, size: 20),
                        ],
                      ),
                      Text(
                        userTitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
>>>>>>> 08759375c10047997d9cde5eccddac3892898c94
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
<<<<<<< HEAD
                      if (location.isNotEmpty)
                        Text(
                          location,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
=======
>>>>>>> 08759375c10047997d9cde5eccddac3892898c94
                      Row(
                        children: [
                          Text(
                            "2 h • ",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                          Icon(Icons.public,
                              size: 11, color: Colors.grey.shade500),
                        ],
                      ),
                    ],
                  ),
                ),
<<<<<<< HEAD
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("Seguir"),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.joviRed,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
=======
                if (badge == null) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Seguir"),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.joviRed,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
>>>>>>> 08759375c10047997d9cde5eccddac3892898c94
              ],
            ),
          ),

          // Content Text with styled hashtags
          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _buildRichText(content),
            ),

          // Media Section (Image or Video)
          if (imageUrl != null)
<<<<<<< HEAD
            Image.network(
              imageUrl,
              height: 350,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 350,
                color: Colors.grey.shade200,
                child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey)),
              ),
=======
            Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  imageUrl,
                  height: 350,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 350,
                    color: Colors.grey.shade200,
                    child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey)),
                  ),
                ),
                // Video Play Overlay
                if (isVideo)
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.white, size: 45),
                  ),
                // AR Badge
                if (!isVideo)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.visibility,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          const Text(
                            "VISTA AR ACTIVA",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                // EN VIVO tag
                if (isVideo)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "EN VIVO",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Duration Badge
                if (isVideo && videoDuration != null)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        videoDuration,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
>>>>>>> 08759375c10047997d9cde5eccddac3892898c94
            ),

          // Counts Row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                // Reaction icons
                Stack(
                  children: [
                    _buildReactionIcon(Icons.thumb_up, Colors.blue),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: _buildReactionIcon(Icons.favorite, Colors.red),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Text(
                  "Alejandro y $_likeCount más",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Spacer(),
                Text(
                  "${widget.data['comments'] ?? 0} comentarios • ",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
<<<<<<< HEAD
                  "${widget.data['shares'] ?? 0} veces compartido",
=======
                  isVideo
                      ? "$reproCount reproducciones"
                      : "${widget.data['shares'] ?? 0} veces compartido",
>>>>>>> 08759375c10047997d9cde5eccddac3892898c94
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          const Divider(height: 1, indent: 12, endIndent: 12),

          // Simplified Action Bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: _ActionBarItem(
                    icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    label: "Recomendar",
                    color: _isLiked ? AppTheme.joviRed : Colors.grey.shade700,
                    onTap: _toggleLike,
                  ),
                ),
                Expanded(
                  child: _ActionBarItem(
                    icon: Icons.send_outlined,
                    label: "Enviar",
                    color: Colors.grey.shade700,
                    onTap: _shareToChat,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Icon(icon, color: Colors.white, size: 8),
    );
  }

  Widget _buildRichText(String text) {
    final words = text.split(' ');
    return Text.rich(
      TextSpan(
        children: words.map((word) {
          final isHashtag = word.startsWith('#');
          return TextSpan(
            text: '$word ',
            style: TextStyle(
              color: isHashtag ? AppTheme.joviRed : Colors.black87,
              fontWeight: isHashtag ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
              height: 1.4,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActionBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBarItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
