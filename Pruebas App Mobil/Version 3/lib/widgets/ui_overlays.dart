import 'package:flutter/material.dart';

class ARteGoOverlay extends StatelessWidget {
  const ARteGoOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top Right Buttons (Compass, Weather, etc.) - Items 1, 2, 3...
        Positioned(
          top: 60,
          right: 15,
          child: Column(
            children: [
              _buildRoundButton(Icons.explore, label: "Compass"), // Compass
              const SizedBox(height: 12),
              _buildRoundButton(Icons.wb_sunny, label: "Weather"), // Weather
              const SizedBox(height: 12),
              _buildRoundButton(Icons.map, label: "Map"), // Map/Settings
            ],
          ),
        ),

        // Bottom Left - Profile & Buddy (Items 11, 12, 43...)
        Positioned(
          bottom: 30,
          left: 20,
          child: _buildProfileAvatar(),
        ),

        // Bottom Center - Main Menu (ARte style) (Item 10)
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Center(
            child: _buildMainMenuButton(),
          ),
        ),

        // Bottom Right - Nearby Radar (Item 8)
        Positioned(
          bottom: 30,
          right: 20,
          child: _buildNearbyWidget(),
        ),
      ],
    );
  }

  Widget _buildRoundButton(IconData icon, {String? label}) {
    return Column(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85), // Glassmorphism base
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Icon(icon, color: Colors.teal.shade800, size: 26),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomLeft,
        children: [
          // Main Avatar Circle
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.teal.shade50, Colors.teal.shade200],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(Icons.face, size: 54, color: Colors.teal.shade900),
          ),
          // Buddy/Second Circle (smaller)
          Positioned(
            right: -8,
            bottom: 0,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade100, Colors.orange.shade300],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.pets, size: 24, color: Colors.white),
            ),
          ),
          // Level Indicator
          Positioned(
              left: -4,
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal.shade700, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ]),
                child: Text("43",
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: Colors.teal.shade800)),
              ))
        ],
      ),
    );
  }

  Widget _buildMainMenuButton() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.tealAccent.shade400, Colors.teal.shade800],
          stops: const [0.2, 1.0],
        ),
        shape: BoxShape.circle,
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.9), width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.5),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 38),
    );
  }

  Widget _buildNearbyWidget() {
    return Container(
      width: 120,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(Icons.bug_report, color: Colors.grey.shade400),
          Icon(Icons.grass, color: Colors.grey.shade400),
          Icon(Icons.water_drop, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
