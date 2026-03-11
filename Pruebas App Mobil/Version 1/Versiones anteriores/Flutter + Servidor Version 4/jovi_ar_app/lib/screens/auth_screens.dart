// lib/screens/auth_screens.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../auth_service.dart';
import '../main.dart'; // Para JoviTheme
import 'package:firebase_auth/firebase_auth.dart'; // Para tipo User

// ==========================================
// PANTALLAS DE AUTENTICACIÓN
// ==========================================

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  void _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Introduce email y contraseña.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = await _auth.signInWithEmailAndPassword(
        _emailController.text, _passwordController.text);

    // CORRECCIÓN: Desactivar _isLoading después de la llamada.
    setState(() {
      _isLoading = false;
    });

    if (user == null) {
      setState(() {
        _errorMessage = "Error de credenciales. Intenta de nuevo.";
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JoviTheme.gray,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Jovi AR", style: JoviTheme.fontBaloo.copyWith(fontSize: 48, color: JoviTheme.blue)),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.mail),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.lock),
                ),
              ),
              const SizedBox(height: 30),

              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: JoviTheme.red)),
              const SizedBox(height: 10),

              _isLoading
                ? const CircularProgressIndicator(color: JoviTheme.yellow)
                : ElevatedButton(
                    onPressed: _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: JoviTheme.yellow,
                      foregroundColor: JoviTheme.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      textStyle: JoviTheme.fontBaloo.copyWith(fontSize: 20)
                    ),
                    child: const Text("INICIAR SESIÓN"),
                  ),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen())
                  );
                },
                child: Text("¿No tienes cuenta? Regístrate aquí.", style: TextStyle(color: JoviTheme.blue.withOpacity(0.7))),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  // 💡 CORRECCIÓN: Método declarado como async
  void _register() async { 
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nicknameController.text.isEmpty) {
      setState(() {
        _errorMessage = "Completa todos los campos.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 💡 registerWithEmailAndPassword ahora devuelve un String de error o null (éxito)
    final error = await _auth.registerWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
        _nicknameController.text
    );

    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      // Muestra el mensaje de error, que puede ser 'El nickname ya está en uso' o un error de Auth
      setState(() {
        _errorMessage = error;
      });
    } else {
      // Éxito: La navegación se gestiona por el StreamBuilder
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrarse"),
        backgroundColor: JoviTheme.yellow,
        foregroundColor: JoviTheme.blue,
      ),
      backgroundColor: JoviTheme.gray,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Crear Cuenta", style: JoviTheme.fontBaloo.copyWith(fontSize: 36, color: JoviTheme.blue)),
              const SizedBox(height: 40),

              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Nickname o Nombre de Usuario',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.user),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.mail),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña (mínimo 6 caracteres)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.lock),
                ),
              ),
              const SizedBox(height: 30),

              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: JoviTheme.red)),
              const SizedBox(height: 10),

              _isLoading
                ? const CircularProgressIndicator(color: JoviTheme.blue)
                : ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: JoviTheme.blue,
                      foregroundColor: JoviTheme.white,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      textStyle: JoviTheme.fontBaloo.copyWith(fontSize: 20)
                    ),
                    child: const Text("REGISTRARME"),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}