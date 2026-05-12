import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/map/nearby_sites_bar.dart';
import '../../services/user_service.dart';
import 'add_site_screen.dart';
import '../features/profile_screen.dart';
import '../../l10n/app_localizations.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapLibreMapController? _mapController;
  bool _mapInitialized = false;
  bool _styleLoaded = false;
  bool _locationServiceEnabled = true;
  LocationPermission _permission = LocationPermission.denied;

  static const String _mapStyle =
      'https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json';

  // GPS & Radar
  double _userLat = 40.4168; 
  double _userLng = -3.7038;
  bool _hasLocation = false;
  bool _initialCenteringDone = false;
  StreamSubscription<Position>? _locationSub;
  double _radarRadiusMeters = 150.0; 
  Timer? _radarDebounce;

  // Firestore
  final List<Map<String, dynamic>> _stops = [];
  StreamSubscription? _firestoreSub;
  final List<Circle> _circles = [];
  Fill? _userRadarFill;

  // Filters
  String _filter = 'all';
  String _sortBy = 'distance'; 
  final List<String> _following = [];
  String? _myUid;
  final UserService _userService = UserService();
  final Random _random = Random();

  // Selected Detail
  Map<String, dynamic>? _selected;

  Map<String, dynamic>? _currentUserPrivacy;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid;
    _checkLocationStatus();
    _loadData();
    _listenToPrivacy();
  }

  void _listenToPrivacy() {
    _userService.currentUserDataStream.listen((snap) {
      if (snap.exists && mounted) {
        setState(() {
          _currentUserPrivacy = snap.data();
        });
        // Force update radar/circles when visibility settings change
        _updateUserRadar();
        _drawCircles();
      }
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _firestoreSub?.cancel();
    _radarDebounce?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (mounted) {
      setState(() {
        _locationServiceEnabled = serviceEnabled;
        _permission = permission;
      });
    }

    if (serviceEnabled && (permission == LocationPermission.always || permission == LocationPermission.whileInUse)) {
      _initGPS();
    }
  }

  Future<void> _requestLocationPermission() async {
    // Primero comprobamos si el permiso ha sido denegado permanentemente
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.map_perm_denied),
            content: Text(AppLocalizations.of(context)!.map_perm_denied_desc),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.map_cancel)),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Geolocator.openAppSettings();
                },
                child: Text(AppLocalizations.of(context)!.map_open_settings),
              ),
            ],
          ),

        );
      }
      return;
    }

    // Si es denegado o no se ha pedido, mostramos un aviso amigable antes del sistema
    if (permission == LocationPermission.denied || permission == LocationPermission.unableToDetermine) {
      bool? proceed = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_rounded, color: Color(0xFF6C63FF), size: 50),
              const SizedBox(height: 20),
              Text(AppLocalizations.of(context)!.map_allow_loc, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.map_loc_reason,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                  child: Text(AppLocalizations.of(context)!.map_continue, style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.map_later)),

            ],
          ),
        ),
      );
      
      if (proceed != true) return;
    }

    // Ahora sí, solicitamos permiso del sistema
    permission = await Geolocator.requestPermission();
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    
    if (mounted) {
      setState(() {
        _permission = permission;
        _locationServiceEnabled = serviceEnabled;
      });
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      if (serviceEnabled) {
        _initGPS();
      } else {
        await Geolocator.openLocationSettings();
      }
    }
  }

  Future<void> _initGPS() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      _updateUserLocation(pos.latitude, pos.longitude);

      _locationSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
      ).listen((p) => _updateUserLocation(p.latitude, p.longitude));
    } catch (e) {
      debugPrint('GPS initialization error: $e');
    }
  }

  void _updateUserLocation(double lat, double lng) {
    if (!mounted) return;
    bool firstLocation = !_hasLocation;
    setState(() {
      _userLat = lat;
      _userLng = lng;
      _hasLocation = true;
      _locationServiceEnabled = true;
    });

    if (firstLocation) {
      // build() handles initial map load
    } else if (_mapController != null && _styleLoaded) {
      _updateUserRadar();
      _drawCircles(); 
    }
  }

  List<LatLng> _calculateCirclePoints(double centerLat, double centerLng, double radiusMeters, {int points = 64}) {
    List<LatLng> circlePoints = [];
    const double earthRadius = 6378137.0;
    double latRad = centerLat * pi / 180;
    double lngRad = centerLng * pi / 180;
    double dOnR = radiusMeters / earthRadius;

    for (int i = 0; i < points; i++) {
      double bearing = 2 * pi * i / points;
      double pointLatRad = asin(sin(latRad) * cos(dOnR) + cos(latRad) * sin(dOnR) * cos(bearing));
      double pointLngRad = lngRad + atan2(sin(bearing) * sin(dOnR) * cos(latRad), cos(dOnR) - sin(latRad) * sin(pointLatRad));
      circlePoints.add(LatLng(pointLatRad * 180 / pi, pointLngRad * 180 / pi));
    }
    circlePoints.add(circlePoints.first);
    return circlePoints;
  }

  void _updateUserRadarWithDebounce() {
    // Immediate visual feedback for state (filtered stops)
    setState(() {}); 
    
    // Debounce the map update to prevent glitches
    _radarDebounce?.cancel();
    _radarDebounce = Timer(const Duration(milliseconds: 16), () {
      _updateUserRadar();
      _drawCircles();
    });
  }

  Future<void> _updateUserRadar() async {
    if (_mapController == null || !_styleLoaded || !mounted) return;

    final points = _calculateCirclePoints(_userLat, _userLng, _radarRadiusMeters);

    if (_userRadarFill != null) {
      try {
        await _mapController!.updateFill(_userRadarFill!, FillOptions(geometry: [points]));
        return;
      } catch (e) {
        // If update fails, fall back to re-add
        try { await _mapController!.removeFill(_userRadarFill!); } catch (_) {}
      }
    }

    bool isVisible = _currentUserPrivacy?['isVisibleOnMap'] ?? true;
    if (!isVisible) {
      if (_userRadarFill != null) {
        try { await _mapController!.removeFill(_userRadarFill!); } catch (_) {}
        _userRadarFill = null;
      }
      return;
    }

    _userRadarFill = await _mapController!.addFill(FillOptions(
      geometry: [points],
      fillColor: '#6C63FF',
      fillOpacity: 0.15,
      fillOutlineColor: '#6C63FF',
    ));
  }

  void _recenter({double zoom = 15.5}) {
    if (!_hasLocation) return;
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: LatLng(_userLat, _userLng), zoom: zoom, tilt: 25),
    ));
  }

  Future<void> _loadData() async {
    if (_myUid != null) {
      try {
        // Correctly fetch the IDs of people we follow from the sub-collection
        final followingSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(_myUid)
            .collection('following')
            .get();
            
        if (mounted) {
          setState(() {
            _following.clear();
            _following.addAll(followingSnap.docs.map((doc) => doc.id));
            debugPrint('DEBUG: Map following list loaded: ${_following.length} users');
          });
        }
      } catch (e) {
        debugPrint('Error loading following list from sub-collection: $e');
      }
    }

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
          if (!d.containsKey('latitude') || !d.containsKey('longitude')) continue;

          final status = (d['status'] ?? 'pending_review').toString();
          final authorId = (d['userId'] ?? '').toString();

          // Show: accepted/approved from anyone, OR own pending_review items
          final isAccepted = status == 'accepted' || status == 'approved';
          final isOwnPending = authorId == _myUid;
          if (!isAccepted && !isOwnPending) continue;

          // Obfuscation jitter: A bit more significant so coordinates aren't exact
          // (Approx 20-30 meters variance)
          double jitterLat = (d['latitude'] as num).toDouble() + (_random.nextDouble() - 0.5) * 0.0003;
          double jitterLng = (d['longitude'] as num).toDouble() + (_random.nextDouble() - 0.5) * 0.0003;

          _stops.add({
            'id': doc.id,
            'title': d['title'] ?? 'Sin título',
            'description': d['description'] ?? '',
            'lat': jitterLat,
            'lng': jitterLng,
            'realLat': (d['latitude'] as num).toDouble(),
            'realLng': (d['longitude'] as num).toDouble(),
            'author': d['username'] ?? 'Explorador',
            'authorId': authorId,
            'image': d['imageUrl'] ?? d['image'] ?? '',
            'likes': d['likesCount'] ?? d['likes'] ?? 0,
            'timestamp': (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'status': status,
          });
        }
      });

      if (_styleLoaded) _drawCircles();
    });
  }

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

    if (_hasLocation) {
      _updateUserRadar();
    }
    await _drawCircles();
  }

  Future<void> _drawCircles() async {
    if (_mapController == null || !mounted || !_styleLoaded) return;

    for (final c in List.from(_circles)) {
      try { await _mapController!.removeCircle(c); } catch (_) {}
    }
    _circles.clear();

    for (final s in _stops) {
      final id = s['authorId'] as String;

      // Distance filter (radar): markers only appear IF they are near the user
      // Use the real coordinates for accurate distance checking, but display the jittered ones
      final double distance = Geolocator.distanceBetween(
        _userLat, 
        _userLng, 
        s['realLat'] ?? s['lat'], 
        s['realLng'] ?? s['lng']
      );
      
      if (distance > _radarRadiusMeters) continue;

      // Category filter
      bool show;
      String color;
      if (_filter == 'me') {
        show = id == _myUid;
        color = '#FFD700';
      } else if (_filter == 'following') {
        show = _following.contains(id);
        color = '#4CAF50';
      } else {
        // 'all'
        show = true;
        if (id == _myUid) color = '#FFD700';
        else if (_following.contains(id)) color = '#4CAF50';
        else color = '#E30613';
      }

      if (!show || !mounted) continue;

      final c = await _mapController!.addCircle(CircleOptions(
        geometry: LatLng(s['lat'], s['lng']),
        circleColor: color,
        circleRadius: 10, // Larger for area feeling
        circleOpacity: 0.7, // Semi-transparent
        circleStrokeWidth: 3.0,
        circleStrokeColor: '#FFFFFF',
        circleStrokeOpacity: 0.5,
      ));
      _circles.add(c);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topPadding = mq.padding.top;
    final bottomNavHeight = kBottomNavigationBarHeight + mq.padding.bottom;
    bool isBlocked = !_locationServiceEnabled || (_permission == LocationPermission.denied || _permission == LocationPermission.deniedForever);

    // Apply category filter to nearby stops list
    final nearbyStops = _stops.where((s) {
      final double dist = Geolocator.distanceBetween(
        _userLat, 
        _userLng, 
        s['realLat'] ?? s['lat'], 
        s['realLng'] ?? s['lng']
      );
      
      if (dist > _radarRadiusMeters) return false;
      final id = s['authorId'] as String;
      if (_filter == 'me') return id == _myUid;
      if (_filter == 'following') return _following.contains(id);
      return true; // 'all'
    }).toList();

    if (_sortBy == 'likes') {
      nearbyStops.sort((a, b) => (b['likes'] as num).compareTo(a['likes'] as num));
    } else if (_sortBy == 'date') {
      nearbyStops.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    } else {
      nearbyStops.sort((a, b) {
        double da = Geolocator.distanceBetween(_userLat, _userLng, a['realLat'] ?? a['lat'], a['realLng'] ?? a['lng']);
        double db = Geolocator.distanceBetween(_userLat, _userLng, b['realLat'] ?? b['lat'], b['realLng'] ?? b['lng']);
        return da.compareTo(db);
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasLocation)
            MapLibreMap(
              styleString: _mapStyle,
              onMapCreated: _onMapCreated,
              onStyleLoadedCallback: _onStyleLoaded,
              initialCameraPosition: CameraPosition(target: LatLng(_userLat, _userLng), zoom: 15.5),
              myLocationEnabled: true,
              trackCameraPosition: true,
              compassEnabled: false,
            )
          else if (!isBlocked)
            _buildLocationWaitingOverlay(),

          // Ghost Mode Indicator
          if (_currentUserPrivacy?['isGhostMode'] == true)
            Positioned(
              bottom: bottomNavHeight + 150,
              left: 16,
              child: _GlassOverlay(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_off, color: Colors.blue.shade400, size: 18),
                    const SizedBox(width: 6),
                    Text(AppLocalizations.of(context)!.map_ghost_mode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
            ),


          if (_hasLocation && !_mapInitialized && !isBlocked) _buildLoadingOverlay(),

          if (_hasLocation && _mapInitialized && !isBlocked) ...[
            Positioned(
              top: topPadding + 10,
              left: 12, right: 12,
              child: _GlassOverlay(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: _FilterBar(
                        selected: _filter,
                        onSelect: (f) async {
                          // Refresh following list when changing to friends filter
                          if (f == 'following') await _loadData();
                          setState(() => _filter = f);
                          _drawCircles();
                        }
                      ),
                    ),
                    Container(width: 1, height: 20, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 8)),
                    _RadarMiniControl(
                      radius: _radarRadiusMeters,
                      onChanged: (v) {
                        setState(() => _radarRadiusMeters = v);
                        _updateUserRadarWithDebounce();
                      },
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: topPadding + 65,
              left: 0, right: 0,
              child: NearbySitesBar(
                stops: nearbyStops,
                userLat: _userLat,
                userLng: _userLng,
                hasLocation: _hasLocation,
                sortBy: _sortBy,
                onSortChanged: (val) => setState(() => _sortBy = val),
                onTap: (s) {
                  setState(() => _selected = s);
                  _mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(s['lat'], s['lng']), zoom: 17)));
                },
              ),
            ),

            _buildFABs(bottomNavHeight),

            if (_selected != null)
              Positioned(
                bottom: bottomNavHeight + 90,
                left: 16, right: 16,
                child: _StopCard(stop: _selected!, onClose: () => setState(() => _selected = null)),
              ),
          ],

          if (isBlocked) _buildGPSRequiredOverlay(),
        ],
      ),
    );
  }

  Widget _buildLocationWaitingOverlay() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.arteRed, strokeWidth: 3),
          const SizedBox(height: 30),
          Text(AppLocalizations.of(context)!.map_getting_loc, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5, color: AppTheme.arteRed)),
        ],
      ),
    );
  }

  Widget _buildGPSRequiredOverlay() {
    return Container(
      color: Colors.white.withAlpha(245),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off_rounded, color: AppTheme.arteRed, size: 70),
          const SizedBox(height: 30),
          Text(AppLocalizations.of(context)!.map_gps_required, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.map_gps_desc, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => _requestLocationPermission(),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.arteRed),
            child: Text(AppLocalizations.of(context)!.map_connect, style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],

      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(color: Colors.white, child: const Center(child: CircularProgressIndicator(color: AppTheme.arteRed)));
  }

  Widget _buildFABs(double bottomNavHeight) {
    return Stack(
      children: [
        Positioned(
          bottom: bottomNavHeight + 20,
          left: 16,
          child: GestureDetector(
            onTap: () async {
              final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSiteScreen()));
              if (res == true) _loadData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.arteRed,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppTheme.arteRed.withAlpha(60), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.map_create, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: bottomNavHeight + 20,
          right: 16,
          child: _MapFab(icon: Icons.my_location_rounded, onTap: () => _recenter()),
        ),
      ],
    );
  }
}

class _RadarMiniControl extends StatelessWidget {
  final double radius;
  final ValueChanged<double> onChanged;
  const _RadarMiniControl({required this.radius, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Row(
        children: [
          const Icon(Icons.radar_rounded, size: 14, color: AppTheme.arteRed),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppTheme.arteRed,
                inactiveTrackColor: AppTheme.arteRed.withAlpha(20),
                thumbColor: Colors.white,
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6, elevation: 2),
              ),
              child: Slider(value: radius, min: 50, max: 500, onChanged: onChanged),
            ),
          ),
          Text("${radius.round()}m", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppTheme.arteRed)),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _GlassOverlay extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _GlassOverlay({required this.child, this.padding = const EdgeInsets.all(4)});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(210),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(120), width: 1),
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
        _FilterTab(label: AppLocalizations.of(context)!.map_all, value: 'all', isSelected: selected == 'all', onTap: onSelect),
        _FilterTab(label: AppLocalizations.of(context)!.map_friends, value: 'following', isSelected: selected == 'following', onTap: onSelect),
        _FilterTab(label: AppLocalizations.of(context)!.map_mine, value: 'me', isSelected: selected == 'me', onTap: onSelect),
      ],

    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label, value;
  final bool isSelected;
  final void Function(String) onTap;
  const _FilterTab({required this.label, required this.value, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.arteRed : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5)),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Icon(icon, color: const Color(0xFF6C63FF), size: 24),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              if (stop['image'].toString().isNotEmpty)
                Image.network(stop['image'], height: 160, width: double.infinity, fit: BoxFit.cover)
              else
                Container(height: 160, color: const Color(0xFFF5F5F5), child: const Icon(Icons.image_outlined, color: Colors.grey)),
              Positioned(
                top: 10, right: 10,
                child: GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(stop['title'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
                    Text(stop['author'], style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(stop['description'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: stop['authorId']))),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('VER GALERÍA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
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
