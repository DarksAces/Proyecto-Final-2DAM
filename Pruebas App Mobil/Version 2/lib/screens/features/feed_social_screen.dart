import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/social/feed_header.dart';
import '../../widgets/social/create_post_card.dart';
import '../../widgets/social/social_post_card.dart';
import 'notifications_screen.dart';
import 'social_screen.dart';
import 'create_post_screen.dart';
import '../../services/user_service.dart';

class FeedSocialScreen extends StatefulWidget {
  const FeedSocialScreen({super.key});

  @override
  State<FeedSocialScreen> createState() => _FeedSocialScreenState();
}

class _FeedSocialScreenState extends State<FeedSocialScreen> {
  final UserService _userService = UserService();
  Map<String, dynamic>? _userData;

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
      backgroundColor: Colors.grey.shade100, // Light grey background for feed
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            FeedHeader(
              avatarUrl: _userData?['avatarUrl'],
              onProfileTap: () {
                // Navigate to Profile or Menu
              },
              onChatTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SocialScreen()),
                );
              },
              onNotificationTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            // Feed Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Create Post Box
                      CreatePostCard(
                        avatarUrl: _userData?['avatarUrl'],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreatePostScreen(),
                            ),
                          );
                        },
                      ),

                      // Firestore Posts Stream
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('sitios')
                            .orderBy('timestamp', descending: true)
                            .limit(20)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return _buildEmptyState();
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final post = snapshot.data!.docs[index];
                              final data = post.data() as Map<String, dynamic>;
                              return SocialPostCard(
                                data: data,
                                postId: post.id,
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 80), // Bottom padding
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.style, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Aún no hay publicaciones de amigos',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
