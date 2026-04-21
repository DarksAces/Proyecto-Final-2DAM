import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_background.dart'; // Import background
import '../features/contest_screen.dart';
import '../features/notifications_screen.dart';
import '../features/gallery_screen.dart';
import '../features/ar_scanner_screen.dart';
import '../main_wrapper.dart';
import '../../services/simulation_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Usuario';

    return Scaffold(
      body: AuthBackground(
        withBlob: false,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hola, $userName",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.black.withValues(alpha: 0.8)),
                        ),
                        const Text(
                          "Mundo AR Creativo",
                          style: TextStyle(
                              color: AppTheme.arteRed,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const NotificationsScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10)
                            ]),
                        child: const Icon(Icons.notifications,
                            color: AppTheme.arteRed),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),

                // Search Bar
                TextField(
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      // Demo search action
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("Buscando: $value..."),
                            backgroundColor: AppTheme.arteBlue),
                      );
                    }
                  },
                  decoration: InputDecoration(
                    hintText: "¿Qué vamos a descubrir hoy?",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon:
                        const Icon(Icons.search, color: AppTheme.arteRed),
                    suffixIcon: GestureDetector(
                      onTap: () => _showFilters(context),
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                            color: AppTheme.arteRed, shape: BoxShape.circle),
                        child: const Icon(Icons.tune,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                            color: AppTheme.arteRed, width: 1)),
                  ),
                ),

                const SizedBox(height: 30),

                // Grid - Title
                const Text("Tu Aventura",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                // Responsive Grid Area
                LayoutBuilder(builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 600 ? 5 : 4;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.9,
                    children: const [
                      _DashboardItem(
                          icon: Icons.map,
                          color: AppTheme.arteBlue,
                          label: "Mapa"),
                      _DashboardItem(
                          icon: Icons.emoji_events,
                          color: AppTheme.arteYellow,
                          label: "Concurso"),
                      _DashboardItem(
                          icon: Icons.qr_code_scanner,
                          color: AppTheme.arteRed,
                          label: "Escanear AR"),
                      _DashboardItem(
                          icon: Icons.public,
                          color: Color(0xFF2ECC71),
                          label: "Feed Social"),
                      _DashboardItem(
                          icon: Icons.collections,
                          color: Color(0xFF9B59B6),
                          label: "Mi Galería"),
                      _DashboardItem(
                          icon: Icons.person,
                          color: Color(0xFFF39C12),
                          label: "Mi Perfil"),
                    ],
                  );
                }),

                const SizedBox(height: 30),

                // Promo Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.arteRed.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 10),
                        )
                      ]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20)),
                        child: const Text("NOVEDAD EXCLUSIVA",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Pinta tu\nRealidad",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1.0),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Explora el mundo y añade color con nuestra AR creativa.",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.arteRed,
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.w900)),
                          child: const Text("EMPEZAR"))
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilters(BuildContext context) {
    // Capture MainWrapper state from the valid context
    final mainWrapper = MainWrapper.of(context);

    // Local state variables for the modal
    String selectedCategory = "Arte Urbano";
    double searchDistance = 5.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.55,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Filtros de Búsqueda",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                const Text("CATEGORÍA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _FilterChip(
                        label: "Arte Urbano",
                        isSelected: selectedCategory == "Arte Urbano",
                        onSelected: (val) {
                          setState(() => selectedCategory = "Arte Urbano");
                        }),
                    _FilterChip(
                        label: "Monumentos",
                        isSelected: selectedCategory == "Monumentos",
                        onSelected: (val) {
                          setState(() => selectedCategory = "Monumentos");
                        }),
                    _FilterChip(
                        label: "Naturaleza",
                        isSelected: selectedCategory == "Naturaleza",
                        onSelected: (val) {
                          setState(() => selectedCategory = "Naturaleza");
                        }),
                    _FilterChip(
                        label: "Eventos",
                        isSelected: selectedCategory == "Eventos",
                        onSelected: (val) {
                          setState(() => selectedCategory = "Eventos");
                        }),
                  ],
                ),
                const SizedBox(height: 25),
                const Text("DISTANCIA",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey)),
                Slider(
                    value: searchDistance,
                    min: 1,
                    max: 50,
                    divisions: 10,
                    activeColor: AppTheme.arteRed,
                    inactiveColor: Colors.grey.shade200,
                    label: "${searchDistance.round()} km",
                    onChanged: (val) {
                      setState(() => searchDistance = val);
                    }),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("1 km",
                        style: TextStyle(color: Colors.grey, fontSize: 10)),
                    Text("50 km",
                        style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                          sheetContext); // Close modal using sheetContext

                      // Use the captured mainWrapper instance
                      if (mainWrapper != null) {
                        mainWrapper.switchTab(2); // Switch to Map
                      }

                      // Trigger search event
                      SimulationService().triggerSearch(selectedCategory);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.arteRed,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 5,
                        shadowColor: AppTheme.arteRed.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    child: const Text("APLICAR FILTROS",
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontSize: 16)),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool)? onSelected;

  const _FilterChip(
      {required this.label, this.isSelected = false, this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppTheme.arteRed.withValues(alpha: 0.1),
      backgroundColor: Colors.grey.shade50,
      labelStyle: TextStyle(
          color: isSelected ? AppTheme.arteRed : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}

class _DashboardItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _DashboardItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final mainWrapper = MainWrapper.of(context);

        switch (label) {
          case "Mapa":
            mainWrapper?.switchTab(2); // Map Tab
            break;
          case "Concurso":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ContestScreen()),
            );
            break;
          case "Escanear AR":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ArScannerScreen()),
            );
            break;
          case "Feed Social":
            mainWrapper?.switchTab(1); // Social Tab
            break;
          case "Mi Galería":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GalleryScreen()),
            );
            break;
          case "Mi Perfil":
            mainWrapper?.switchTab(3); // Profile Tab
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            // Make icon container flexible
            child: AspectRatio(
              aspectRatio: 1, // Keep it square
              child: Container(
                decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ]),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }
}
