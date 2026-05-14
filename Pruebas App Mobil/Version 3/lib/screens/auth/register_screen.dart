import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_background.dart';
import '../../services/auth_service.dart';
import '../settings/language_screen.dart';
import '../../l10n/app_localizations.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Final check for username availability before submitting
    final isAvailable = await _authService.isUsernameAvailable(_nameController.text);
    if (!isAvailable) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre artístico ya está en uso. Elige otro.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await _authService.registerWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _nameController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Error al registrarse'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleAuthResult(AuthResult result) {
    if (!mounted) return;
    if (result.success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (result.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showComingSoon(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('El registro con $provider estará disponible próximamente.'),
        backgroundColor: AppTheme.arteBlue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final result = await _authService.signInWithGoogle();
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (result.errorMessage != 'Inicio de sesión cancelado.') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Error al registrarse con Google'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            // Header with Back Button
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: AppTheme.arteYellow,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(AppLocalizations.of(context)!.join_adventure,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.arteRed)),

                  )
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SizedBox(
                        height: 80,
                        width: 80,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Text(
                            "ARte",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.arteBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Center(
                      child: Text(AppLocalizations.of(context)!.create_account,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                    ),

                    const SizedBox(height: 5),
                    Center(
                      child: Text(AppLocalizations.of(context)!.explore_hidden,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),

                    const SizedBox(height: 40),

                    // Form with validation
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Inputs
                          _buildLabel(AppLocalizations.of(context)!.username),
                          TextFormField(
                            controller: _nameController,
                            maxLength: 10,
                            decoration: _inputDecoration(
                                AppLocalizations.of(context)!.username_hint, Icons.person_outline),

                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu nombre';
                              }
                              if (value.length < 3) {
                                return 'El nombre debe tener al menos 3 caracteres';
                              }
                              if (value.length > 10) {
                                return 'El nombre no puede tener más de 10 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          _buildLabel(AppLocalizations.of(context)!.email),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(
                                "creativo@ARte.es", Icons.email_outlined),

                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu email';
                              }
                              if (!value.contains('@')) {
                                return 'Ingresa un email válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          _buildLabel(AppLocalizations.of(context)!.password),
                          TextFormField(
                            controller: _passwordController,

                            obscureText: _obscurePassword,
                            decoration: _inputDecoration(
                                "........", Icons.lock_outline,
                                isPassword: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa una contraseña';
                              }
                              if (value.length < 8) {
                                return 'Debe tener al menos 8 caracteres';
                              }
                              if (!value.contains(RegExp(r'[A-Z]'))) {
                                return 'Debe incluir una mayúscula';
                              }
                              if (!value.contains(RegExp(r'[a-z]'))) {
                                return 'Debe incluir una minúscula';
                              }
                              if (!value.contains(RegExp(r'[0-9]'))) {
                                return 'Debe incluir un número';
                              }
                              if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                                return 'Debe incluir un carácter especial';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 40),

                          // Register Button
                          SizedBox(
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.arteRed,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                                elevation: 5,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(AppLocalizations.of(context)!.register_button,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white)),

                                        SizedBox(width: 8),
                                        Icon(Icons.brush,
                                            color: Colors.white, size: 20)
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                    Center(
                        child: Text(AppLocalizations.of(context)!.or_register_with,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey))),

                    const SizedBox(height: 20),

                    // Social Placeholders
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialButton(
                          Icons.g_mobiledata,
                          Colors.red.shade50,
                          onTap: _handleGoogleLogin,
                        ),
                        const SizedBox(width: 20),
                        _socialButton(
                          Icons.facebook,
                          AppTheme.arteBlue,
                          onTap: () => _showComingSoon("Facebook"),
                        ),
                        const SizedBox(width: 20),
                        _socialButton(
                          Icons.apple,
                          Colors.black,
                          onTap: () => _showComingSoon("Apple"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppLocalizations.of(context)!.already_have_account + " "),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/login'),
                          child: Text(
                            AppLocalizations.of(context)!.login_link,
                            style: const TextStyle(
                              color: AppTheme.arteBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )

                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 10),
      child: Text(text,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon,
      {bool isPassword = false}) {
    return InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.arteBlue.withValues(alpha: 0.5)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.remove_red_eye_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: AppTheme.arteBlue, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 15));
  }

  Widget _socialButton(IconData icon, Color bgColor, {VoidCallback? onTap}) {
    bool isLight = bgColor == Colors.red.shade50;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration:
            BoxDecoration(color: bgColor, shape: BoxShape.circle, boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 5,
              offset: const Offset(0, 3))
        ]),
        child: Icon(icon, color: isLight ? Colors.grey : Colors.white),
      ),
    );
  }
}
