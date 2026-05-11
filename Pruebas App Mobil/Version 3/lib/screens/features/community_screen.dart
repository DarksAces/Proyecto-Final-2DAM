import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';
import '../../services/user_service.dart';
import 'profile_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _userService.getAllUsersWithFollowStatus();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF100505), // Dark Red/Black
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.arteRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.hub,
                        color: Colors.white, size: 20), // Placeholder for logo
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Comunidad",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                  const Spacer(),
                  _HeaderButton(icon: Icons.add, onPressed: () {}),
                  const SizedBox(width: 12),
                  _HeaderButton(icon: Icons.settings, onPressed: () {}),
                ],
              ),
            ),

            // Search Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 12),
                  Text("Buscar amigos o exploradores...",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // User List (Real Data)
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.arteRed))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final name = user['displayName'] ?? user['username'] ?? 'Usuario';
                      final photoUrl = user['photoUrl'] ?? user['avatarUrl'];
                      
                      return _ChatTile(
                        userId: user['id'],
                        name: name,
                        message: user['bio'] ?? "Explorador en ARte",
                        time: "Ahora",
                        imageUrl: photoUrl ?? "https://i.pravatar.cc/150?u=${user['id']}",
                        isVerified: user['isVerified'] == true,
                        isOnline: index % 3 == 0,
                      );
                    },
                  ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppTheme.arteRed,
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _HeaderButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String userId;
  final String name;
  final String message;
  final String time;
  final String imageUrl;
  final bool isVerified;
  final bool isOnline;
  final bool hasUnread;
  final bool isRedTime;
  final bool hasRing;
  final Color? ringColor;
  final bool isHighlightedStart;

  const _ChatTile({
    required this.userId,
    required this.name,
    required this.message,
    required this.time,
    required this.imageUrl,
    this.isVerified = false,
    this.isOnline = false,
    this.hasUnread = false,
    this.isRedTime = false,
    this.hasRing = false,
    this.ringColor,
    this.isHighlightedStart = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ChatScreen()));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        color: Colors.transparent, // Ensure hit test works
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(userId: userId),
                  ),
                );
              },
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: hasRing
                          ? Border.all(
                              color: ringColor ?? Colors.transparent, width: 2)
                          : null,
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(imageUrl),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                      ),
                    )
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      if (isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: Colors.blue, size: 16)
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: isHighlightedStart
                              ? Colors.white
                              : Colors.grey.shade500,
                          fontWeight: isHighlightedStart
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(time,
                    style: TextStyle(
                        color:
                            isRedTime ? AppTheme.arteRed : Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight:
                            isRedTime ? FontWeight.bold : FontWeight.normal)),
                if (hasUnread) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.arteRed,
                      shape: BoxShape.circle,
                    ),
                  )
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}
