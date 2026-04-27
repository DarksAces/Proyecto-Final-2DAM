import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final UserService _userService = UserService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    if (_currentUserId.isEmpty) {
      return const Scaffold(body: Center(child: Text('No estás autenticado')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Notificaciones",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _userService.getNotifications(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    "No tienes notificaciones aún",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;
          // Sort manually because of potential index issues in service
          final sortedDocs = notifications.toList()
            ..sort((a, b) {
              final aTime = (a.data() as Map)['timestamp'] as Timestamp?;
              final bTime = (b.data() as Map)['timestamp'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime);
            });

          return ListView.builder(
            itemCount: sortedDocs.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _NotificationTile(
                notificationId: doc.id,
                data: data,
                onTap: () {
                  _userService.markNotificationAsRead(doc.id);
                  // Optional: Navigate based on notification type
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String notificationId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notificationId,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String message = data['message'] ?? 'Nueva notificación';
    final String type = data['type'] ?? 'info';
    final bool read = data['read'] ?? false;
    final Timestamp? timestamp = data['timestamp'] as Timestamp?;

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'welcome':
        icon = Icons.star;
        iconColor = AppTheme.arteYellow;
        break;
      case 'like':
        icon = Icons.favorite;
        iconColor = AppTheme.arteRed;
        break;
      case 'comment':
        icon = Icons.chat_bubble;
        iconColor = AppTheme.arteBlue;
        break;
      default:
        icon = Icons.notifications;
        iconColor = AppTheme.arteRed;
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: read
            ? Colors.transparent
            : AppTheme.arteRed.withValues(alpha: 0.03),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      fontWeight: read ? FontWeight.normal : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (timestamp != null)
                    Text(
                      DateFormat('dd MMM, HH:mm').format(timestamp.toDate()),
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                ],
              ),
            ),
            if (!read)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppTheme.arteRed,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
