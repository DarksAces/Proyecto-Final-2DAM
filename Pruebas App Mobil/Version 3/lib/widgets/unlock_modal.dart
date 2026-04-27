import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UnlockModal extends StatelessWidget {
  const UnlockModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // White Card
          Container(
            margin: const EdgeInsets.only(top: 40),
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "¡Felicidades!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.arteRed,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                        fontSize: 16, color: Colors.black, height: 1.5),
                    children: [
                      TextSpan(text: "Has desbloqueado el objeto AR:\n"),
                      TextSpan(
                        text: "Totem de la Creatividad",
                        style: TextStyle(
                          color: AppTheme.arteBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.arteBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text("Colocar en Mapa",
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share, color: Colors.grey),
                  label: const Text("Compartir",
                      style: TextStyle(color: Colors.grey)),
                )
              ],
            ),
          ),
          // Floating Icon
          Positioned(
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.arteYellow.withAlpha(100),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 50,
                color: AppTheme.arteYellow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
