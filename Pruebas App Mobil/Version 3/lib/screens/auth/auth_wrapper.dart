import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_screen.dart';
import '../main_wrapper.dart';
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

        // If user is logged in, go to home
        if (snapshot.hasData && snapshot.data != null) {
          return const MainWrapper();
        }

        // If not logged in, show welcome screen
        return const WelcomeScreen();
      },
    );
  }
}
