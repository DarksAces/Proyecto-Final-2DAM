import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';
import '../screens/home/home_screen.dart';
import '../screens/features/feed_social_screen.dart';
import 'map/map_screen.dart';

import '../screens/features/profile_screen.dart';
import '../services/notification_service.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => MainWrapperState();

  static MainWrapperState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainWrapperState>();
  }
}

class MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    // Procesar notificaciones pendientes si existen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().processPendingNotification();
    });
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const FeedSocialScreen();
      case 2:
        return const MapScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
      _visitedTabs.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // el cuerpo se extiende detrás del nav bar
      body: SafeArea(
        bottom: true,
        child: Stack(
          fit: StackFit.expand,
          children: List.generate(4, (index) {
            final bool visited = _visitedTabs.contains(index);
            final bool active = _currentIndex == index;
            return Offstage(
              offstage: !active,
              child: visited ? _buildPage(index) : const SizedBox.shrink(),
            );
          }),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _visitedTabs.add(index);
          });
        },
      ),
    );
  }
}
