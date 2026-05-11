import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_background.dart'; // Import background
import '../features/contest_screen.dart';
import '../features/notifications_screen.dart';
import '../features/gallery_screen.dart';
import '../features/ar_scanner_screen.dart';
import '../features/ar_generation_screen.dart';
import '../main_wrapper.dart';
import '../map/add_site_screen.dart';
import '../../services/user_service.dart';
import '../../l10n/app_localizations.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Usuario';

    return Scaffold(
      body: AuthBackground(
        withBlob: false,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.home_hello(userName),
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.black.withValues(alpha: 0.8)),
                        ),
                        Text(
                          AppLocalizations.of(context)!.home_creative_world,
                          style: const TextStyle(
                              color: AppTheme.arteRed,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0),
                        ),

                      ],
                    ),
                    StreamBuilder<int>(
                        stream: UserService()
                            .getUnreadNotificationsCount(user?.uid ?? ''),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationsScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 10)
                                  ]),
                              child: Badge.count(
                                count: count,
                                isLabelVisible: count > 0,
                                backgroundColor: AppTheme.arteRed,
                                child: const Icon(Icons.notifications,
                                    color: AppTheme.arteRed),
                              ),
                            ),
                          );
                        })
                  ],
                ),
                const SizedBox(height: 30),

                // Grid - Title
                Text(AppLocalizations.of(context)!.home_your_adventure,
                    style:
                        const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                const SizedBox(height: 15),

                // Responsive Grid Area
                LayoutBuilder(builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 600 ? 5 : 4;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.9,
                    children: [
                      _DashboardItem(
                          icon: Icons.map,
                          color: AppTheme.arteBlue,
                          label: AppLocalizations.of(context)!.home_view_map),
                      _DashboardItem(
                          icon: Icons.emoji_events,
                          color: AppTheme.arteYellow,
                          label: AppLocalizations.of(context)!.home_contest),
                      _DashboardItem(
                          icon: Icons.qr_code_scanner,
                          color: AppTheme.arteRed,
                          label: AppLocalizations.of(context)!.home_scan_ar),
                      _DashboardItem(
                          icon: Icons.public,
                          color: const Color(0xFF2ECC71),
                          label: AppLocalizations.of(context)!.home_feed_social),
                      _DashboardItem(
                          icon: Icons.collections,
                          color: const Color(0xFF9B59B6),
                          label: AppLocalizations.of(context)!.home_my_gallery),
                      _DashboardItem(
                          icon: Icons.person,
                          color: const Color(0xFFF39C12),
                          label: AppLocalizations.of(context)!.home_my_profile),

                    ],
                  );
                }),

                const SizedBox(height: 30),

                // Promo Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.arteRed.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 10),
                        )
                      ]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(AppLocalizations.of(context)!.home_exclusive_news,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),

                      ),
                      const SizedBox(height: 15),
                      Text(
                        AppLocalizations.of(context)!.home_paint_reality,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1.0),
                      ),

                      const SizedBox(height: 10),
                      Text(
                        AppLocalizations.of(context)!.home_explore_desc,
                        style: const TextStyle(color: Colors.white70),
                      ),

                      const SizedBox(height: 20),
                      ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ArGenerationScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.arteRed,
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.w900)),
                          child: Text(AppLocalizations.of(context)!.home_start_button))

                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _DashboardItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final mainWrapper = MainWrapper.of(context);

        final l10n = AppLocalizations.of(context)!;
        if (label == l10n.home_view_map) {
          mainWrapper?.switchTab(2); // Map Tab
        } else if (label == l10n.home_contest) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ContestScreen()),
          );
        } else if (label == l10n.home_scan_ar) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ArScannerScreen()),
          );
        } else if (label == l10n.home_feed_social) {
          mainWrapper?.switchTab(1); // Social Tab
        } else if (label == l10n.home_my_gallery) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GalleryScreen()),
          );
        } else if (label == l10n.home_my_profile) {
          mainWrapper?.switchTab(3); // Profile Tab
        }

      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            // Make icon container flexible
            child: AspectRatio(
              aspectRatio: 1, // Keep it square
              child: Container(
                decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ]),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }
}
