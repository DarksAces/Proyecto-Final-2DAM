import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CreatePostCard extends StatelessWidget {
  final String? avatarUrl;
  final VoidCallback? onTap;

  const CreatePostCard({super.key, this.avatarUrl, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8), // Gap before next item
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.arteGreen.withOpacity(0.1),
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.person,
                          color: AppTheme.arteGreen, size: 24)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      "Start a post...",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionButton(
                icon: Icons.photo,
                label: "Photo",
                color: const Color(0xFFE30613), // Red
              ),
              _ActionButton(
                icon: Icons.videocam,
                label: "Video",
                color: const Color(0xFF0099D8), // Blue
              ),
              _ActionButton(
                icon: Icons.event,
                label: "Event",
                color: const Color(0xFFFFCC00), // Yellow
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
