import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../main.dart';
import 'ar_scanner_screen.dart';

// ==========================================
// 1. PANTALLA INICIO
// ==========================================

class HomeScreen extends StatelessWidget {
  final TabController tabController;
  
  const HomeScreen({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoviTheme.gray,
      appBar: AppBar(
        title: Text("Hola, ${FirebaseAuth.instance.currentUser?.displayName ?? 'Viajero'}", style: JoviTheme.fontBaloo),
        backgroundColor: JoviTheme.yellow,
        foregroundColor: JoviTheme.blue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 160, 
              child: _DashboardCard(
                title: "Explorar Mapa",
                icon: LucideIcons.map,
                color: const Color(0xFFACD8AA), 
                onTap: () => tabController.animateTo(2), 
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 130,
                    child: _DashboardCard(
                      title: "Escanear AR",
                      icon: LucideIcons.scanLine,
                      color: const Color(0xFFFFD6E0), 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ARScannerScreen())),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 130,
                    child: _DashboardCard(
                      title: "Feed Social",
                      icon: LucideIcons.users,
                      color: const Color(0xFFC3F3F7), 
                      onTap: () => tabController.animateTo(1), 
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 130,
                    child: _DashboardCard(
                      title: "Mi Galería",
                      icon: LucideIcons.image,
                      color: const Color(0xFFFFF4BD), 
                      onTap: () => tabController.animateTo(3), 
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 130,
                    child: _DashboardCard(
                      title: "Mi Perfil",
                      icon: LucideIcons.userCircle,
                      color: Colors.white,
                      onTap: () => tabController.animateTo(4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: JoviTheme.blue),
                const SizedBox(height: 8),
                Text(
                  title, 
                  style: JoviTheme.fontBaloo.copyWith(fontSize: 16, color: JoviTheme.blue, fontWeight: FontWeight.bold), 
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
