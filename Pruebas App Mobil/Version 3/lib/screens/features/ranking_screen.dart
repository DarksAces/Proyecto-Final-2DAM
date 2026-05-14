import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../utils/sync_util.dart';
import 'profile_screen.dart';
import '../../l10n/app_localizations.dart';


class RankingScreen extends StatefulWidget {
  final int initialTabIndex;
  const RankingScreen({super.key, this.initialTabIndex = 0});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final UserService _userService = UserService();
  Map<String, dynamic>? _myData;

  @override
  void initState() {
    super.initState();
    _loadMyData();
  }

  Future<void> _loadMyData() async {
    final data = await _userService.getCurrentUserData();
    if (mounted) setState(() => _myData = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Background gradient
            Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.arteRed.withAlpha(30),
                    AppTheme.backgroundWhite,
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.rank_title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                        IconButton(
                          icon: const Icon(Icons.sync_rounded, color: AppTheme.arteRed, size: 24),
                          tooltip: AppLocalizations.of(context)!.rank_sync_tooltip,

                          onPressed: () async {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppLocalizations.of(context)!.rank_syncing)),
                            );

                            await syncAllUsersPoints();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppLocalizations.of(context)!.rank_sync_done)),
                              );

                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // How to earn points banner
                  _PointsGuide(),

                  // Ranking list
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _userService.getRankingStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: AppTheme.arteRed),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Text(
                              AppLocalizations.of(context)!.rank_no_artists,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          );
                        }


                        final docs = snapshot.data!.docs.toList();
                        
                        // Sort in-memory: Points descending, then Name
                        docs.sort((a, b) {
                          final dataA = a.data() as Map<String, dynamic>;
                          final dataB = b.data() as Map<String, dynamic>;
                          final ptsA = (dataA['points'] ?? 0) as num;
                          final ptsB = (dataB['points'] ?? 0) as num;
                          
                          int compare = ptsB.compareTo(ptsA);
                          if (compare != 0) return compare;
                          
                          // Fallback to name if points are equal
                          final nameA = (dataA['displayName'] ?? '').toString();
                          final nameB = (dataB['displayName'] ?? '').toString();
                          return nameA.compareTo(nameB);
                        });

                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 110),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            final uid = docs[index].id;
                            final rank = index + 1;
                            final name = data['displayName'] ??
                                data['fullName'] ??
                                data['name'] ??
                                data['userName'] ??
                                data['username'] ??
                                'Explorador';
                            final int points = data['points'] != null ? (data['points'] as num).toInt() : 0;
                            final photoUrl = data['photoUrl'] ?? data['avatarUrl'];
                            final avatarColor = data['avatarColor'] ?? 0xFF6C63FF;
                            final level = _userService.getLevelName(points);

                            if (rank <= 3) {
                              // Top-3 gets a special card
                              return _TopRankCard(
                                rank: rank,
                                name: name,
                                points: points,
                                level: level,
                                photoUrl: photoUrl,
                                avatarColor: avatarColor,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfileScreen(userId: uid),
                                  ),
                                ),
                              );
                            }

                            return _RankingListItem(
                              rank: rank,
                              name: name,
                              level: level,
                              points: points,
                              photoUrl: photoUrl,
                              avatarColor: avatarColor,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfileScreen(userId: uid),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Sticky bottom card for current user
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 10,
              child: _MyPositionCard(myData: _myData, userService: _userService),
            ),
          ],
        ),
      ),
    );
  }
}

// ── TOP 3 CARD ────────────────────────────────────────────────────────────────

class _TopRankCard extends StatelessWidget {
  final int rank;
  final String name;
  final int points;
  final String level;
  final String? photoUrl;
  final int avatarColor;
  final VoidCallback onTap;

  const _TopRankCard({
    required this.rank,
    required this.name,
    required this.points,
    required this.level,
    this.photoUrl,
    required this.avatarColor,
    required this.onTap,
  });

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    return const Color(0xFFCD7F32); // Bronze
  }

  String get _rankEmoji {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    return '🥉';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_rankColor.withAlpha(40), Colors.white],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(color: _rankColor, width: 1.5),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _rankColor.withAlpha(60),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(_rankEmoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            _Avatar(photoUrl: photoUrl, avatarColor: avatarColor, name: name, radius: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(level,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$points',
                    style: TextStyle(
                        color: _rankColor == const Color(0xFFFFD700)
                            ? AppTheme.arteRed
                            : AppTheme.arteBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 20)),
                Text(AppLocalizations.of(context)!.rank_points,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),

              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── NORMAL LIST ITEM ──────────────────────────────────────────────────────────

class _RankingListItem extends StatelessWidget {
  final int rank;
  final String name;
  final String level;
  final int points;
  final String? photoUrl;
  final int avatarColor;
  final VoidCallback onTap;

  const _RankingListItem({
    required this.rank,
    required this.name,
    required this.level,
    required this.points,
    this.photoUrl,
    required this.avatarColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 10),
            _Avatar(photoUrl: photoUrl, avatarColor: avatarColor, name: name, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(level,
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$points',
                    style: const TextStyle(
                        color: AppTheme.arteBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 16)),
                Text(AppLocalizations.of(context)!.rank_points,
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 8,
                        fontWeight: FontWeight.bold)),

              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── MY POSITION FOOTER CARD ───────────────────────────────────────────────────

class _MyPositionCard extends StatelessWidget {
  final Map<String, dynamic>? myData;
  final UserService userService;

  const _MyPositionCard({this.myData, required this.userService});

  @override
  Widget build(BuildContext context) {
    final name = myData?['displayName'] ??
        myData?['fullName'] ??
        myData?['name'] ??
        myData?['userName'] ??
        'Yo';
    final points = (myData?['points'] ?? 0) as int;
    final photoUrl = myData?['photoUrl'] ?? myData?['avatarUrl'];
    final avatarColor = myData?['avatarColor'] ?? 0xFF6C63FF;
    final level = userService.getLevelName(points);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.arteRed,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.arteRed.withAlpha(100),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.person_pin, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          _Avatar(
            photoUrl: photoUrl,
            avatarColor: avatarColor,
            name: name,
            radius: 18,
            borderColor: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  level.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$points',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18),
              ),
              Text(
                AppLocalizations.of(context)!.rank_points,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 8,
                    fontWeight: FontWeight.bold),
              ),

            ],
          ),
        ],
      ),
    );
  }
}

// ── HOW TO EARN POINTS GUIDE ──────────────────────────────────────────────────

class _PointsGuide extends StatefulWidget {
  @override
  State<_PointsGuide> createState() => _PointsGuideState();
}

class _PointsGuideState extends State<_PointsGuide> {
  bool _expanded = false;

  static const _items = [
    {'icon': Icons.favorite_rounded, 'label': 'Like en tu obra del concurso', 'pts': '+5', 'color': 0xFFFF4D6D},
    {'icon': Icons.thumb_up_rounded, 'label': 'Like en tu publicación', 'pts': '+3', 'color': 0xFF4C9BE8},
    {'icon': Icons.view_in_ar_rounded, 'label': 'Generar modelo AR', 'pts': '+50', 'color': 0xFF7B61FF},
    {'icon': Icons.brush_rounded, 'label': 'Subir obra al concurso', 'pts': '+15', 'color': 0xFFFF9F43},
    {'icon': Icons.post_add_rounded, 'label': 'Crear nueva publicación', 'pts': '+10', 'color': 0xFF4CAF50},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.arteRed.withAlpha(12), const Color(0xFF6C63FF).withAlpha(12)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.arteRed.withAlpha(40)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.rank_how_earn,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    Icon(
                      _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                  ],
                ),
              ),
              if (_expanded) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                const SizedBox(height: 8),
                ...(_items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Color(item['color'] as int).withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item['icon'] as IconData, color: Color(item['color'] as int), size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getGuideItemLabel(context, item['label'] as String),
                          style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Color(item['color'] as int).withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item['pts'] as String,
                          style: TextStyle(
                            color: Color(item['color'] as int),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getGuideItemLabel(BuildContext context, String originalLabel) {
    final l10n = AppLocalizations.of(context)!;
    switch (originalLabel) {
      case 'Like en tu obra del concurso': return l10n.rank_item_contest_like;
      case 'Like en tu publicación': return l10n.rank_item_post_like;
      case 'Generar modelo AR': return l10n.rank_item_ar_gen;
      case 'Subir obra al concurso': return l10n.rank_item_contest_upload;
      case 'Crear nueva publicación': return l10n.rank_item_new_post;
      default: return originalLabel;
    }
  }
}


// ── SHARED AVATAR WIDGET ──────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final int avatarColor;
  final String name;
  final double radius;
  final Color? borderColor;

  const _Avatar({
    this.photoUrl,
    required this.avatarColor,
    required this.name,
    required this.radius,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: borderColor != null
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor!, width: 2),
            )
          : null,
      child: CircleAvatar(
        radius: radius,
        backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
        backgroundColor: Color(avatarColor),
        child: photoUrl == null
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.8,
                ),
              )
            : null,
      ),
    );
  }
}
