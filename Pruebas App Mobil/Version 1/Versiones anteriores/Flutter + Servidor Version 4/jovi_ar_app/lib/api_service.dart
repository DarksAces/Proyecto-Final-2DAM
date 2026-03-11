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
  final String authorId; // UID del creador

  NewStopData({
    required this.title,
    required this.author,
    required this.type,
    required this.lat,
    required this.lng,
    required this.imageFile,
    required this.authorId,
  });
}

class ApiService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  // ==========================================
  // 1. GESTIÓN DE SEGUIDORES (SISTEMA INSTAGRAM)
  // ==========================================

  // Seguir a un usuario por nickname
  Future<String?> followUser(String targetNickname) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return "No estás autenticado";

    final normalizedNick = targetNickname.toLowerCase().trim();

    try {
      // 1. Buscar el UID del usuario objetivo
      final usernameDoc = await _firestore.collection('usernames').doc(normalizedNick).get();
      
      if (!usernameDoc.exists) {
        return "El usuario '$targetNickname' no existe.";
      }

      final targetUid = usernameDoc.data()?['userId'];

      if (targetUid == currentUser.uid) {
        return "No puedes seguirte a ti mismo.";
      }

      // 2. Transacción para actualizar ambas listas
      final userRef = _firestore.collection('users').doc(currentUser.uid);
      final targetRef = _firestore.collection('users').doc(targetUid);

      await _firestore.runTransaction((transaction) async {
        // Añado al objetivo en mis "siguiendo" (following)
        transaction.set(userRef, {
          'following': FieldValue.arrayUnion([targetUid])
        }, SetOptions(merge: true));

        // Me añado a mí en sus "seguidores" (followers)
        transaction.set(targetRef, {
          'followers': FieldValue.arrayUnion([currentUser.uid])
        }, SetOptions(merge: true));
      });

      return null; // Éxito
    } catch (e) {
      return "Error al seguir: $e";
    }
  }

  // Dejar de seguir
  Future<String?> unfollowUser(String targetUid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return "Error auth";

    try {
      final userRef = _firestore.collection('users').doc(currentUser.uid);
      final targetRef = _firestore.collection('users').doc(targetUid);

      await _firestore.runTransaction((transaction) async {
        transaction.update(userRef, {
          'following': FieldValue.arrayRemove([targetUid])
        });
        transaction.update(targetRef, {
          'followers': FieldValue.arrayRemove([currentUser.uid])
        });
      });
      return null;
    } catch (e) {
      return "Error: $e";
    }
  }

  // Obtener lista de gente a la que SIGO (para el Feed Social y Mapa)
  Future<List<String>> getFollowingList() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    final doc = await _firestore.collection('users').doc(currentUser.uid).get();
    if (doc.exists && doc.data() != null && doc.data()!.containsKey('following')) {
      return List<String>.from(doc.data()!['following']);
    }
    return [];
  }

  // ==========================================
  // 2. HERRAMIENTA DE REPARACIÓN (AUTHOR ID)
  // ==========================================
  
  // ESTA ES LA FUNCIÓN QUE TE FALTABA Y DABA ERROR
  Future<int> asignarAutorASitiosHuerfanos() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final snapshot = await _firestore.collection('sitios').get();
    WriteBatch batch = _firestore.batch();
    int count = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      // Si no tiene authorId o está vacío
      if (data['authorId'] == null || data['authorId'] == "") {
        batch.update(doc.reference, {
          'authorId': user.uid,
          'author': user.displayName ?? 'Recuperado'
        });
        count++;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
    return count;
  }

  // ==========================================
  // 3. GESTIÓN DEL NICKNAME ÚNICO
  // ==========================================
  
  Future<String?> checkAndRegisterNickname(String nickname, String userId, {bool isUpdate = false}) async {
    final normalizedNickname = nickname.toLowerCase();
    final nicknameRef = _firestore.collection('usernames').doc(normalizedNickname);

    try {
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(nicknameRef);

        if (doc.exists) {
          final existingUserId = doc.data()?['userId'];
          if (!isUpdate || existingUserId != userId) {
            throw StateError('NicknameAlreadyTaken');
          }
        }

        transaction.set(nicknameRef, {
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      return null; 
    } on StateError catch (e) {
      if (e.message == 'NicknameAlreadyTaken') return 'El nickname "$nickname" ya está en uso.';
      return 'Error desconocido.';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  Future<void> deleteNicknameRegistration(String nickname) async {
    final normalizedNickname = nickname.toLowerCase();
    await _firestore.collection('usernames').doc(normalizedNickname).delete();
  }

  // ==========================================
  // 4. GESTIÓN DE SITIOS (CRUD)
  // ==========================================

  Future<int> getUserStopCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;
    final query = await _firestore.collection('sitios').where('authorId', isEqualTo: user.uid).count().get();
    return query.count ?? 0;
  }

  Future<bool> uploadNewStop(NewStopData stopData) async {
    try {
      if (!await stopData.imageFile.exists()) return false;
      
      final fileName = 'stop_photos/${DateTime.now().millisecondsSinceEpoch}-${stopData.title.replaceAll(' ', '_')}.jpg';
      final fileRef = _storage.ref().child(fileName);
      
      await fileRef.putFile(stopData.imageFile);
      final imageUrl = await fileRef.getDownloadURL();

      await _firestore.collection('sitios').add({
        'title': stopData.title,
        'author': stopData.author,
        'authorId': stopData.authorId, 
        'type': stopData.type,
        'lat': stopData.lat,
        'lng': stopData.lng,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error subida: $e');
      return false;
    }
  }

  Future<String?> deleteStop(String sitioId, String authorId, String imageUrl) async {
    final user = _auth.currentUser;
    if (user == null) return "Usuario no autenticado.";
    if (user.uid != authorId) return "No tienes permiso.";

    try {
      try {
         final storageRef = _storage.refFromURL(imageUrl);
         await storageRef.delete();
      } catch(e) { print("Error borrando imagen: $e"); }

      await _firestore.collection('sitios').doc(sitioId).delete();
      return null;
    } catch (e) {
      return 'Error: $e';
    }
  }

  // ==========================================
  // 5. BORRADO TOTAL (CLEANUP)
  // ==========================================

  // Borrar TODOS los sitios de un usuario
  Future<void> deleteAllUserSites(String uid) async {
    try {
      final snapshot = await _firestore.collection('sitios').where('authorId', isEqualTo: uid).get();
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final imageUrl = data['imageUrl'] as String?;

        // 1. Borrar imagen si existe
        if (imageUrl != null && imageUrl.isNotEmpty) {
           try {
             await _storage.refFromURL(imageUrl).delete();
           } catch(e) { print("Error limpieza imagen: $e"); }
        }

        // 2. Borrar documento
        await doc.reference.delete();
      }
      print("✅ Sitios de usuario $uid eliminados.");
    } catch (e) {
      print("❌ Error borrando sitios: $e");
    }
  }

  // Borrar perfil público
  Future<void> deleteUserProfile(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      print("✅ Perfil de usuario $uid eliminado.");
    } catch (e) {
      print("❌ Error borrando perfil: $e");
    }
  }
}