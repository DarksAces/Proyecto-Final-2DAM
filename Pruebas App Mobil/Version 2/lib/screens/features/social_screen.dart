import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../services/chat_service.dart';
import 'chat_detail_screen.dart';
import 'add_friends_screen.dart';
import 'package:intl/intl.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();
  Map<String, dynamic>? _userData;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

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
    if (_currentUserId.isEmpty) {
      return const Scaffold(body: Center(child: Text('No estás autenticado')));
    }

    return Scaffold(
      backgroundColor: Colors.white, // Light theme as requested
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.joviRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.hub, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Comunidad",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddFriendsScreen()),
                      );
                    },
                    icon: const Icon(Icons.add_circle,
                        color: Colors.grey, size: 28),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings,
                        color: Colors.grey, size: 28),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100, // Darker input bg
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey),
                    hintText: "Buscar amigos o grupos...",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Chat List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatService.getUserChats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text(
                            "No tienes chats activos",
                            style: TextStyle(color: Colors.grey),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const AddFriendsScreen()),
                              );
                            },
                            child: const Text("Iniciar un chat",
                                style: TextStyle(color: AppTheme.joviRed)),
                          )
                        ],
                      ),
                    );
                  }

                  final chats = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: chats.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final data = chat.data() as Map<String, dynamic>;
                      return _ChatTile(
                        chatId: chat.id,
                        data: data,
                        currentUserId: _currentUserId,
                        onTap: () {
                          // Get other user name/avatar
                          String name = "Usuario";
                          String? avatarUrl;
                          final participants =
                              List<String>.from(data['participants'] ?? []);
                          final otherUserId = participants.firstWhere(
                              (id) => id != _currentUserId,
                              orElse: () => '');

                          if (otherUserId.isNotEmpty) {
                            final names = data['participantNames']
                                as Map<String, dynamic>?;
                            final avatars = data['participantAvatars']
                                as Map<String, dynamic>?;
                            name = names?[otherUserId] ?? "Usuario";
                            avatarUrl = avatars?[otherUserId];
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                chatId: chat.id,
                                chatName: name,
                                avatarUrl: avatarUrl,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String chatId;
  final Map<String, dynamic> data;
  final String currentUserId;
  final VoidCallback onTap;

  const _ChatTile({
    required this.chatId,
    required this.data,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final participants = List<String>.from(data['participants'] ?? []);
    final otherUserId =
        participants.firstWhere((id) => id != currentUserId, orElse: () => '');

    String name = "Usuario";
    String? avatarUrl;

    if (otherUserId.isNotEmpty) {
      final names = data['participantNames'] as Map<String, dynamic>?;
      final avatars = data['participantAvatars'] as Map<String, dynamic>?;
      name = names?[otherUserId] ?? "Usuario";
      avatarUrl = avatars?[otherUserId];
    }

    final lastMessage = data['lastMessage'] ?? '';
    final timestamp = data['lastMessageTime'] as Timestamp?;
    String timeStr = '';
    if (timestamp != null) {
      final dt = timestamp.toDate();
      final now = DateTime.now();
      if (now.difference(dt).inDays > 0) {
        timeStr = '${now.difference(dt).inDays} d';
      } else if (now.difference(dt).inHours > 0) {
        timeStr = '${now.difference(dt).inHours} h';
      } else {
        timeStr = '${now.difference(dt).inMinutes} min';
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  backgroundColor: AppTheme.joviRed.withValues(alpha: 0.1),
                  child: avatarUrl == null
                      ? Text(name[0].toUpperCase(),
                          style: const TextStyle(
                              color: AppTheme.joviRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 20))
                      : null,
                ),
                // Online indicator mock
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      border: Border.all(color: Colors.white, width: 2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        timeStr, // Mock time
                        style: TextStyle(
                          color: lastMessage.contains('rincón')
                              ? AppTheme.joviRed
                              : Colors.grey, // Highlight example
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
