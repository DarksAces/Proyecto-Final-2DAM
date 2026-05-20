import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_screen.dart';
import '../main_wrapper.dart';
import '../tutorial/tutorial_screen.dart';
import '../../services/settings_service.dart';
import '../../widgets/loading_indicator.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BrandedLoadingScreen();
        }

        // If user is logged in, check if seen tutorial
        if (snapshot.hasData && snapshot.data != null) {
          if (!SettingsService().hasSeenTutorial) {
            return const TutorialScreen();
          }
          return const MainWrapper();
        }

        // If not logged in, show welcome screen
        return const WelcomeScreen();
      },
    );
  }
}
