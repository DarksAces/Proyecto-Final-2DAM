import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../main.dart';
import 'ar_scanner_screen.dart';
import 'shop_screen.dart'; // Importar pantalla de tienda
import 'contest_screen.dart'; // Importar para corregir error de compilación

// ==========================================
// 1. PANTALLA INICIO
// ==========================================

/// Pantalla de Inicio (Dashboard).
///
/// Muestra las funcionalidades principales de la aplicación en formato de tarjetas grandes:
/// - Tienda Jovi
/// - Concurso
/// - Escáner AR
/// - Feed Social
/// - Galería y Perfil
class HomeScreen extends StatelessWidget {
  final TabController tabController;
  
  const HomeScreen({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoviTheme.gray,
      appBar: AppBar(
        title: Row(
          children: [
            Image.network(
              "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Jovi_Logo.svg/512px-Jovi_Logo.svg.png",
              height: 30,
              errorBuilder: (_,__,___) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 10),
            Text("Hola, ${FirebaseAuth.instance.currentUser?.displayName ?? 'Viajero'}", style: JoviTheme.fontBaloo),
          ],
        ),
        backgroundColor: JoviTheme.yellow,
        foregroundColor: JoviTheme.blue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // NUEVO: DOS EJES CENTRALES (TIENDA Y CONCURSO)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 160, // Aumentado para mejor visibilidad
                    child: _DashboardCard(
                      title: "Tienda Jovi",
                      icon: LucideIcons.shoppingBag,
                      color: const Color(0xFFACD8AA),
                      onTap: () {
                        // Navegar a la pantalla nativa de la tienda
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const JoviShopScreen()));
                      }, 
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 160,
                    child: _DashboardCard(
                      title: "El Concurso",
                      icon: LucideIcons.trophy,
                      color: const Color(0xFFFFD6E0),
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const ContestScreen()));
                      }, 
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

/// Widget auxiliar para las tarjetas del Dashboard.
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
