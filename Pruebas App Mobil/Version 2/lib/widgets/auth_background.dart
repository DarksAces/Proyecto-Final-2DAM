import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:math';

class AuthBackground extends StatelessWidget {
  final Widget child;
  final bool withBlob;

  const AuthBackground({super.key, required this.child, this.withBlob = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Polka Dot Pattern
          SizedBox.expand(
            child: CustomPaint(
              painter: _DotPatternPainter(),
            ),
          ),

          // Optional: Top Blob for Welcome Screen
          if (withBlob)
            Positioned(
              top: -100,
              left: -50,
              right: -50,
              child: Container(
                height: 500,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A), // Dark blob color
                  shape: BoxShape.circle,
                ),
              ),
            ),

          // Content
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    const double spacing = 40.0;

    // Fixed random seed for consistent pattern
    final Random random = Random(42);

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        // Add some jitter
        double dx = x + (random.nextDouble() - 0.5) * 10;
        double dy = y + (random.nextDouble() - 0.5) * 10;

        // Randomly pick color (mostly yellow, some blue, rare red)
        double r = random.nextDouble();
        if (r < 0.7) {
          paint.color = AppTheme.joviYellow.withValues(alpha: 0.4);
        } else if (r < 0.9) {
          paint.color = AppTheme.joviBlue.withValues(alpha: 0.3);
        } else {
          paint.color = AppTheme.joviRed.withValues(alpha: 0.2);
        }

        // Draw small circle
        canvas.drawCircle(Offset(dx, dy), 2.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
