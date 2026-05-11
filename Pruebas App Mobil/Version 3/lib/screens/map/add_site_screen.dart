import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';


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

  Future<void> _getLocation() async {
    setState(() { _gpsLoading = true; _gpsError = null; });
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() { _gpsLoading = false; _gpsError = AppLocalizations.of(context)!.add_site_gps_off; });
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() { _gpsLoading = false; _gpsError = AppLocalizations.of(context)!.add_site_perm_denied; });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      setState(() { _lat = pos.latitude; _lng = pos.longitude; _gpsLoading = false; });
    } catch (e) {
      setState(() { _gpsLoading = false; _gpsError = AppLocalizations.of(context)!.add_site_gps_error; });
    }

  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1200);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.add_site_img_err)));
      return;
    }

    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.add_site_gps_err)));
      return;
    }


    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      String imageUrl = '';

      // Upload to Storage
      final storageRef = FirebaseStorage.instance.ref().child('sitios/${user!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(_imageFile!);
      imageUrl = await storageRef.getDownloadURL();

      // Get Username
      String username = user.displayName ?? 'Artista';
      try {
        final uDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        username = uDoc.data()?['username'] ?? uDoc.data()?['displayName'] ?? username;
      } catch (_) {}

      // Save to Firestore
      await FirebaseFirestore.instance.collection('sitios').add({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'imageUrl': imageUrl,
        'latitude': _lat,
        'longitude': _lng,
        'status': 'pending_review',
        'userId': user.uid,
        'username': username,
        'timestamp': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'type': 'site',
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: SafeArea(
              top: false, // AppBar already handles top
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImagePicker(),
                      const SizedBox(height: 32),
                      _buildSectionTitle(AppLocalizations.of(context)!.add_site_section_details),

                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _titleCtrl,
                        label: AppLocalizations.of(context)!.add_site_proj_title,
                        hint: AppLocalizations.of(context)!.add_site_proj_hint,
                        icon: Icons.edit_note_rounded,
                        validator: (v) => v!.isEmpty ? AppLocalizations.of(context)!.add_site_title_err : null,
                      ),

                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _descCtrl,
                        label: AppLocalizations.of(context)!.add_site_desc,
                        hint: AppLocalizations.of(context)!.add_site_desc_hint,

                        icon: Icons.description_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle(AppLocalizations.of(context)!.add_site_section_geo),

                      const SizedBox(height: 16),
                      _buildGPSCard(),
                      const SizedBox(height: 40),
                      _buildSubmitButton(),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(AppLocalizations.of(context)!.add_site_new_title, style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w900, fontSize: 18)),

        centerTitle: true,
        background: Container(color: Colors.white),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: AppTheme.arteRed, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5));
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: () => _showImageSourceOptions(),
      child: Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black12, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        clipBehavior: Clip.antiAlias,
        child: _imageFile != null
            ? Image.file(_imageFile!, fit: BoxFit.cover)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppTheme.arteRed.withAlpha(10), shape: BoxShape.circle),
                    child: const Icon(Icons.add_a_photo_rounded, color: AppTheme.arteRed, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.add_site_upload_capture, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(AppLocalizations.of(context)!.add_site_gallery_hint, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),

                ],
              ),
      ),
    );
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.add_site_select_source, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(Icons.camera_alt_rounded, AppLocalizations.of(context)!.add_site_camera, () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
                  _buildSourceOption(Icons.photo_library_rounded, AppLocalizations.of(context)!.add_site_gallery, () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),

                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFFF0F0FF), borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: const Color(0xFF6C63FF), size: 30),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, required IconData icon, int maxLines = 1, String? Function(String?)? validator}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildGPSCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lat != null ? const Color(0xFF4CAF50).withAlpha(50) : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: (_lat != null ? Colors.green : Colors.grey).withAlpha(20), shape: BoxShape.circle),
            child: Icon(_lat != null ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded, color: _lat != null ? Colors.green : Colors.grey, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_lat != null ? AppLocalizations.of(context)!.add_site_coords_fixed : AppLocalizations.of(context)!.add_site_searching_signal, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: _lat != null ? Colors.green : Colors.grey)),
                const SizedBox(height: 2),
                Text(_lat != null ? "${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}" : AppLocalizations.of(context)!.add_site_stay_clear, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              ],

            ),
          ),
          if (_gpsError != null) IconButton(onPressed: _getLocation, icon: const Icon(Icons.refresh_rounded, color: AppTheme.arteRed)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(colors: [AppTheme.arteRed, Color(0xFFFF4D4D)]),
        boxShadow: [BoxShadow(color: AppTheme.arteRed.withAlpha(60), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ElevatedButton(
        onPressed: _loading ? null : _publish,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : Text(AppLocalizations.of(context)!.add_site_submit, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),

      ),
    );
  }
}
