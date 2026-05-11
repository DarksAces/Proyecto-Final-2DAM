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
import 'connections_screen.dart';
import '../../l10n/app_localizations.dart';


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
    debugPrint('DEBUG: ProfileScreen _loadData for $targetId');
    if (targetId.isEmpty) {
      debugPrint('DEBUG: targetId is empty!');
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Sync points with real activity (posts, likes, AR)
    debugPrint('DEBUG: Triggering recalculateUserPoints...');
    await _userService.recalculateUserPoints(targetId);
    debugPrint('DEBUG: recalculateUserPoints finished.');

    final data = await _userService.getUserData(targetId);
    debugPrint('DEBUG: getUserData finished. Points in data: ${data?['points']}');
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
            content: Text(_isFollowing 
              ? AppLocalizations.of(context)!.profile_following_btn 
              : AppLocalizations.of(context)!.profile_follow_btn),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.profile_user_not_found), backgroundColor: Colors.red),
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
        title: type == 'followers' 
          ? AppLocalizations.of(context)!.profile_followers 
          : AppLocalizations.of(context)!.profile_following,

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
          return Scaffold(body: Center(child: Text(AppLocalizations.of(context)!.profile_user_not_found)));
        }


        final bool isMyProfile =
            widget.userId == null || widget.userId == _userService.currentUserId;
        final String username =
            displayData['displayName'] ?? displayData['username'] ?? 'Explorador';
        final String bio =
            displayData['bio'] ?? '¡Hola! Estoy explorando el mundo AR.';
        final int points = (displayData['points'] ?? 0).toInt();
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
              isMyProfile 
                ? AppLocalizations.of(context)!.profile_my_pro 
                : AppLocalizations.of(context)!.profile_title,
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
          body: SafeArea(
            child: RefreshIndicator(
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
                            : Text(_isFollowing 
                                ? AppLocalizations.of(context)!.profile_following_btn 
                                : AppLocalizations.of(context)!.profile_follow_btn,
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

                  // ── LEVEL & POINTS CARD ────────────────────────────────────
                  Builder(builder: (ctx) {
                    final levelInfo = _userService.getLevelInfo(points);
                    final int lvlMin = levelInfo['min'] as int;
                    final int lvlMax = levelInfo['max'] as int;
                    final Color lvlColor = Color(levelInfo['color'] as int);
                    final String lvlName = levelInfo['name'] as String;
                    final bool isMaxLevel = lvlMax >= 1000000;
                    final double progress = isMaxLevel
                        ? 1.0
                        : ((points - lvlMin) / (lvlMax - lvlMin)).clamp(0.0, 1.0);
                    final int ptsToNext = isMaxLevel ? 0 : lvlMax - points;

                    // Next level name
                    final nextLevelName = isMaxLevel
                        ? 'NIVEL MÁXIMO'
                        : _userService.getLevelName(lvlMax);
                    
                    final l10n = AppLocalizations.of(context)!;


                    return Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: lvlColor.withAlpha(30),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          )
                        ],
                        border: Border.all(color: lvlColor.withAlpha(40)),
                      ),
                      child: Column(
                        children: [
                          // Top row: avatar pts + level badge
                          Row(
                            children: [
                              // Points pill
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.profile_total_points,
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1)),

                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('$points',
                                            style: TextStyle(
                                                fontSize: 36,
                                                fontWeight: FontWeight.w900,
                                                color: lvlColor,
                                                height: 1)),
                                        const Padding(
                                          padding: EdgeInsets.only(bottom: 6, left: 4),
                                          child: Text('pts',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Level badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: lvlColor.withAlpha(18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: lvlColor.withAlpha(60)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      levelInfo['icon'] ?? '🌱',
                                      style: const TextStyle(fontSize: 26),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(lvlName.toUpperCase(),
                                        style: TextStyle(
                                            color: lvlColor,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 9,
                                            letterSpacing: 0.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Progress bar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isMaxLevel
                                        ? '🏆 NIVEL MÁXIMO ALCANZADO'
                                        : 'PROGRESO → ${nextLevelName.toUpperCase()}',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                        letterSpacing: 0.5),
                                  ),
                                  if (!isMaxLevel)
                                    Text(
                                      '${points - lvlMin}/${lvlMax - lvlMin} pts',
                                      style: TextStyle(
                                          color: lvlColor,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 10),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Stack(
                                children: [
                                  Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  AnimatedFractionallySizedBox(
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOut,
                                    widthFactor: progress,
                                    child: Container(
                                      height: 10,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            lvlColor.withAlpha(180),
                                            lvlColor,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: lvlColor.withAlpha(80),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (!isMaxLevel) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Te faltan $ptsToNext pts para ${nextLevelName.toUpperCase()}',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 10),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 16),

                          // Seguidores / Siguiendo row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _navigateToUserList('followers'),
                                child: _buildStat('SEGUIDORES', '$followers'),
                              ),
                              Container(
                                  height: 40, width: 1, color: Colors.grey.shade100),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _navigateToUserList('following'),
                                child: _buildStat('SIGUIENDO', '$following'),
                              ),
                              Container(
                                  height: 40, width: 1, color: Colors.grey.shade100),
                              _buildStat('OBRAS', '${_userContent.length}'),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

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
                            final String targetId = widget.userId ?? _userService.currentUserId ?? '';
                            
                            return _UniquePortfolioItem(
                              docId: item['id'] ?? '',
                              contentType: item['contentType'] ?? 'site',
                              authorId: targetId,
                              imageUrl: item['imageUrl'] ??
                                  "https://images.unsplash.com/photo-1550684848-fac1c5b4e853?w=500&q=60",
                              hearts: "${item['likes'] ?? 0}",
                              isAr: item['contentType'] == 'ar_object',
                              initialIsLiked: item['isLiked'] ?? false,
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
                                } else {
                                  // For sites/images, show full screen view
                                  _showFullScreenImage(
                                      context,
                                      item['imageUrl'] ??
                                          "https://images.unsplash.com/photo-1550684848-fac1c5b4e853?w=500&q=60",
                                      item['title'] ?? "Obra ARte");
                                }
                              },
                            );
                          },
                        ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
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

class _UniquePortfolioItem extends StatefulWidget {
  final String docId;
  final String contentType;
  final String authorId;
  final String imageUrl;
  final String hearts;
  final bool isAr;
  final bool initialIsLiked;
  final VoidCallback? onTap;

  const _UniquePortfolioItem({
    super.key,
    required this.docId,
    required this.contentType,
    required this.authorId,
    required this.imageUrl,
    required this.hearts,
    this.isAr = false,
    this.initialIsLiked = false,
    this.onTap,
  });

  @override
  State<_UniquePortfolioItem> createState() => _UniquePortfolioItemState();
}

class _UniquePortfolioItemState extends State<_UniquePortfolioItem> {
  late bool _isLiked;
  late int _likeCount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialIsLiked;
    _likeCount = int.tryParse(widget.hearts) ?? 0;
  }

  Future<void> _handleLike() async {
    if (_isLoading) return;

    final bool wasLiked = _isLiked;

    setState(() {
      _isLoading = true;
      // Optimistic update
      _isLiked = !wasLiked;
      _likeCount = wasLiked ? (_likeCount - 1).clamp(0, 999999) : _likeCount + 1;
    });

    bool success;
    if (wasLiked) {
      success = await UserService().unlikeContent(
        widget.docId,
        widget.contentType,
        widget.authorId,
      );
    } else {
      success = await UserService().likeContent(
        widget.docId,
        widget.contentType,
        widget.authorId,
      );
    }

    if (!success && mounted) {
      setState(() {
        _isLiked = wasLiked;
        _likeCount = wasLiked ? _likeCount + 1 : (_likeCount - 1).clamp(0, 999999);
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(wasLiked ? "Error al quitar me gusta" : "Error al dar me gusta")),
      );
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          image: DecorationImage(
            image: NetworkImage(widget.imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Dark gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            
            // AR Badge
            if (widget.isAr)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.4),
                        blurRadius: 4,
                      )
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.view_in_ar_rounded,
                          color: Colors.white, size: 10),
                      SizedBox(width: 4),
                      Text("3D", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: GestureDetector(
                onTap: _handleLike,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.redAccent : Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$_likeCount",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
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
}
