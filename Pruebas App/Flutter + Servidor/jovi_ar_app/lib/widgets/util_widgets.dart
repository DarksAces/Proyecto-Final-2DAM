// lib/widgets/util_widgets.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../main.dart'; // Para JoviTheme

// ==========================================
// WIDGETS DE UTILIDAD
// ==========================================

// 🖼️ PANTALLA PARA VER LA IMAGEN EN GRANDE
class FullScreenImageScreen extends StatelessWidget {
  final String imageUrl;
  final String title;

  const FullScreenImageScreen({super.key, required this.imageUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(color: JoviTheme.yellow),
          ),
          errorWidget: (context, url, error) => const Icon(
            Icons.error,
            color: JoviTheme.red
          ),
        ),
      ),
    );
  }
}

class MyAnnotationClickListener implements OnCircleAnnotationClickListener {
  final Function(CircleAnnotation) onTap;
  MyAnnotationClickListener({required this.onTap});
  @override
  void onCircleAnnotationClick(CircleAnnotation annotation) {
    onTap(annotation);
  }
}