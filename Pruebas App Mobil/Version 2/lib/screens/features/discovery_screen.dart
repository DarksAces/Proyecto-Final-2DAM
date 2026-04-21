import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background - Simulated using gradient or image
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF87CEEB).withAlpha(150), // Sky blue
                  const Color(0xFFAFE1AF).withAlpha(150), // Light Green
                ],
              ),
            ),
          ),

          // Confetti Shapes
          Positioned(
              top: 100,
              right: 60,
              child: Transform.rotate(
                  angle: -0.2,
                  child: Container(
                      width: 20, height: 10, color: AppTheme.joviYellow))),
          Positioned(
              top: 250,
              left: 40,
              child: Transform.rotate(
                  angle: 0.2,
                  child: Container(
                      width: 15, height: 25, color: AppTheme.joviBlue))),
          Positioned(
              top: 180,
              right: 20,
              child: Transform.rotate(
                  angle: 0.1,
                  child: Container(
                      width: 25, height: 10, color: AppTheme.joviRed))),

          Column(
            children: [
              const SizedBox(height: 60),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.celebration,
                        color: AppTheme.joviRed, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text("¡DESCUBRIMIENTO!",
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          letterSpacing: 0.5)),
                ],
              ),

              const Spacer(),
              // Central Reward Element
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Main Circle
                  Container(
                    width: 280,
                    height: 280,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(Icons.hub_outlined,
                          size: 100,
                          color: Colors
                              .grey.shade300), // Placeholder for Témpera Image
                    ),
                  ),

                  // Legendary Badge
                  Positioned(
                    top: -20,
                    right: 20,
                    child: Transform.rotate(
                      angle: 0.2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                            color: AppTheme.joviYellow,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withAlpha(20),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ]),
                        child: const Text("LEGENDARIO!",
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 14)),
                      ),
                    ),
                  ),

                  // Points Badge removed
                ],
              ),
              const Spacer(),
              const Spacer(),
            ],
          ),

          // Bottom Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(
                  20), // Added explicit margin for card effect if needed, design shows full width bottom sheet though
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                  color: const Color(
                      0xFFF1F4F0), // Off-white/light greyish as in image
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 30,
                        offset: const Offset(0, -5))
                  ]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("¡Felicidades!",
                      style: TextStyle(
                          color: AppTheme.joviRed,
                          fontSize: 32,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                        style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 16,
                            height: 1.5),
                        children: const [
                          TextSpan(text: "Has desbloqueado el "),
                          TextSpan(
                              text: "Bote de\nTémpera de Oro",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight:
                                      FontWeight.bold)), // Bold and new line
                          TextSpan(text: " para tu galería\npersonal."),
                        ]),
                  ),
                  const SizedBox(height: 30),

                  // Save to Gallery Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon:
                          const Icon(Icons.auto_fix_high, color: Colors.white),
                      label: const Text("Guardar en Galería",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.joviRed,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30))),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Share Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.share, color: Colors.white),
                      label: const Text("Compartir",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF0056B3), // Darker blue
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30))),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Return to Map Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.map_outlined,
                          color: AppTheme.joviRed),
                      label: const Text("Volver al Mapa",
                          style: TextStyle(
                              color: AppTheme.joviRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppTheme.joviRed, width: 2),
                          backgroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30))),
                    ),
                  ),

                  const SizedBox(height: 30),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            height: 1, width: 40, color: Colors.grey.shade300),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text("JOVI AR EXPLORER",
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 2.0)),
                        ),
                        Container(
                            height: 1, width: 40, color: Colors.grey.shade300),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
