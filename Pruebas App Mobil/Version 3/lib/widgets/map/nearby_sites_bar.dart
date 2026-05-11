import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class NearbySitesBar extends StatelessWidget {
  final List<Map<String, dynamic>> stops;
  final double userLat;
  final double userLng;
  final bool hasLocation;
  final String sortBy;
  final ValueChanged<String> onSortChanged;
  final void Function(Map<String, dynamic>) onTap;

  const NearbySitesBar({
    super.key,
    required this.stops,
    required this.userLat,
    required this.userLng,
    required this.hasLocation,
    required this.sortBy,
    required this.onSortChanged,
    required this.onTap,
  });

  double _distance(double lat, double lng) {
    const r = 6371000.0;
    final dLat = (lat - userLat) * pi / 180;
    final dLng = (lng - userLng) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(userLat * pi / 180) *
            cos(lat * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  String _formatDist(double m) {
    if (m < 1000) return '${m.round()}m';
    return '${(m / 1000).toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(180),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(80), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: Row(
                    children: [
                      const Text(
                        'CERCA DE TI',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2, color: Color(0xFF1A1A1A)),
                      ),
                      const Spacer(),
                      _SortMiniSelector(current: sortBy, onChanged: onSortChanged),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 80,
                  child: stops.isEmpty
                      ? const Center(child: Text('Sin obras cerca', style: TextStyle(fontSize: 10, color: Colors.grey)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: stops.length,
                          itemBuilder: (context, i) {
                            final s = stops[i];
                            final dist = hasLocation ? _distance(s['lat'], s['lng']) : null;
                            return _NearbyMiniCard(
                              stop: s,
                              distance: dist,
                              formatDist: _formatDist,
                              sortBy: sortBy,
                              onTap: () => onTap(s),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SortMiniSelector extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  const _SortMiniSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: current,
      onSelected: onChanged,
      offset: const Offset(0, 30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFF6C63FF).withAlpha(15), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(
              current == 'likes' ? Icons.favorite : (current == 'date' ? Icons.access_time : Icons.near_me),
              size: 10, color: const Color(0xFF6C63FF)
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 10, color: Color(0xFF6C63FF)),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'distance', height: 35, child: Text('Distancia', style: TextStyle(fontSize: 11))),
        const PopupMenuItem(value: 'likes', height: 35, child: Text('Likes', style: TextStyle(fontSize: 11))),
        const PopupMenuItem(value: 'date', height: 35, child: Text('Fecha', style: TextStyle(fontSize: 11))),
      ],
    );
  }
}

class _NearbyMiniCard extends StatelessWidget {
  final Map<String, dynamic> stop;
  final double? distance;
  final String sortBy;
  final String Function(double) formatDist;
  final VoidCallback onTap;

  const _NearbyMiniCard({
    required this.stop,
    required this.distance,
    required this.formatDist,
    required this.sortBy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = stop['image'] as String? ?? '';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 10, bottom: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            if (image.isNotEmpty)
              Image.network(image, width: 60, height: double.infinity, fit: BoxFit.cover)
            else
              Container(width: 60, color: Colors.grey.shade100, child: const Icon(Icons.image_outlined, color: Colors.grey, size: 16)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stop['title'] ?? 'Sin título',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2D2D2D)),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (sortBy == 'likes')
                      Row(children: [const Icon(Icons.favorite, size: 9, color: Colors.redAccent), const SizedBox(width: 3), Text("${stop['likes']}", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))])
                    else if (distance != null)
                      Text(formatDist(distance!), style: const TextStyle(fontSize: 9, color: Color(0xFF6C63FF), fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
