import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
import '../settings/advanced_settings_screen.dart';
import 'ranking_screen.dart';
import 'ar_model_viewer_screen.dart';
import '../../services/ar_generation_service.dart';
import 'user_list_screen.dart';
import '../../services/chat_service.dart';
import 'chat_detail_screen.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final ArGenerationService _arService = ArGenerationService();
  final ChatService _chatService = ChatService();
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _userContent = [];
  List<Map<String, dynamic>> _medals = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final String targetId = widget.userId ?? _userService.currentUserId ?? '';
    if (targetId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final data = await _userService.getUserData(targetId);
    final content = await _userService.getUserContent(targetId);
    final isFollowing = await _userService.isFollowing(targetId);

    if (mounted) {
      setState(() {
        _userData = data;
        _userContent = content;
        _isFollowing = isFollowing;
        if (data != null) {
          _medals = _userService.calculateMedals(data, content.length);
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final String targetId = widget.userId ?? '';
    if (targetId.isEmpty || _userService.currentUserId == null) return;

    setState(() => _isActionLoading = true);

    bool success;
    if (_isFollowing) {
      success = await _userService.unfollowUser(targetId);
    } else {
      success = await _userService.followUser(targetId);
    }

    if (mounted) {
      setState(() {
        if (success) _isFollowing = !_isFollowing;
        _isActionLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing ? "Ahora sigues a este usuario" : "Has dejado de seguir a este usuario"),
            backgroundColor: AppTheme.arteBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _startChat() async {
    if (_userData == null || _userService.currentUserId == null) return;
    
    setState(() => _isActionLoading = true);
    
    try {
      final String targetId = widget.userId!;
      final String name = _userData!['displayName'] ?? _userData!['username'] ?? 'Usuario';
      final String avatar = _userData!['photoUrl'] ?? _userData!['avatarUrl'] ?? '';
      
      final String chatId = await _chatService.createChat(targetId, name, avatar);
      
      if (mounted) {
        setState(() => _isActionLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              chatId: chatId,
              chatName: name,
              avatarUrl: avatar,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al iniciar el chat"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToUserList(String type) {
    final String targetId = widget.userId ?? _userService.currentUserId ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserListScreen(
          userId: targetId,
          type: type,
          title: type == 'followers' ? "Seguidores" : "Seguidos",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String targetId = widget.userId ?? _userService.currentUserId ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(targetId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
          return const Scaffold(
              body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF))));
        }

        final userDataDoc = snapshot.data;
        final data = userDataDoc?.data() as Map<String, dynamic>?;
        
        // Use local _userData if stream is empty or just for initial load
        final displayData = data ?? _userData;

        if (displayData == null) {
          return const Scaffold(body: Center(child: Text("Usuario no encontrado")));
        }

        final bool isMyProfile =
            widget.userId == null || widget.userId == _userService.currentUserId;
        final String username =
            displayData['displayName'] ?? displayData['username'] ?? 'Explorador';
        final String bio =
            displayData['bio'] ?? '¡Hola! Estoy explorando el mundo AR.';
        final int points = displayData['points'] ?? 0;
        final String level = _userService.getLevelName(points);
        final String subtitle = displayData['userTitle'] ?? 'CREADOR AR';
        final int avatarColor = displayData['avatarColor'] ?? 0xFF6C63FF;
        
        // Still use the real-time count if possible, but the stream will trigger rebuilds
        final int followers = (displayData['followers'] ?? 0).clamp(0, 999999);
        final int following = (displayData['following'] ?? 0).clamp(0, 999999);
        final String? photoUrl = displayData['photoUrl'] ?? displayData['avatarUrl'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          isMyProfile ? "MI PERFIL PRO" : "PERFIL",
          style: const TextStyle(
              fontWeight: FontWeight.w900, color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: isMyProfile
            ? Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100, shape: BoxShape.circle),
                child: IconButton(
                  icon:
                      const Icon(Icons.settings, color: Colors.black, size: 20),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdvancedSettingsScreen())),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.grey.shade100, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.black, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF6C63FF),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              // Profile Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6C63FF),
                            Color(0xFFC084FC),
                            Color(0xFF6C63FF),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withAlpha(40),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ]),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(avatarColor),
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null 
                          ? Text(
                              username.isNotEmpty ? username[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child:
                        const Icon(Icons.verified, color: Colors.white, size: 16),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "@${username.replaceAll(' ', '_').toLowerCase()}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle.toUpperCase(),
                style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              Text(
                bio,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 14, height: 1.4),
              ),
              if (!isMyProfile) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _isActionLoading ? null : _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFollowing ? Colors.grey.shade200 : const Color(0xFF6C63FF),
                        foregroundColor: _isFollowing ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        elevation: _isFollowing ? 0 : 2,
                      ),
                      child: _isActionLoading 
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isFollowing ? "SIGUIENDO" : "SEGUIR",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _isActionLoading ? null : _startChat,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Icon(Icons.mail_outline_rounded),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              // Stats Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ]),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStat("PUNTOS", "$points"),
                        _buildStat("NIVEL", level),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _navigateToUserList('followers'),
                          child: _buildStat("SEGUIDORES", "$followers"),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _navigateToUserList('following'),
                          child: _buildStat("SIGUIENDO", "$following"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Progress Bar for Level
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("PROGRESO NIVEL",
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10)),
                            Text("${points % 500}/500 XP",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 10)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: (points % 500) / 500,
                            backgroundColor: Colors.grey.shade100,
                            color: const Color(0xFF6C63FF),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Medals Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Medallas",
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RankingScreen())),
                    child: const Text("Ver Ranking",
                        style: TextStyle(
                            color: Color(0xFF6C63FF),
                            fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _medals.isEmpty
                      ? [
                          Text("Explora para ganar medallas",
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 12))
                        ]
                      : _medals
                          .map((medal) => Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: _MedalItem(
                                  icon: medal['icon'],
                                  label: medal['label'],
                                  color: medal['color'],
                                  isSelected: medal['isUnlocked'],
                                  requirement: medal['requirement'] ?? '',
                                ),
                              ))
                          .toList(),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Portfolio",
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const Icon(Icons.grid_view_rounded,
                      color: Color(0xFF6C63FF), size: 24),
                ],
              ),
              const SizedBox(height: 16),
              _userContent.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          "Aún no hay obras en el portfolio",
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13),
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _userContent.length,
                      itemBuilder: (context, index) {
                        final item = _userContent[index];
                        return GestureDetector(
                          onTap: () async {
                            if (item['contentType'] == 'ar_object') {
                              final String url = item['url'];
                              final String name = item['name'] ?? "model.glb";

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Abriendo visor 3D..."),
                                    duration: Duration(seconds: 1)),
                              );

                              final File? file =
                                  await _arService.downloadToLocal(url, name);
                              if (file != null && mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ArModelViewerScreen(
                                      modelFile: file,
                                      modelUrl: url,
                                      title: "Mi Obra AR",
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: _PortfolioItem(
                            imageUrl: item['imageUrl'] ??
                                "https://images.unsplash.com/photo-1550684848-fac1c5b4e853?w=500&q=60",
                            hearts: "${item['likes'] ?? 0}",
                            isAr: item['contentType'] == 'ar_object',
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 1.0)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 24)),
      ],
    );
  }
}

class _MedalItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final String requirement;
  const _MedalItem({
    required this.icon,
    required this.label,
    required this.color,
    this.isSelected = false,
    this.requirement = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (!isSelected) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("BLOQUEADO: $label\nReq: $requirement"),
                  backgroundColor: Colors.black87,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: isSelected ? color : Colors.grey.shade200, width: 2),
              color: isSelected ? color.withOpacity(0.05) : Colors.white,
            ),
            child: Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade300,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: isSelected ? Colors.black : Colors.grey.shade400,
            ))
      ],
    );
  }
}

class _PortfolioItem extends StatelessWidget {
  final String imageUrl;
  final String hearts;
  final bool isAr;
  const _PortfolioItem({
    required this.imageUrl,
    required this.hearts,
    this.isAr = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image:
            DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(160)
                  ]),
            ),
          ),
          if (isAr)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF6C63FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.view_in_ar_rounded,
                    color: Colors.white, size: 14),
              ),
            ),
          Positioned(
            bottom: 12,
            left: 12,
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(hearts,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
