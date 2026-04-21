import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';

/// Pantalla para añadir un nuevo sitio al mapa.
/// Recoge título, descripción, foto y la ubicación GPS actual.
/// Crea un post en Firestore con latitude/longitude para que aparezca en el mapa.
class AddSiteScreen extends StatefulWidget {
  const AddSiteScreen({super.key});

  @override
  State<AddSiteScreen> createState() => _AddSiteScreenState();
}

class _AddSiteScreenState extends State<AddSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  File? _imageFile;
  bool _loading = false;
  bool _gpsLoading = true;
  double? _lat;
  double? _lng;
  String? _gpsError;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── GPS ──────────────────────────────────────────────────────────────────

  Future<void> _getLocation() async {
    setState(() {
      _gpsLoading = true;
      _gpsError = null;
    });
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() {
          _gpsLoading = false;
          _gpsError = 'Activa el GPS del móvil';
        });
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() {
          _gpsLoading = false;
          _gpsError = 'Permiso de ubicación denegado';
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _gpsLoading = false;
      });
    } catch (e) {
      setState(() {
        _gpsLoading = false;
        _gpsError = 'Error al obtener ubicación';
      });
    }
  }

  // ── Imagen ────────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1080,
    );
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppTheme.joviRed,
              ),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppTheme.joviRed,
              ),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Publicar ──────────────────────────────────────────────────────────────

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esperando ubicación GPS...')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      String imageUrl = '';

      // Subir imagen si la hay
      if (_imageFile != null) {
        final storage = FirebaseStorage.instanceFor(
          bucket: 'gs://jovi-45c79.firebasestorage.app',
        );
        final ref = storage.ref().child(
          'stop_photos/${user!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      // Obtener nombre del usuario
      String username = user?.displayName ?? 'Usuario';
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .get();
        username =
            doc.data()?['username'] ?? doc.data()?['displayName'] ?? username;
      } catch (_) {}

      // Crear post en Firestore
      await FirebaseFirestore.instance.collection('sitios').add({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'latitude': _lat,
        'longitude': _lng,
        'userId': user?.uid ?? '',
        'username': username,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'site',
        'status': 'accepted',
      });

      if (mounted) {
        Navigator.pop(context, true); // true = publicado con éxito
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al publicar: $e')));
        setState(() => _loading = false);
      }
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Añadir sitio',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _publish,
              child: const Text(
                'Publicar',
                style: TextStyle(
                  color: AppTheme.joviRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.joviRed,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Foto
            GestureDetector(
              onTap: _showImageOptions,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Añadir foto (opcional)',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // Título
            TextFormField(
              controller: _titleCtrl,
              maxLength: 60,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nombre del sitio *',
                hintText: 'Ej: Cafetería La Paloma',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.joviRed),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El nombre es obligatorio'
                  : null,
            ),
            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Cuéntanos algo sobre este sitio...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.joviRed),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Estado GPS
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _gpsError != null
                    ? Colors.red.shade50
                    : (_lat != null
                          ? Colors.green.shade50
                          : Colors.blue.shade50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _gpsError != null
                      ? Colors.red.shade200
                      : (_lat != null
                            ? Colors.green.shade200
                            : Colors.blue.shade200),
                ),
              ),
              child: Row(
                children: [
                  if (_gpsLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _gpsError != null
                          ? Icons.location_off
                          : Icons.location_on_rounded,
                      color: _gpsError != null
                          ? Colors.red
                          : Colors.green.shade700,
                      size: 20,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _gpsLoading
                          ? 'Obteniendo ubicación GPS...'
                          : _gpsError != null
                          ? _gpsError!
                          : 'Ubicación obtenida ✓\n${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _gpsError != null
                            ? Colors.red.shade700
                            : Colors.black87,
                      ),
                    ),
                  ),
                  if (_gpsError != null)
                    TextButton(
                      onPressed: _getLocation,
                      child: const Text(
                        'Reintentar',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Botón publicar
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _publish,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.location_pin, color: Colors.white),
                label: Text(
                  _loading ? 'Publicando...' : 'Publicar sitio',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.joviRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
