import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_background.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      withBlob: true,
      child: SingleChildScrollView(
        child: Container(
          // Ensure min height to fill screen if possible, but allow scrolling
          constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header Badge
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.auraYellow,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.palette_rounded,
                          color: AppTheme.auraRed, size: 16),
                      SizedBox(width: 5),
                      Text(
                        "CREATIVITY FIRST",
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.auraRed),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Logo/Blob Area
              Image.asset(
                'assets/images/logo.png',
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.auto_awesome,
                    color: Colors.white24,
                    size: 80),
              ),

              const SizedBox(height: 20),

              // Texts
              Column(
                children: [
                  const Text(
                    "AURA AR",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.auraBlue,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "¡Crea tu propia\naventura mágica!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textBlack,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Explora lugares secretos y dales vida\ncon la magia de tus colores.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.auraRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "¡EMPEZAR A JUGAR!",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.rocket_launch,
                              color: Colors.white, size: 20)
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/login'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: AppTheme.auraBlue.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withValues(alpha: 0.8)),
                      child: const Text(
                        "Entrar ahora",
                        style: TextStyle(
                            color: AppTheme.auraBlue,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
