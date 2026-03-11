import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../screens/features/add_friends_screen.dart';

class FeedHeader extends StatelessWidget {
  final String? avatarUrl;
  final VoidCallback onProfileTap;
  final VoidCallback onChatTap;
  final VoidCallback onNotificationTap;

  const FeedHeader({
    super.key,
    this.avatarUrl,
    required this.onProfileTap,
    required this.onChatTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.joviRed.withValues(alpha: 0.1),
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: AppTheme.joviRed, size: 20)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          // Search Bar
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddFriendsScreen()),
                );
              },
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Search discoveries, artists...",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Notification Icon
          GestureDetector(
            onTap: onNotificationTap,
            child: Icon(Icons.notifications_none,
                color: Colors.grey.shade700, size: 24),
          ),
          const SizedBox(width: 12),
          // Chat Icon (Right)
          GestureDetector(
            onTap: onChatTap,
            child: Icon(Icons.chat_bubble_outline,
                color: Colors.grey.shade700, size: 24),
          ),
        ],
      ),
    );
  }
}
