// lib/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'api_service.dart';

/// Servicio de Autenticación que envuelve FirebaseAuth y gestiona el registro de usuarios.
///
/// Responsabilidades:
/// - Iniciar/Cerrar sesión (Email/Password).
/// - Registro de usuarios con validación de unicidad de Nickname (via Firestore).
/// - Actualización de perfil y borrado de cuenta.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService(); 

  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  // 1. INICIAR SESIÓN
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      print("✅ Inicio de sesión exitoso: ${result.user!.email}");
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("❌ Error de inicio de sesión: ${e.message}");
      return null;
    } catch (e) {
      print("❌ Error desconocido: $e");
      return null;
    }
  }

  // 2. REGISTRARSE (CORREGIDO: AHORA GUARDA EL PERFIL PÚBLICO)
  Future<String?> registerWithEmailAndPassword(
      String email, String password, String nickname, 
      {String? school, String? classId}) async {
    UserCredential? result;
    
    // Paso 1: Crear usuario en Auth
    try {
      result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      return e.message; 
    } 
    
    final user = result!.user;
    if (user == null) return "Error inesperado al crear usuario.";

    // Paso 2: Verificar nickname único
    final nicknameError = await _apiService.checkAndRegisterNickname(nickname, user.uid);

    if (nicknameError != null) {
        // Si falla, borramos la cuenta creada para no dejar basura
        await user.delete(); 
        await _auth.signOut(); 
        return nicknameError; 
    }

    // Paso 3: Actualizar nombre en Auth (Interno)
    await user.updateDisplayName(nickname);

    // ✅ PASO 4 (NUEVO): Guardar ficha pública en Firestore
    // Esto es lo que faltaba para que la lista de seguidores vea el nombre
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'nickname': nickname,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'school': school, // Nuevo: Colegio
      'classId': classId, // Nuevo: Clase (e.g. 2ºA)
      'followers': [], // Inicializamos listas vacías
      'following': [],
    }, SetOptions(merge: true));

    print("✅ Registro exitoso y perfil público creado: $nickname");
    
    return null; // Null = Éxito
  }

  // 3. CERRAR SESIÓN
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("❌ Error al cerrar sesión: $e");
    }
  

  // ... (Puedes dejar el resto de funciones como updateNickname igual)
}

  // 4. ACTUALIZAR NICKNAME
  Future<String?> updateNickname(String newNickname) async {
    final user = _auth.currentUser;
    if (user == null) return "Usuario no autenticado.";
    final oldNickname = user.displayName ?? '';

    // 1. Verificar unicidad del nuevo nickname (isUpdate: true)
    final nicknameError = await _apiService.checkAndRegisterNickname(newNickname, user.uid, isUpdate: true);

    if (nicknameError != null) {
      return nicknameError; // Devuelve el error (ya en uso)
    }

    // 2. Eliminar el registro del nickname antiguo (si no está vacío)
    if (oldNickname.isNotEmpty) {
      await _apiService.deleteNicknameRegistration(oldNickname);
    }

    // 3. Actualizar el displayName en Firebase Auth
    await user.updateDisplayName(newNickname);
    return null; // Éxito
  }

  // 5. ELIMINAR CUENTA
  Future<String?> deleteAccount(String nickname) async {
    final user = _auth.currentUser;
    if (user == null) return "Usuario no autenticado.";

    try {
      // 1. Eliminar el registro del nickname de Firestore
      await _apiService.deleteNicknameRegistration(nickname);

      // 2. Limpieza PROFUNDA (Sitios + Perfil)
      await _apiService.deleteAllUserSites(user.uid);
      await _apiService.deleteUserProfile(user.uid);

      // 3. Eliminar la cuenta de Firebase Auth (esto cierra la sesión)
      await user.delete();
      
      print("🗑️ Cuenta y todos los datos eliminados.");
      return null; // Éxito

    } on FirebaseException catch (e) {
      if (e.code == 'requires-recent-login') {
        return "Requiere inicio de sesión reciente. Por seguridad, debes cerrar y volver a iniciar sesión antes de eliminar la cuenta.";
      }
      return "Error de Firebase al eliminar cuenta: ${e.message}";
    } catch (e) {
      return "Error inesperado: $e";
    }
  }
}