import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';

class RankingScreen extends StatefulWidget {
  final int initialTabIndex;

  const RankingScreen({super.key, this.initialTabIndex = 0});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late int _selectedTabIndex;
  final UserService _userService = UserService();
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
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

  // Mock Data
  final List<Map<String, dynamic>> _globalRanking = [
    {
      "rank": 1,
      "name": "CreativoPro",
      "points": "24.150 pts",
      "tag": "MAESTRO TÉMPERAS",
      "imageUrl": "https://i.pravatar.cc/150?img=3",
      "ringColor": AppTheme.joviYellow,
      "size": 100.0
    },
    {
      "rank": 2,
      "name": "Marco AR",
      "points": "18.420 pts",
      "imageUrl": "https://i.pravatar.cc/150?img=11",
      "ringColor": const Color(0xFFC0C0C0),
      "size": 80.0
    },
    {
      "rank": 3,
      "name": "Elena_Art",
      "points": "15.900 pts",
      "imageUrl": "https://i.pravatar.cc/150?img=5",
      "ringColor": const Color(0xFFCD7F32),
      "size": 80.0
    },
    {
      "rank": 4,
      "name": "Pintor_Veloz",
      "subtext": "Experto en Acuarela",
      "points": "12.840",
      "imageUrl": "https://i.pravatar.cc/150?img=9"
    },
    {
      "rank": 5,
      "name": "JoviFan99",
      "subtext": "Iniciado",
      "points": "11.200",
      "imageUrl": "https://i.pravatar.cc/150?img=12"
    },
    {
      "rank": 6,
      "name": "Dibu_Gando",
      "subtext": "Mago del Color",
      "points": "10.550",
      "imageUrl": "https://i.pravatar.cc/150?img=20"
    },
    {
      "rank": 7,
      "name": "Sonia.Art_",
      "subtext": "Técnica Mixta",
      "points": "9.980",
      "imageUrl": "https://i.pravatar.cc/150?img=25"
    },
  ];

  final List<Map<String, dynamic>> _schoolRanking = [
    {
      "rank": 1,
      "name": "Tu Compañero",
      "points": "5.150 pts",
      "tag": "CLASE 5A",
      "imageUrl": "https://i.pravatar.cc/150?img=33",
      "ringColor": AppTheme.joviYellow,
      "size": 100.0
    },
    {
      "rank": 2,
      "name": "Ana Maria",
      "points": "4.420 pts",
      "imageUrl": "https://i.pravatar.cc/150?img=41",
      "ringColor": const Color(0xFFC0C0C0),
      "size": 80.0
    },
    {
      "rank": 3,
      "name": "Luis P.",
      "points": "3.900 pts",
      "imageUrl": "https://i.pravatar.cc/150?img=55",
      "ringColor": const Color(0xFFCD7F32),
      "size": 80.0
    },
    {
      "rank": 4,
      "name": "Carlos D.",
      "subtext": "Clase 4B",
      "points": "2.840",
      "imageUrl": "https://i.pravatar.cc/150?img=19"
    },
    {
      "rank": 5,
      "name": "Sofia M.",
      "subtext": "Clase 5A",
      "points": "2.200",
      "imageUrl": "https://i.pravatar.cc/150?img=22"
    },
    {
      "rank": 6,
      "name": "Javi R.",
      "subtext": "Clase 6C",
      "points": "1.950",
      "imageUrl": "https://i.pravatar.cc/150?img=15"
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentRanking =
        _selectedTabIndex == 0 ? _globalRanking : _schoolRanking;
    final top3 = currentRanking.sublist(0, 3);
    final rest = currentRanking.sublist(3);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.joviRed.withAlpha(30),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          "RANKING DE ARTISTAS",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.black,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 1.2),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tabs (Global/Mi Colegio)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = 0),
                        child: _TabButton(
                            label: "GLOBAL",
                            isSelected: _selectedTabIndex == 0),
                      )),
                      Expanded(
                          child: GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = 1),
                        child: _TabButton(
                            label: "MI COLEGIO",
                            isSelected: _selectedTabIndex == 1),
                      )),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Content (Podium + List)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(
                        bottom: 100), // Space for sticky footer
                    children: [
                      // Podium
                      SizedBox(
                        height: 260,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // 2nd Place
                            Positioned(
                              left: 30,
                              bottom: 20,
                              child: _PodiumItem(
                                rank: top3[1]['rank'],
                                name: top3[1]['name'],
                                points: top3[1]['points'],
                                imageUrl: top3[1]['imageUrl'],
                                ringColor: top3[1]['ringColor'],
                                size: top3[1]['size'],
                              ),
                            ),
                            // 3rd Place
                            Positioned(
                              right: 30,
                              bottom: 20,
                              child: _PodiumItem(
                                rank: top3[2]['rank'],
                                name: top3[2]['name'],
                                points: top3[2]['points'],
                                imageUrl: top3[2]['imageUrl'],
                                ringColor: top3[2]['ringColor'],
                                size: top3[2]['size'],
                              ),
                            ),
                            // 1st Place
                            Positioned(
                              top: 0,
                              child: _PodiumItem(
                                rank: top3[0]['rank'],
                                name: top3[0]['name'],
                                points: top3[0]['points'],
                                tag: top3[0]['tag'],
                                imageUrl: top3[0]['imageUrl'],
                                ringColor: top3[0]['ringColor'],
                                size: top3[0]['size'],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // List Items
                      ...rest.map((item) => _RankingListItem(
                            rank: item['rank'],
                            name: item['name'],
                            subtext: item['subtext'] ?? 'Participante',
                            points: item['points'],
                            imageUrl: item['imageUrl'],
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Footer
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                  color: AppTheme.joviRed,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.joviRed.withAlpha(100),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    )
                  ]),
              child: Row(
                children: [
                  Text(
                      _userData?['rank'] != null
                          ? "${_userData!['rank']}º"
                          : "142º",
                      style: const TextStyle(
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w900,
                          fontSize: 18)),
                  const SizedBox(width: 16),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        color: Colors.white),
                    child: CircleAvatar(
                      backgroundImage: _userData?['avatarUrl'] != null
                          ? NetworkImage(_userData!['avatarUrl'])
                          : null,
                      child: _userData?['avatarUrl'] == null
                          ? Text(
                              (_userData?['name'] ?? 'T')[0].toUpperCase(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          _userData?['name'] != null
                              ? "Tú (${_userData!['name']})"
                              : "Tú",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text(
                          _userData?['rankTitle']?.toUpperCase() ??
                              "APRENDIZ DE AR",
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_userData?['points']?.toString() ?? "2.450",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18)),
                      const Text("PUNTOS",
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 8,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _TabButton({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.joviRed : Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final int rank;
  final String name;
  final String points;
  final String? tag;
  final String imageUrl;
  final Color ringColor;
  final double size;

  const _PodiumItem({
    required this.rank,
    required this.name,
    required this.points,
    this.tag,
    required this.imageUrl,
    required this.ringColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: ringColor.withAlpha(50),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ]),
              child: CircleAvatar(
                  radius: size / 2, backgroundImage: NetworkImage(imageUrl)),
            ),
            Positioned(
              bottom: -10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ringColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$rankº",
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 12),
                ),
              ),
            )
          ],
        ),
        SizedBox(height: rank == 1 ? 20 : 16),
        Text(name,
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 4),
        Text(points,
            style: const TextStyle(
                color: AppTheme.joviRed,
                fontWeight: FontWeight.w900,
                fontSize: 14)),
        if (tag != null) ...[
          const SizedBox(height: 4),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1),
                  borderRadius: BorderRadius.circular(4)), // Dark Blue
              child: Text(tag!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold)))
        ]
      ],
    );
  }
}

class _RankingListItem extends StatelessWidget {
  final int rank;
  final String name;
  final String subtext;
  final String points;
  final String imageUrl;

  const _RankingListItem({
    required this.rank,
    required this.name,
    required this.subtext,
    required this.points,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              "$rank",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(backgroundImage: NetworkImage(imageUrl), radius: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(subtext,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(points,
                  style: const TextStyle(
                      color: AppTheme.joviBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 16)),
              Text("PUNTOS",
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 8,
                      fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}
