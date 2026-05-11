import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    final result = await _firestore
        .collection('users')
        .where('displayName', isEqualTo: username)
        .get();
    return result.docs.isEmpty;
  }

  // Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult(success: true, user: result.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        errorMessage: _getSpanishErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Error inesperado. Por favor, inténtalo de nuevo.',
      );
    }
  }

  // Register with email and password
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Final check for username availability
      if (!await isUsernameAvailable(displayName)) {
        return AuthResult(
          success: false,
          errorMessage: 'El nombre artístico ya está en uso.',
        );
      }

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await result.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      if (result.user != null) {
        await _createUserDocument(result.user!, displayName, email.trim());
      }

      return AuthResult(success: true, user: result.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        errorMessage: _getSpanishErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Error inesperado. Por favor, inténtalo de nuevo.',
      );
    }
  }

  // Helper to create user doc
  Future<void> _createUserDocument(User user, String displayName, String email) async {
    await _firestore.collection('users').doc(user.uid).set({
      'displayName': displayName,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'points': 0,
      'level': 'Aprendiz de AR',
      'followers': 0,
      'following': 0,
      'bio': 'Nuevo en ARte',
    });

    await _firestore.collection('notifications').add({
      'userId': user.uid,
      'type': 'welcome',
      'message': '¡Bienvenido a ARte! Comienza tu aventura creativa.',
      'fromUser': 'system',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Change password (requires re-authentication)
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        return AuthResult(success: false, errorMessage: 'Usuario no autenticado.');
      }

      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        errorMessage: _getSpanishErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Error al cambiar la contraseña: $e',
      );
    }
  }

  // Reset password
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult(
        success: true,
        errorMessage: 'Correo de recuperación enviado. Revisa tu bandeja.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        errorMessage: _getSpanishErrorMessage(e.code),
      );
    }
  }

  // Delete account (requires re-authentication)
  Future<AuthResult> deleteAccount({required String currentPassword}) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        return AuthResult(success: false, errorMessage: 'Usuario no autenticado.');
      }

      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      
      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();
      
      // Delete user from Auth
      await user.delete();

      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        errorMessage: _getSpanishErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Error al eliminar la cuenta: $e',
      );
    }
  }

  // Get Spanish error messages
  String _getSpanishErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo electrónico.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo electrónico.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Por favor, inténtalo más tarde.';
      case 'operation-not-allowed':
        return 'Operación no permitida.';
      case 'invalid-credential':
        return 'Credenciales inválidas. Verifica tu correo y contraseña.';
      default:
        return 'Error de autenticación. Por favor, inténtalo de nuevo.';
    }
  }
}

// Auth result class
class AuthResult {
  final bool success;
  final User? user;
  final String? errorMessage;

  AuthResult({
    required this.success,
    this.user,
    this.errorMessage,
  });
}


