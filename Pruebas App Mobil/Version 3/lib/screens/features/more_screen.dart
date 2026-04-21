import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

import '../features/gallery_screen.dart';
import '../features/ar_generation_screen.dart';
import '../main_wrapper.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: Stack(
        children: [
          // Background Decor
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.auraRed.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text("Menú",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textBlack)),

                const SizedBox(height: 30),

                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    padding: const EdgeInsets.all(24),
                    mainAxisSpacing: 30,
                    crossAxisSpacing: 20,
                    children: [
                      _MenuButton(
                        icon: Icons.settings_rounded,
                        label: "Ajustes",
                        color: Colors.grey.shade700,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Ajustes próximamente")),
                          );
                        },
                      ),
                      _MenuButton(
                        icon: Icons.person_rounded,
                        label: "Perfil",
                        color: AppTheme.auraBlue,
                        onTap: () {
                          MainWrapper.of(context)
                              ?.switchTab(4); // Switch to Profile tab
                        },
                      ),
                      _MenuButton(
                        icon: Icons.event_available_rounded,
                        label: "Eventos",
                        color: AppTheme.auraYellow,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Sin eventos cercanos")),
                          );
                        },
                      ),
                      _MenuButton(
                        icon: Icons.newspaper_rounded,
                        label: "Noticias",
                        color: Colors.purple,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Noticias al día")),
                          );
                        },
                      ),
                      _MenuButton(
                        icon: Icons.help_outline_rounded,
                        label: "Ayuda",
                        color: Colors.teal,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Centro de Ayuda")),
                          );
                        },
                      ),
                      _MenuButton(
                        icon: Icons.favorite_rounded,
                        label: "Favoritos",
                        color: Colors.pink,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Tus favoritos")),
                          );
                        },
                      ),
                      _MenuButton(
                        icon: Icons.wallet_giftcard_rounded,
                        label: "Cupones",
                        color: Colors.orange,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Cupones no disponibles")),
                          );
                        },
                      ),
                      _MenuButton(
                        icon: Icons.camera_alt_rounded,
                        label: "Galería AR",
                        color: Colors.indigo,
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const GalleryScreen()));
                        },
                      ),
                      _MenuButton(
                        icon: Icons.auto_awesome_rounded,
                        label: "Generar AR",
                        color: AppTheme.auraRed,
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ArGenerationScreen()));
                        },
                      ),
                    ],
                  ),
                ),

                // Version info
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text("Versión 1.0.0 (Aura Beta)",
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
                border:
                    Border.all(color: color.withValues(alpha: 0.1), width: 1)),
            child: Icon(icon, color: color, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))
      ],
    );
  }
}
