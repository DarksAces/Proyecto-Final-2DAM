// lib/api_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Modelo de datos para el nuevo sitio a subir
class NewStopData {
  final String title;
  final String author;
  final String type;
  final double lat;
  final double lng;
  final File imageFile;
  final String authorId; // <--- Debe estar aquí

  NewStopData({
    required this.title,
    required this.author,
    required this.type,
    required this.lat,
    required this.lng,
    required this.imageFile,
    required this.authorId, // <--- Debe estar aquí
  });
}

// Lógica de comunicación con Firebase
class ApiService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  // 1. GESTIÓN DEL NICKNAME ÚNICO (TRANSACCIONAL)
  
  // Verifica y reserva un nickname de forma atómica. Devuelve un mensaje de error si falla, o null si tiene éxito.
  Future<String?> checkAndRegisterNickname(String nickname, String userId, {bool isUpdate = false}) async {
    final normalizedNickname = nickname.toLowerCase();
    final nicknameRef = _firestore.collection('usernames').doc(normalizedNickname);

    try {
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(nicknameRef);

        if (doc.exists) {
          final existingUserId = doc.data()?['userId'];
          // Si no es una actualización, o si otro usuario tiene el nombre, falla
          if (!isUpdate || existingUserId != userId) {
            throw StateError('NicknameAlreadyTaken');
          }
        }

        // Reservamos el nickname
        transaction.set(nicknameRef, {
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      
      return null; // Éxito

    } on StateError catch (e) {
      if (e.message == 'NicknameAlreadyTaken') {
        return 'El nickname "$nickname" ya está en uso.';
      }
      return 'Error desconocido al verificar el nickname.';
    } on FirebaseException catch (e) {
      return 'Error de Firebase: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  // Elimina el registro del nickname de la colección 'usernames'
  Future<void> deleteNicknameRegistration(String nickname) async {
    final normalizedNickname = nickname.toLowerCase();
    await _firestore.collection('usernames').doc(normalizedNickname).delete();
  }
  
  // 2. GESTIÓN DEL CONTENIDO (SITIOS)

  // Sube el sitio (imagen a Storage y metadatos a Firestore)
  Future<bool> uploadNewStop(NewStopData stopData) async {
    try {
      if (!await stopData.imageFile.exists()) {
        print('❌ ERROR: El archivo de imagen no existe');
        return false;
      }
      
      final fileName = 'stop_photos/${DateTime.now().millisecondsSinceEpoch}-${stopData.title.replaceAll(' ', '_')}.jpg';
      final fileRef = _storage.ref().child(fileName);
      
      await fileRef.putFile(stopData.imageFile);
      final imageUrl = await fileRef.getDownloadURL();

      // Subir los metadatos a Firestore
      await _firestore.collection('sitios').add({
        'title': stopData.title,
        'author': stopData.author,
        'authorId': stopData.authorId, // 💡 UID para seguridad
        'type': stopData.type,
        'lat': stopData.lat,
        'lng': stopData.lng,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('🎉 SUBIDA COMPLETADA EXITOSAMENTE');
      return true;

    } on FirebaseException catch (e) {
      print('🚨 ERROR DE FIREBASE: ${e.message}');
      // Las subidas fallidas se reanudarán automáticamente si la red se recupera.
      return false;
      
    } catch (e) {
      print('🚨 ERROR GENÉRICO: $e');
      return false;
    }
  }

  // 💡 NUEVO MÉTODO: Eliminar Sitio (Documento y Archivo de Storage)
  Future<String?> deleteStop(String sitioId, String authorId, String imageUrl) async {
    final user = _auth.currentUser;
    if (user == null) return "Usuario no autenticado.";

    final sitioRef = _firestore.collection('sitios').doc(sitioId);

    try {
      // La regla de seguridad de Firestore debe asegurar que user.uid == authorId
      if (user.uid != authorId) {
        return "No tienes permiso para eliminar este sitio.";
      }
      
      // Eliminar la imagen de Firebase Storage
      final storageRef = _storage.refFromURL(imageUrl);
      await storageRef.delete();
      print('✅ Imagen eliminada de Storage.');

      // Eliminar el documento de Firestore
      await sitioRef.delete();
      print('✅ Documento de sitio eliminado.');
      
      return null; // Éxito

    } on FirebaseException catch (e) {
      return 'Error de Firebase al eliminar: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }
}