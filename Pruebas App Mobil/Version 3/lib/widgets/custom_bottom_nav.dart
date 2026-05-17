import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';


class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final GlobalKey? homeKey;
  final GlobalKey? socialKey;
  final GlobalKey? mapKey;
  final GlobalKey? profileKey;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.homeKey,
    this.socialKey,
    this.mapKey,
    this.profileKey,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 12,
      shadowColor: Colors.black26,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
              icon: Icons.home_rounded,
              label: AppLocalizations.of(context)!.nav_home,
              isSelected: currentIndex == 0,
              showcaseKey: homeKey,
              showcaseTitle: 'Inicio / Explora',
              showcaseDesc: 'Aquí verás las obras AR destacadas, noticias exclusivas y acceso directo a escaneo.',
              showcaseColor: AppTheme.arteRed,
              onTap: () => onTap(0)),

          _NavItem(
              icon: Icons.people_alt_rounded,
              label: AppLocalizations.of(context)!.nav_social,
              isSelected: currentIndex == 1,
              showcaseKey: socialKey,
              showcaseTitle: 'Comunidad Social',
              showcaseDesc: 'Comparte tus capturas, descubre las publicaciones de tus amigos y conecta con otros artistas.',
              showcaseColor: AppTheme.arteBlue,
              onTap: () => onTap(1)),

          _NavItem(
              icon: Icons.map_rounded,
              label: AppLocalizations.of(context)!.nav_map,
              isSelected: currentIndex == 2,
              showcaseKey: mapKey,
              showcaseTitle: 'Mapa AR',
              showcaseDesc: 'Localiza obras de arte geolocalizadas a tu alrededor en tiempo real con el radar.',
              showcaseColor: AppTheme.arteYellow,
              onTap: () => onTap(2)),

          _NavItem(
              icon: Icons.person_rounded,
              label: AppLocalizations.of(context)!.nav_profile,
              isSelected: currentIndex == 3,
              showcaseKey: profileKey,
              showcaseTitle: 'Tu Perfil y Ranking',
              showcaseDesc: 'Revisa tus puntos, medallas, obras guardadas en tu portfolio y tu posición en el ranking.',
              showcaseColor: const Color(0xFF4CAF50),
              onTap: () => onTap(3)),

        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final GlobalKey? showcaseKey;
  final String? showcaseTitle;
  final String? showcaseDesc;
  final Color? showcaseColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.showcaseKey,
    this.showcaseTitle,
    this.showcaseDesc,
    this.showcaseColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppTheme.arteRed : Colors.grey.shade400;
    Widget content = InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.arteRed.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );

    if (showcaseKey != null && showcaseTitle != null && showcaseDesc != null) {
      content = Showcase(
        key: showcaseKey!,
        title: showcaseTitle!,
        description: showcaseDesc!,
        titleTextStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: showcaseColor ?? AppTheme.arteRed),
        descTextStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textBlack),
        tooltipPadding: const EdgeInsets.all(16),
        tooltipBorderRadius: BorderRadius.circular(16),
        targetShapeBorder: const CircleBorder(),
        targetPadding: const EdgeInsets.all(4),
        child: content,
      );
    }

    return Expanded(child: content);
  }
}
