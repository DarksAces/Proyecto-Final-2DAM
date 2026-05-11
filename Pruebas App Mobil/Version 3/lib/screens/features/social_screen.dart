import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../services/chat_service.dart';
import 'chat_detail_screen.dart';
import 'add_friends_screen.dart';
import 'profile_screen.dart';
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
    _markChatNotificationsAsRead();
  }

  Future<void> _markChatNotificationsAsRead() async {
    if (_currentUserId.isEmpty) return;
    try {
      final unreadChatNotifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: _currentUserId)
          .where('type', isEqualTo: 'chat')
          .where('read', isEqualTo: false)
          .get();

      if (unreadChatNotifications.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in unreadChatNotifications.docs) {
          batch.update(doc.reference, {'read': true});
        }
        await batch.commit();
        debugPrint('✅ SocialScreen: Marked ${unreadChatNotifications.docs.length} chat notifications as read');
      }
    } catch (e) {
      debugPrint('Error marking chat notifications as read: $e');
    }
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
                      color: AppTheme.arteRed,
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
                ],
              ),
            ),


            const SizedBox(height: 16),

            // Friends List (Amigos)
            SizedBox(
              height: 100,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _userService.getFollowingUsersDetails(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("Sigue a alguien para empezar a chatear", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    );
                  }
                  
                  final friends = snapshot.data!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      final avatarUrl = friend['avatarUrl'];
                      final name = friend['displayName'] ?? 'Usuario';
                      final targetUserId = friend['id'];
                      
                      return Container(
                        margin: const EdgeInsets.only(right: 16),
                        width: 60,
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfileScreen(userId: targetUserId),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: AppTheme.arteRed.withAlpha(50),
                                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                child: avatarUrl == null ? Text(name[0].toUpperCase(), style: const TextStyle(color: AppTheme.arteRed, fontWeight: FontWeight.bold)) : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () async {
                                try {
                                  final chatId = await _chatService.createChat(targetUserId, name, avatarUrl ?? '');
                                  if (mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatDetailScreen(
                                          chatId: chatId,
                                          chatName: name,
                                          avatarUrl: avatarUrl,
                                          otherUserId: targetUserId,
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint("Error creating chat: $e");
                                }
                              },
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Mensajes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
              ),
            ),

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
                                style: TextStyle(color: AppTheme.arteRed)),
                          )
                        ],
                      ),
                    );
                  }

                  final chats = snapshot.data!.docs.toList();
                  
                  // Sort locally to avoid Firestore composite index requirement
                  chats.sort((a, b) {
                    final dataA = a.data() as Map<String, dynamic>;
                    final dataB = b.data() as Map<String, dynamic>;
                    final tA = dataA['lastMessageTime'] as Timestamp?;
                    final tB = dataB['lastMessageTime'] as Timestamp?;
                    if (tA == null && tB == null) return 0;
                    if (tA == null) return 1;
                    if (tB == null) return -1;
                    return tB.compareTo(tA);
                  });

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

  const _ChatTile({
    required this.chatId,
    required this.data,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final participants = List<String>.from(data['participants'] ?? []);
    final otherUserId =
        participants.firstWhere((id) => id != currentUserId, orElse: () => '');

    final lastMessage = data['lastMessage'] ?? '';
    final timestamp = data['lastMessageTime'] as Timestamp?;
    final lastSenderId = data['lastSenderId'];
    final lastReadTimeMap = data['lastReadTime'] as Map<String, dynamic>?;
    final myLastReadTime = lastReadTimeMap?[currentUserId] as Timestamp?;

    final bool isUnread = lastSenderId != currentUserId && 
                          (myLastReadTime == null || 
                           (timestamp != null && timestamp.compareTo(myLastReadTime) > 0));

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

    if (otherUserId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(otherUserId).snapshots(),
      builder: (context, userSnapshot) {
        String name = "Usuario";
        String? avatarUrl;

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          name = userData['userName'] ?? userData['fullName'] ?? userData['displayName'] ?? "Usuario";
          // Try all possible avatar field names
          avatarUrl = userData['profileImageUrl'] ?? 
                      userData['avatarUrl'] ?? 
                      userData['photoUrl'];
          
          debugPrint('✅ SocialScreen: Loaded user $name ($otherUserId) with avatar: $avatarUrl');
        } else {
          // Fallback to chat metadata if user doc is loading or not found
          final names = data['participantNames'] as Map<String, dynamic>?;
          final avatars = data['participantAvatars'] as Map<String, dynamic>?;
          name = names?[otherUserId] ?? "Usuario";
          avatarUrl = avatars?[otherUserId];
        }

        return GestureDetector(
          onTap: () {
            debugPrint('👉 SocialScreen: Tapped on chat $chatId with $name');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  chatId: chatId,
                  chatName: name,
                  avatarUrl: avatarUrl,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isUnread ? AppTheme.arteRed.withValues(alpha: 0.05) : Colors.transparent,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(userId: otherUserId),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage:
                        (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                    backgroundColor: AppTheme.arteRed.withValues(alpha: 0.1),
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? Text(name[0].toUpperCase(),
                            style: const TextStyle(
                                color: AppTheme.arteRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 20))
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      debugPrint('👉 SocialScreen: Tapped on chat $chatId with $name');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            chatId: chatId,
                            chatName: name,
                            avatarUrl: avatarUrl,
                            otherUserId: otherUserId,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: isUnread ? FontWeight.w900 : FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: isUnread ? AppTheme.arteRed : Colors.grey,
                                fontSize: 12,
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastMessage,
                          style: TextStyle(
                            color: isUnread ? Colors.black : Colors.grey.shade600,
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
