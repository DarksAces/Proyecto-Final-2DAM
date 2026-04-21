import 'dart:async';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/map/nearby_sites_bar.dart';
import 'add_site_screen.dart';
import '../features/profile_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapLibreMapController? _mapController;
  bool _mapInitialized = false;
  bool _styleLoaded = false;

  static const String _mapStyle =
      'https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json';

  // GPS
  double _userLat = 40.4168; // Default to Madrid until GPS loads
  double _userLng = -3.7038;
  bool _hasLocation = false;
  bool _initialCenteringDone = false;
  StreamSubscription<Position>? _locationSub;

  // Firestore
  final List<Map<String, dynamic>> _stops = [];
  StreamSubscription? _firestoreSub;
  final List<Circle> _circles = [];

  // Filters
  String _filter = 'all';
  final List<String> _following = [];
  String? _myUid;

  // Selected Detail
  Map<String, dynamic>? _selected;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid;
    _initGPS();
    _loadData();

    // Safety timeout for loading screen
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && !_mapInitialized) {
        setState(() => _mapInitialized = true);
      }
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _firestoreSub?.cancel();
    super.dispose();
  }

  // ─── GPS & Geolocation ─────────────────────────────────────────────────────

  Future<void> _initGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are denied.');
      return;
    }

    try {
      // Get INITIAL position as fast as possible
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      _updateUserLocation(pos.latitude, pos.longitude);

      // Setup HIGH ACCURACY stream for movement
      _locationSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((p) => _updateUserLocation(p.latitude, p.longitude));
    } catch (e) {
      debugPrint('GPS initialization error: $e');
    }
  }

  void _updateUserLocation(double lat, double lng) {
    if (!mounted) return;

    setState(() {
      _userLat = lat;
      _userLng = lng;
      _hasLocation = true;
    });

    // AUTO-CENTER only once on startup
    if (!_initialCenteringDone && _mapController != null && _styleLoaded) {
      _initialCenteringDone = true;
      _recenter(zoom: 15.5);
    }
  }

  void _recenter({double zoom = 16.0}) {
    if (!_hasLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Obteniendo tu ubicación...')),
      );
      _initGPS(); // Try re-fetching
      return;
    }

    _mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: LatLng(_userLat, _userLng), zoom: zoom, tilt: 45),
    ));
  }

  // ─── Data Loading ──────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    // Load following list for filtering
    if (_myUid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_myUid)
            .get();
        final d = doc.data();
        if (mounted && d != null) {
          setState(() {
            _following.clear();
            _following.addAll(
                List<String>.from(d['followingList'] ?? d['following'] ?? []));
          });
        }
      } catch (e) {
        debugPrint('Error loading following list: $e');
      }
    }

    // Subscribe to sites
    _firestoreSub?.cancel();
    _firestoreSub = FirebaseFirestore.instance
        .collection('sitios')
        .snapshots()
        .listen((snap) {
      if (!mounted) return;

      setState(() {
        _stops.clear();
        for (final doc in snap.docs) {
          final d = doc.data();
          if (!d.containsKey('latitude') || !d.containsKey('longitude'))
            continue;

          final status = d['status'] ?? 'accepted';
          final authorId = d['userId'] ?? '';

          if (status != 'accepted' && authorId != _myUid) continue;

          _stops.add({
            'id': doc.id,
            'title': d['title'] ?? 'Sitio sin nombre',
            'description': d['description'] ?? 'Sin descripción',
            'lat': (d['latitude'] as num).toDouble(),
            'lng': (d['longitude'] as num).toDouble(),
            'author': d['username'] ?? 'Explorador',
            'authorId': authorId,
            'image': d['imageUrl'] ?? d['image'] ?? '',
          });
        }
      });

      if (_styleLoaded) _drawCircles();
    });
  }

  // ─── Map Operations ────────────────────────────────────────────────────────

  void _onMapCreated(MapLibreMapController c) {
    _mapController = c;
    c.onCircleTapped.add((circle) {
      final geo = circle.options.geometry;
      if (geo == null) return;
      for (final s in _stops) {
        if ((s['lat'] - geo.latitude).abs() < 0.0001 &&
            (s['lng'] - geo.longitude).abs() < 0.0001) {
          setState(() => _selected = s);
          _mapController?.animateCamera(CameraUpdate.newLatLng(geo));
          return;
        }
      }
    });
  }

  Future<void> _onStyleLoaded() async {
    if (!mounted) return;
    setState(() {
      _styleLoaded = true;
      _mapInitialized = true;
    });

    // Load official logo as map marker
    try {
      final ByteData bytes = await rootBundle.load('assets/images/logo.png');
      final Uint8List list = bytes.buffer.asUint8List();
      await _mapController?.addImage('aura-marker', list);
    } catch (e) {
      debugPrint('Error loading marker image: $e');
    }

    if (_hasLocation && !_initialCenteringDone) {
      _initialCenteringDone = true;
      _recenter(zoom: 15.5);
    }

    await _drawCircles();
  }

  Future<void> _drawCircles() async {
    if (_mapController == null || !mounted || !_styleLoaded) return;

    // Batch clearing
    for (final c in List.from(_circles)) {
      try {
        await _mapController!.removeCircle(c);
      } catch (_) {}
    }
    _circles.clear();

    for (final s in _stops) {
      final id = s['authorId'] as String;
      bool show;
      String color;

      if (_filter == 'me') {
        show = id == _myUid;
        color = '#4CAF50';
      } else if (_filter == 'following') {
        show = _following.contains(id);
        color = '#2979FF';
      } else {
        show = true;
        color = id == _myUid
            ? '#4CAF50'
            : (_following.contains(id) ? '#2979FF' : '#E30613');
      }

      if (!show || !mounted) continue;

      final c = await _mapController!.addCircle(CircleOptions(
        geometry: LatLng(s['lat'], s['lng']),
        circleColor: color,
        circleRadius: 11,
        circleStrokeWidth: 3,
        circleStrokeColor: '#FFFFFF',
        circleOpacity: 0.95,
      ));
      _circles.add(c);
    }
  }

  void _onNearbyTap(Map<String, dynamic> stop) {
    setState(() => _selected = stop);
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
          target: LatLng(stop['lat'], stop['lng']), zoom: 17.5, tilt: 30),
    ));
  }

  // ─── Build UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topPadding = mq.padding.top;
    final bottomNavHeight = kBottomNavigationBarHeight + mq.padding.bottom;
    final nearbyBarTop = topPadding + 70; // Adjusted for better spacing

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. The Map (Background)
          MapLibreMap(
            styleString: _mapStyle,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            initialCameraPosition: CameraPosition(
              target: LatLng(_userLat, _userLng),
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationTrackingMode: MyLocationTrackingMode.tracking,
            compassEnabled: false,
            attributionButtonPosition: AttributionButtonPosition.topRight,
          ),

          // 2. Loading Overlay
          if (!_mapInitialized) _buildLoadingOverlay(),

          // 3. UI Overlays (only visible once initialized)
          if (_mapInitialized) ...[
            // Glass Filter Bar
            Positioned(
              top: topPadding + 12,
              left: 16,
              right: 16,
              child: _GlassOverlay(
                child: _FilterBar(
                    selected: _filter,
                    onSelect: (f) {
                      setState(() => _filter = f);
                      _drawCircles();
                    }),
              ),
            ),

            // Obras Cercanas
            Positioned(
              top: nearbyBarTop,
              left: 0,
              right: 0,
              child: NearbySitesBar(
                stops: _stops,
                userLat: _userLat,
                userLng: _userLng,
                hasLocation: _hasLocation,
                onTap: _onNearbyTap,
              ),
            ),

            // Floating Buttons
            _buildFABs(bottomNavHeight),

            // Stop Detail Card
            if (_selected != null)
              Positioned(
                bottom: bottomNavHeight + 85,
                left: 16,
                right: 16,
                child: _StopCard(
                  stop: _selected!,
                  onClose: () => setState(() => _selected = null),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: const Color(0xFFF8F8F8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
                color: AppTheme.auraRed, strokeWidth: 3),
            const SizedBox(height: 20),
            Text(
              'Sincronizando con el mundo real...',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFABs(double bottomNavHeight) {
    return Stack(
      children: [
        // Add Site (Bottom Left)
        Positioned(
          bottom: bottomNavHeight + 16,
          left: 16,
          child: FloatingActionButton.extended(
            heroTag: 'add_main',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddSiteScreen()),
              );
              if (result == true) {
                _loadData(); // Force refresh
              }
            },
            backgroundColor: AppTheme.auraRed,
            elevation: 8,
            icon:
                const Icon(Icons.add_location_alt_rounded, color: Colors.white),
            label: const Text('NUEVA OBRA',
                style:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ),
        ),

        // Recenter (Bottom Right)
        Positioned(
          bottom: bottomNavHeight + 16,
          right: 16,
          child: _MapFab(
            icon: Icons.my_location_rounded,
            onTap: _recenter,
          ),
        ),
      ],
    );
  }
}

// ─── Helper UI Components ──────────────────────────────────────────────────

class _GlassOverlay extends StatelessWidget {
  final Widget child;
  const _GlassOverlay({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const _FilterBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(
            label: 'Todos', value: 'all', selected: selected, onTap: onSelect),
        _Chip(
            label: 'Seguidores',
            value: 'following',
            selected: selected,
            onTap: onSelect),
        _Chip(
            label: 'Mis Obras',
            value: 'me',
            selected: selected,
            onTap: onSelect),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label, value, selected;
  final void Function(String) onTap;

  const _Chip(
      {required this.label,
      required this.value,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSel = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? AppTheme.auraRed : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSel ? Colors.white : Colors.grey.shade700,
              fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapFab({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Icon(icon, color: AppTheme.auraRed, size: 28),
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  final Map<String, dynamic> stop;
  final VoidCallback onClose;
  const _StopCard({required this.stop, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              if (stop['image'].toString().isNotEmpty)
                Image.network(
                  stop['image'],
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.broken_image_rounded,
                        color: Colors.grey),
                  ),
                )
              else
                Container(
                  height: 140,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.image_not_supported_rounded,
                      color: Colors.grey),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.black, size: 20),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop['title'],
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  stop['description'] ?? 'Sin descripción disponible.',
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey.shade600, height: 1.3),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    if (stop['authorId'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfileScreen(userId: stop['authorId']),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.auraRed.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.auraRed.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_pin,
                            size: 16, color: AppTheme.auraRed),
                        const SizedBox(width: 6),
                        Text(
                          "Creado por: ",
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 13),
                        ),
                        Text(
                          stop['author'],
                          style: const TextStyle(
                            color: AppTheme.auraRed,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
