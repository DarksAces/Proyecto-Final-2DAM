import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FilterModal extends StatefulWidget {
  const FilterModal({super.key});

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  String _selectedCategory = "Plastilina";
  String _selectedScope = "Mi Colegio";
  String _selectedSort = "Más Votados";

  final List<String> categories = [
    "Plastilina",
    "Pintura",
    "Dibujo",
    "Escultura"
  ];
  final List<String> scopes = ["Global", "Mi Colegio", "Mi Ciudad"];
  final List<String> sorts = ["Más Votados", "Más Recientes", "Finalistas"];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text("Filtros de Búsqueda",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit')),
          const SizedBox(height: 24),

          // Category
          const _SectionTitle(title: "CATEGORÍA DEL ARTE"),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: categories
                .map((c) => _FilterChip(
                      label: c,
                      isSelected: _selectedCategory == c,
                      onTap: () => setState(() => _selectedCategory = c),
                    ))
                .toList(),
          ),

          const SizedBox(height: 24),

          // Scope
          const _SectionTitle(title: "ÁMBITO"),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: scopes
                .map((s) => _FilterChip(
                      label: s,
                      isSelected: _selectedScope == s,
                      onTap: () => setState(() => _selectedScope = s),
                    ))
                .toList(),
          ),

          const SizedBox(height: 24),

          // Sort
          const _SectionTitle(title: "ORDENAR POR"),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: sorts
                .map((s) => _FilterChip(
                      label: s,
                      isSelected: _selectedSort == s,
                      onTap: () => setState(() => _selectedSort = s),
                    ))
                .toList(),
          ),

          const SizedBox(height: 40),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.arteRed,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Aplicar Filtros",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            color: Color(0xFF8A6365),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2));
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.arteRed : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
