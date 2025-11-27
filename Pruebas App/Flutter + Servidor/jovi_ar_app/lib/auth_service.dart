// lib/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'api_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService(); 

  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  // 1. INICIAR SESIÓN (Se mantiene)
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

  // 2. REGISTRARSE (CON VERIFICACIÓN DE UNICIDAD)
  Future<String?> registerWithEmailAndPassword(String email, String password, String nickname) async {
    UserCredential? result;
    
    // Paso 1: Intentar crear la cuenta de Auth
    try {
      result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      return e.message; 
    } 
    
    final user = result!.user;
    if (user == null) return "Error inesperado al crear usuario.";

    // Paso 2: Verificar si el nickname está disponible y registrarlo en Firestore
    final nicknameError = await _apiService.checkAndRegisterNickname(nickname, user.uid);

    if (nicknameError != null) {
        // Si el nickname está tomado, borramos la cuenta de Firebase Auth recién creada
        await user.delete(); 
        await _auth.signOut(); 
        return nicknameError; 
    }

    // Paso 3: Si tiene éxito, actualizar el displayName en Firebase Auth
    await user.updateDisplayName(nickname);
    print("✅ Registro exitoso y nickname único guardado: $nickname");
    
    return null; // Null significa éxito
  }

  // 3. CERRAR SESIÓN (Se mantiene)
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print("🚪 Sesión cerrada correctamente.");
    } catch (e) {
      print("❌ Error al cerrar sesión: $e");
    }
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

  // 5. ELIMINAR CUENTA (NUEVO MÉTODO)
  Future<String?> deleteAccount(String nickname) async {
    final user = _auth.currentUser;
    if (user == null) return "Usuario no autenticado.";

    try {
      // 1. Eliminar el registro del nickname de Firestore
      await _apiService.deleteNicknameRegistration(nickname);

      // 2. Eliminar la cuenta de Firebase Auth (esto cierra la sesión)
      await user.delete();
      
      print("🗑️ Cuenta y registro de nickname eliminados.");
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