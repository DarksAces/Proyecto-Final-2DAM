// lib/api_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Modelo de datos para el nuevo sitio a subir
class NewStopData {
  final String title;
  final String author;
  final String type;
  final double lat;
  final double lng;
  final File imageFile;

  NewStopData({
    required this.title,
    required this.author,
    required this.type,
    required this.lat,
    required this.lng,
    required this.imageFile,
  });
}

// Lógica de comunicación con Firebase
class ApiService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<bool> uploadNewStop(NewStopData stopData) async {
    try {
      print('🚀 INICIANDO SUBIDA...');
      print('📍 Ubicación: ${stopData.lat}, ${stopData.lng}');
      print('📝 Título: ${stopData.title}');
      print('📁 Archivo: ${stopData.imageFile.path}');
      
      // 1. Verificar que el archivo existe
      if (!await stopData.imageFile.exists()) {
        print('❌ ERROR: El archivo de imagen no existe');
        return false;
      }
      print('✅ Archivo verificado');

      // 2. Subir la imagen a Firebase Storage
      final fileName = 'stop_photos/${DateTime.now().millisecondsSinceEpoch}-${stopData.title.replaceAll(' ', '_')}.jpg';
      print('📤 Subiendo imagen a Storage: $fileName');
      
      final fileRef = _storage.ref().child(fileName);
      final uploadTask = fileRef.putFile(stopData.imageFile);
      
      // Monitorear el progreso
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('📊 Progreso: ${progress.toStringAsFixed(2)}%');
      });

      await uploadTask;
      print('✅ Imagen subida exitosamente');
      
      // 3. Obtener la URL de descarga
      final imageUrl = await fileRef.getDownloadURL();
      print('🔗 URL obtenida: $imageUrl');

      // 4. Subir los metadatos a Firestore
      print('💾 Guardando en Firestore...');
      final docRef = await _firestore.collection('sitios').add({
        'title': stopData.title,
        'author': stopData.author.isEmpty ? 'Anónimo' : stopData.author,
        'type': stopData.type,
        'lat': stopData.lat,
        'lng': stopData.lng,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Documento creado con ID: ${docRef.id}');
      print('🎉 SUBIDA COMPLETADA EXITOSAMENTE');
      return true;

    } on FirebaseException catch (e) {
      print('═══════════════════════════════════════');
      print('🚨 ERROR DE FIREBASE');
      print('═══════════════════════════════════════');
      print('Código: ${e.code}');
      print('Mensaje: ${e.message}');
      print('Plugin: ${e.plugin}');
      if (e.stackTrace != null) print('Stack: ${e.stackTrace}');
      print('═══════════════════════════════════════');
      
      // Ayuda según el error
      if (e.code == 'permission-denied') {
        print('💡 SOLUCIÓN: Configura las reglas de Firebase:');
        print('   Firestore: allow read, write: if true;');
        print('   Storage: allow read, write: if true;');
      } else if (e.code == 'network-request-failed') {
        print('💡 SOLUCIÓN: Verifica tu conexión a internet');
      }
      
      return false;
      
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════');
      print('🚨 ERROR GENÉRICO');
      print('═══════════════════════════════════════');
      print('Excepción: $e');
      print('Tipo: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      print('═══════════════════════════════════════');
      return false;
    }
  }
}