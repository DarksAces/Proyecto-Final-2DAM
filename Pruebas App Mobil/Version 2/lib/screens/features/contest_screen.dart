import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../services/contest_service.dart';

import '../../screens/main_wrapper.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'participation_screen.dart';
import 'ranking_screen.dart';

class ContestScreen extends StatefulWidget {
  const ContestScreen({super.key});

  @override
  State<ContestScreen> createState() => _ContestScreenState();
}

class _ContestScreenState extends State<ContestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();
  final ContestService _contestService = ContestService();
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: AppTheme.joviRed.withValues(alpha: 0.1),
            backgroundImage: _userData?['avatarUrl'] != null
                ? NetworkImage(_userData!['avatarUrl'])
                : null,
            child: _userData?['avatarUrl'] == null
                ? Text(
                    (_userData?['name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                        color: AppTheme.joviRed, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
        ),
        title: const Text("Concurso de Arte"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.joviRed,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.joviRed,
          tabs: const [
            Tab(text: "Global"),
            Tab(text: "Mi Colegio"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events, color: AppTheme.joviYellow),
            tooltip: 'Ver Ranking',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RankingScreen(
                    initialTabIndex: _tabController.index,
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Global Tab
          _ArtworkGrid(stream: _contestService.getGlobalArtworks()),
          // School Tab
          _userData != null && _userData!['schoolId'] != null
              ? _ArtworkGrid(
                  stream:
                      _contestService.getSchoolArtworks(_userData!['schoolId']),
                  emptyMessage: "No hay obras de tu colegio aún.",
                )
              : const Center(
                  child: Text("Cargando información de tu colegio...")),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2, // Highlight Map/Central button as it's an adventure
        onTap: (index) {
          Navigator.pop(context); // Close Contest Screen
          // Small delay to ensure pop animations don't conflict, usually not needed but safer
          Future.delayed(const Duration(milliseconds: 50), () {
            if (context.mounted) {
              MainWrapper.of(context)?.switchTab(index);
            }
          });
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ParticipationScreen()),
          );
        },
        label: const Text("PARTICIPAR",
            style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.joviRed,
      ),
    );
  }
}

class _ArtworkGrid extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String emptyMessage;

  const _ArtworkGrid(
      {required this.stream,
      this.emptyMessage = "No hay obras aceptadas aún."});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(emptyMessage));
        }

        final docs = snapshot.data!.docs;

        // Client-side sorting to avoid index requirements
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime =
              (aData['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
          final bTime =
              (bData['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
          return bTime.compareTo(aTime); // Descending
        });

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final imageUrl = data['imageUrl'] ??
                "https://picsum.photos/seed/contest_${docs[index].id}/300/400";
            final title = data['title'] ?? "Obra #${index + 1}";
            final artistName = data['artistName'] ?? "Artista";
            final isLiked =
                data['isLiked'] ?? false; // Simulate if user liked it

            return Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.grey.shade200,
                  image: DecorationImage(
                      image: NetworkImage(imageUrl), fit: BoxFit.cover)),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                                Text(artistName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: AppTheme.joviRed,
                            size: 16,
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
