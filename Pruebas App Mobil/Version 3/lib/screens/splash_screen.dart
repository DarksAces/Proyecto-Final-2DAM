import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../services/simulation_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Attach listener BEFORE starting animation to avoid race conditions
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAndNavigate();
      }
    });

    _controller.forward();
    _initializeApp();
  }

  bool _isInitDone = false;
  bool _isAnimationDone = false;

  Future<void> _initializeApp() async {
    try {
      debugPrint('🔥 SplashScreen: Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 15));
      debugPrint('🔥 SplashScreen: Firebase ready!');

      // Initialize demo data in background
      SimulationService()
          .initSimulation()
          .catchError((e) => debugPrint("Error seeding: $e"));
    } catch (e) {
      debugPrint('⚠️ SplashScreen: Firebase init error: $e');
    } finally {
      _isInitDone = true;
      _checkAndNavigate();
    }
  }

  void _checkAndNavigate() {
    if (_controller.status == AnimationStatus.completed) {
      _isAnimationDone = true;
    }

    if (_isInitDone && _isAnimationDone) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/auth');
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.auto_awesome, size: 100, color: AppTheme.arteRed),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ARte',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
