import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import 'nickname_bio_screen.dart';
import 'change_password_screen.dart';
import 'two_factor_screen.dart';
import 'language_screen.dart';
import 'legal_screens.dart';
import '../../services/settings_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';



class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isVisibleOnMap = true;
  bool _isGhostMode = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await _userService.getCurrentUserData();
    if (mounted) {
      setState(() {
        _userData = data;
        _isVisibleOnMap = data?['isVisibleOnMap'] ?? true;
        _isGhostMode = data?['isGhostMode'] ?? false;
        _isLoading = false;
      });
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'es': return 'Español';
      case 'en': return 'English';
      default: return code.toUpperCase();
    }

  }

  @override
  Widget build(BuildContext context) {

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.settings_title,
          style: GoogleFonts.outfit(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),

        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: SettingsService(),
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: _loadUserData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
              const SizedBox(height: 20),
              // Profile Header
              _buildProfileHeader(),
              const SizedBox(height: 30),

              // Sections
              _buildSection(
                "MI CUENTA",
                [
                  _buildSettingsTile(
                    icon: Icons.badge_outlined,
                    title: "Nickname y Bio",
                    subtitle: "Identidad pública en la red",
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              NicknameBioScreen(initialData: _userData),
                        ),
                      );
                      _loadUserData();
                    },
                  ),
                ],
              ),
              _buildSection(
                AppLocalizations.of(context)!.privacy.toUpperCase(),
                [
                  _buildSettingsTile(
                    icon: Icons.language,
                    title: AppLocalizations.of(context)!.language,
                    trailingText: _getLanguageName(SettingsService().locale.languageCode),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LanguageScreen())),
                  ),
                ],
              ),
              _buildSection(
                AppLocalizations.of(context)!.security,

                [
                  _buildSettingsTile(
                    icon: Icons.lock_outline,
                    title: "Cambiar Contraseña",
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen())),
                  ),
                ],
              ),
              

              _buildSection(
                "PRIVACIDAD",
                [
                  _buildSettingsTile(
                    icon: Icons.map_outlined,
                    title: "Visibilidad en Mapa",
                    trailing: Switch(
                      value: _isVisibleOnMap,
                      onChanged: (val) async {
                        setState(() => _isVisibleOnMap = val);
                        await _userService.updateUserData(
                            _userService.currentUserId!,
                            {'isVisibleOnMap': val});
                      },
                      activeColor: Colors.red,
                    ),
                  ),
                  _buildSettingsTile(
                    icon: Icons.blur_on,
                    title: "Modo Fantasma",
                    trailing: Switch(
                      value: _isGhostMode,
                      onChanged: (val) async {
                        setState(() => _isGhostMode = val);
                        await _userService.updateUserData(
                            _userService.currentUserId!, {'isGhostMode': val});
                      },
                      activeColor: Colors.red,
                    ),
                  ),
                ],
              ),

              _buildSection(
                "LEGAL Y SOPORTE",
                [
                  _buildSettingsTile(
                    title: "Términos de Servicio",
                    trailing: const Icon(Icons.open_in_new,
                        size: 20, color: Colors.grey),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TermsOfServiceScreen())),
                  ),
                  _buildSettingsTile(
                    title: "Política de Privacidad",
                    trailing: const Icon(Icons.open_in_new,
                        size: 20, color: Colors.grey),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyScreen())),
                  ),
                  _buildSettingsTile(
                    title: "Licencias de Software",
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SoftwareLicensesScreen())),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _authService.signOut();
                      if (mounted) {
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/auth', (route) => false);
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text("Cerrar Sesión",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.arteRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  final passwordController = TextEditingController();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Eliminar Cuenta"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                              "¿Estás seguro? Esta acción es IRREVERSIBLE. Por favor, confirma tu contraseña para continuar:"),
                          const SizedBox(height: 16),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Contraseña Actual",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("CANCELAR"),
                        ),
                        TextButton(
                          onPressed: () async {
                            if (passwordController.text.isEmpty) return;
                            
                            final result = await _authService.deleteAccount(
                              currentPassword: passwordController.text
                            );
                            
                            if (mounted) {
                              if (result.success) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/auth', (route) => false);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result.errorMessage ?? "Error al eliminar cuenta"),
                                    backgroundColor: Colors.red,
                                  )
                                );
                              }
                            }
                          },
                          child: const Text("ELIMINAR DEFINITIVAMENTE",
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  "Eliminar Cuenta permanentemente",
                  style: TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                "ARte v2.4.0 (Build 892) • ARte.es",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    },
  ),
);
}

  Widget _buildProfileHeader() {
    final String username =
        _userData?['displayName'] ?? _userData?['username'] ?? 'Explorador';
    final String subtitle = _userData?['userTitle'] ?? 'CREADOR AR';
    final int avatarColorValue = _userData?['avatarColor'] ?? 0xFFE30613;

    final String? photoUrl = _userData?['photoUrl'] ?? _userData?['avatarUrl'];

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.shade100, width: 2),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Color(avatarColorValue),
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                  ? Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          "@${username.replaceAll(' ', '_').toLowerCase()}",
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          subtitle,
          style: TextStyle(
              color: Colors.red.shade400,
              fontSize: 14,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => NicknameBioScreen(initialData: _userData)),
            );
            _loadUserData();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          ),
          child: const Text("Editar Perfil",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24, top: 20, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    IconData? icon,
    required String title,
    String? subtitle,
    Color? subtitleColor,
    String? trailingText,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: icon != null
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.red, size: 20),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                  color: subtitleColor ?? Colors.grey.shade500, fontSize: 12),
            )
          : null,
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText != null)
                Text(
                  trailingText,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
    );
  }
}
