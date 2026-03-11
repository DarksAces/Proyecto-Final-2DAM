// lib/api_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Modelo de datos para transferir la información de un nuevo sitio a subir.
// Se utiliza tanto para paradas normales como para concursos.
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

/// Servicio principal para la interacción con Firebase Firestore y Storage.
/// 
/// Gestiona:
/// - CRUD de Sitios (Puntos de interés)
/// - Sistema de Seguidores (Social)
/// - Concursos y Votaciones
/// - Moderación de contenido (Admin/AI)
class ApiService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  // ==========================================
  // 1. GESTIÓN DE SEGUIDORES (SISTEMA INSTAGRAM)
  // ==========================================

  // Seguir a un usuario por nickname.
  // Utiliza una TRANSACCIÓN para asegurar que ambas listas (followers/following) 
  // se actualicen simultáneamente o ninguna lo haga, evitando inconsistencias.
  Future<String?> followUser(String targetNickname) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return "No estás autenticado";

    final normalizedNick = targetNickname.toLowerCase().trim();

    try {
      // 1. Buscar el UID del usuario objetivo en la colección 'usernames'
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

  // Dejar de seguir a un usuario.
  // También usa transacción para eliminar los UIDs de ambos arrays de forma atómica.
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

  // Obtener lista de gente a la que SIGO (para el Feed Social y Mapa).
  // Se usa para filtrar qué marcadores mostrar en el mapa o qué fotos en el feed.
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
  
  // Asigna el UID del usuario actual a sitios que no tienen autor.
  // Útil si se subieron datos en versiones anteriores de la app sin auth.
  // Usa WRITE BATCH para realizar múltiples escrituras de una sola vez (más eficiente).
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

  // REPARAR SITIOS SIN ESTATUS (MIGRACIÓN)
  // Establece un estado por defecto 'pending_review' para sitios antiguos.
  Future<int> repairNullStatusSites() async {
    final snapshot = await _firestore.collection('sitios').get();
    WriteBatch batch = _firestore.batch();
    int count = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      // Si no tienen status, les ponemos 'pending_review' por defecto
      if (data['status'] == null) {
        batch.update(doc.reference, {
          'status': 'pending_review',
          'appealCount': 0 // Inicializamos esto también por si acaso
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
  
  // Registra un nickname asegurando que sea único globalmente.
  // 1. Normaliza a minúsculas.
  // 2. Intenta leer el documento en 'usernames/nickname'.
  // 3. Si existe y es de otro usuario -> Error.
  // 4. Si no, lo crea apuntando al UID.
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
    // Count aggregation query es más barato y rápido que traerse todos los docs
    final query = await _firestore.collection('sitios').where('authorId', isEqualTo: user.uid).count().get();
    return query.count ?? 0;
  }

  // Sube un nuevo sitio:
  // 1. Sube la imagen a Firebase Storage.
  // 2. Obtiene la URL de descarga.
  // 3. Crea el documento en Firestore con la URL y coordenadas.
  Future<bool> uploadNewStop(NewStopData stopData) async {
    try {
      if (!await stopData.imageFile.exists()) return false;
      
      // Nombre de archivo único basado en timestamp
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
        'status': 'pending_review', // Estados: pending_review, ai_approved, ai_denied, approved, denied, appeal_pending
        'appealCount': 0,
      });
      return true;
    } catch (e) {
      print('Error subida: $e');
      return false;
    }
  }

  // NUEVO: Subida para el CONCURSO (Colección separada)
  // Similar a uploadNewStop pero apunta a 'contest_entries'.
  // Incluye campos extra para el filtrado escolar (school, classId).
  Future<bool> uploadContestEntry(NewStopData data, {String? school, String? classId}) async {
    try {
      if (!await data.imageFile.exists()) return false;
      
      final fileName = 'contest_photos/${DateTime.now().millisecondsSinceEpoch}-${data.authorId}.jpg';
      final fileRef = _storage.ref().child(fileName);
      
      await fileRef.putFile(data.imageFile);
      final imageUrl = await fileRef.getDownloadURL();

      await _firestore.collection('contest_entries').add({
        'title': data.title,
        'author': data.author,
        'authorId': data.authorId,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'school': school,   // Puede ser null (Global)
        'classId': classId, // Puede ser null
        'likes': 0,         // Votación
        'likedBy': [],      // Array de UIDs que han votado
        'status': 'approved', // Por defecto aprobado para simplificar flujo, o pending
        // Ubicación para fase local pública
        'lat': data.lat, 
        'lng': data.lng,
      });
      return true;
    } catch (e) {
      print('Error subida concurso: $e');
      return false;
    }
  }

  // Votar una obra del concurso (Toggle).
  // Usa transacción para evitar condiciones de carrera (ej. likes negativos o dobles votos).
  Future<void> toggleContestVote(String entryId, String userId) async {
    final docRef = _firestore.collection('contest_entries').doc(entryId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final data = snapshot.data();
        if (data == null) return;
        
        // Obtenemos lista actual de votantes (seguro ante nulls)
        final List<dynamic> likedByDynamic = data['likedBy'] ?? [];
        final List<String> likedBy = likedByDynamic.map((e) => e.toString()).toList();

        if (likedBy.contains(userId)) {
          // Si ya votó -> Quitamos voto
          transaction.update(docRef, {
            'likes': FieldValue.increment(-1),
            'likedBy': FieldValue.arrayRemove([userId])
          });
        } else {
          // Si no votó -> Añadimos voto
          transaction.update(docRef, {
            'likes': FieldValue.increment(1),
            'likedBy': FieldValue.arrayUnion([userId])
          });
        }
      });
    } catch (e) {
      print("Error al votar: $e");
    }
  }

  Future<String?> deleteStop(String sitioId, String authorId, String imageUrl) async {
    final user = _auth.currentUser;
    if (user == null) return "Usuario no autenticado.";
    if (user.uid != authorId) return "No tienes permiso.";

    try {
      // 1. Intentamos borrar la imagen (no bloqueante si falla)
      try {
         final storageRef = _storage.refFromURL(imageUrl);
         await storageRef.delete();
      } catch(e) { print("Error borrando imagen: $e"); }

      // 2. Borramos el documento
      await _firestore.collection('sitios').doc(sitioId).delete();
      return null;
    } catch (e) {
      return 'Error: $e';
    }
  }

  // ==========================================
  // 5. BORRADO TOTAL (CLEANUP)
  // ==========================================

  // Borrar TODOS los sitios de un usuario.
  // Iterativo: busca todos los docs del autor y los borra uno a uno.
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

  // ==========================================
  // 6. GESTIÓN DE APROBACIONES (ADMIN/AI)
  // ==========================================

  /// Obtiene sitios que requieren revisión (AI Approved/Denied o Pending)
  /// Utiliza 'whereIn' para traer varios estados a la vez.
  Stream<QuerySnapshot> getSitesForReview() {
     // Traemos los que están en 'pending_review', 'ai_approved', 'ai_denied', 'appeal_pending'
     // Firestore 'whereIn' soporta hasta 10 valores.
     return _firestore.collection('sitios')
        .where('status', whereIn: ['pending_review', 'ai_approved', 'ai_denied', 'appeal_pending'])
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Acción de validar manualmente (Desktop/Admin Panel)
  Future<void> reviewSite(String siteId, String newStatus, {String? denialReason}) async {
    // newStatus debería ser 'approved' o 'denied'
    Map<String, dynamic> updateData = {
      'status': newStatus,
      'reviewedAt': FieldValue.serverTimestamp(),
    };
    
    if (newStatus == 'denied' && denialReason != null) {
      updateData['denialReason'] = denialReason;
    }

    // SI ES DENEGADO Y YA TENÍA APELACIÓN, O SI EL USUARIO YA APELÓ UNA VEZ...
    // La regla es: "Permite apelar una vez, si ya ha apelado y se ha denegado se borra toda info"
    if (newStatus == 'denied') {
       final doc = await _firestore.collection('sitios').doc(siteId).get();
       final appealCount = doc.data()?['appealCount'] ?? 0;
       
       if (appealCount >= 1) {
         // Ya apeló y se le deniega de nuevo -> BORRAR DEFINITIVAMENTE
         final imageUrl = doc.data()?['imageUrl'];
         await deleteStop(siteId, doc.data()?['authorId'], imageUrl);
         return; 
       }
    }

    await _firestore.collection('sitios').doc(siteId).update(updateData);
  }

  /// Acción del Usuario para Apelar una denegación.
  /// Incrementa el contador de apelaciones para evitar spam.
  Future<String?> appealSite(String siteId, String reason) async {
    try {
      final doc = await _firestore.collection('sitios').doc(siteId).get();
      final currentAppealCount = doc.data()?['appealCount'] ?? 0;

      if (currentAppealCount >= 1) {
        return "Ya has agotado tu oportunidad de apelación.";
      }

      await _firestore.collection('sitios').doc(siteId).update({
        'status': 'appeal_pending',
        'appealCount': FieldValue.increment(1),
        'appealReason': reason,
        'appealedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return "Error al apelar: $e";
    }
  }

  // Simulación de AI (Para pruebas de UI).
  // En producción esto lo haría una Cloud Function con Vision API.
  Future<void> simulateAIProcess(String siteId, bool approve) async {
    await _firestore.collection('sitios').doc(siteId).update({
      'status': approve ? 'ai_approved' : 'ai_denied',
      'aiProcessedAt': FieldValue.serverTimestamp(),
    });
  }
}
