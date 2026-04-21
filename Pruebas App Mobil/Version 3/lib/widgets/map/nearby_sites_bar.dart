import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class NearbySitesBar extends StatelessWidget {
  final List<Map<String, dynamic>> stops;
  final double userLat;
  final double userLng;
  final bool hasLocation;
  final void Function(Map<String, dynamic>) onTap;

  const NearbySitesBar({
    super.key,
    required this.stops,
    required this.userLat,
    required this.userLng,
    required this.hasLocation,
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
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...stops];
    if (hasLocation) {
      sorted.sort((a, b) {
        final da = _distance(a['lat'], a['lng']);
        final db = _distance(b['lat'], b['lng']);
        return da.compareTo(db);
      });
    }

    final nearby = sorted.take(15).toList();

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.auraRed.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.explore_rounded,
                          size: 14, color: AppTheme.auraRed),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'OBRAS CERCANAS',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.8,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    if (hasLocation)
                      Text(
                        'A tu alrededor',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 95,
                child: nearby.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, bottom: 16),
                        itemCount: nearby.length,
                        itemBuilder: (context, i) {
                          final s = nearby[i];
                          final dist = hasLocation
                              ? _distance(s['lat'], s['lng'])
                              : null;
                          return _NearbyCard(
                            stop: s,
                            distance: dist,
                            formatDist: _formatDist,
                            onTap: () => onTap(s),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          'Explora el mapa para encontrar obras',
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
              fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  final Map<String, dynamic> stop;
  final double? distance;
  final String Function(double) formatDist;
  final VoidCallback onTap;

  const _NearbyCard({
    required this.stop,
    required this.distance,
    required this.formatDist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = stop['image'] as String? ?? '';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 175,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            if (image.isNotEmpty)
              Image.network(
                image,
                width: 65,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            else
              _placeholder(),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stop['title'] ?? 'Sin título',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (distance != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.auraRed.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          formatDist(distance!),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.auraRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 65,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.auraRed.withValues(alpha: 0.1),
            AppTheme.auraRed.withValues(alpha: 0.05)
          ],
        ),
      ),
      child: const Icon(Icons.image_not_supported_rounded,
          color: AppTheme.auraRed, size: 24),
    );
  }
}
