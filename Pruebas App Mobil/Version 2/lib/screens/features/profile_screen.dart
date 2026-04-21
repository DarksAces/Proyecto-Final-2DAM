import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
import '../settings/advanced_settings_screen.dart';
import 'ranking_screen.dart';
import 'ar_model_viewer_screen.dart';
import '../../services/ar_generation_service.dart';
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
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _userContent = [];
  List<Map<String, dynamic>> _medals = [];
  bool _isLoading = true;

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

    if (mounted) {
      setState(() {
        _userData = data;
        _userContent = content;
<<<<<<< HEAD
        _userData = data;
        _userContent = content;
=======
        if (data != null) {
          _medals = _userService.calculateMedals(data, content.length);
        }
>>>>>>> 08759375c10047997d9cde5eccddac3892898c94
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppTheme.joviRed)));
    }

    final bool isMyProfile =
        widget.userId == null || widget.userId == _userService.currentUserId;
    final String username =
        _userData?['displayName'] ?? _userData?['username'] ?? 'Explorador';
<<<<<<< HEAD
=======
    final String bio =
        _userData?['bio'] ?? '¡Hola! Estoy explorando el mundo AR.';
    final int points = _userData?['points'] ?? 0;
    final String level = _userService.getLevelName(points);
    final String subtitle = _userData?['userTitle'] ?? 'CREADOR AR';
>>>>>>> 08759375c10047997d9cde5eccddac3892898c94
    final int avatarColor = _userData?['avatarColor'] ?? 0xFFE30613;
    final int followers = _userData?['followers'] ?? 0;
    final int following = _userData?['following'] ?? 0;

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
            : BackButton(color: Colors.black),
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
      body: SingleChildScrollView(
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
                          AppTheme.joviYellow,
                          Colors.orange,
                          AppTheme.joviRed
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.joviYellow.withValues(alpha: 0.4),
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
                      child: Text(
                        username.isNotEmpty ? username[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.joviRed,
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
<<<<<<< HEAD
            const SizedBox(height: 8),
            const SizedBox(height: 16),
=======
            const SizedBox(height: 4),
            Text(
              subtitle.toUpperCase(),
              style: const TextStyle(
                  color: AppTheme.joviRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 14, height: 1.4),
            ),
>>>>>>> 08759375c10047997d9cde5eccddac3892898c94
            if (!isMyProfile) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.joviRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("SEGUIR",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {},
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
<<<<<<< HEAD
            // Stats Card removed as per cleanup
            const SizedBox(height: 30),
            // Medals and stats removed as per cleanup
=======
            // Stats Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat("SEGUIDORES", "$followers"),
                      _buildStat("SIGUIENDO", "$following"),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                          color: AppTheme.joviRed,
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
                          color: AppTheme.joviRed,
                          fontWeight: FontWeight.bold)),
                )
              ],
            ),
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
>>>>>>> 08759375c10047997d9cde5eccddac3892898c94
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Portfolio",
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const Icon(Icons.grid_view_rounded,
                    color: AppTheme.joviRed, size: 24),
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
                    Colors.black.withValues(alpha: 0.6)
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
                  color: AppTheme.joviRed,
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
