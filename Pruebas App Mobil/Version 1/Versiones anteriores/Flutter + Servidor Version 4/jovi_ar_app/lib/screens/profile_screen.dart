import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../main.dart';
import '../api_service.dart';
import 'settings_screen.dart';
import 'users_list_screen.dart';

// ==========================================
// 6. PERFIL (CON CLICS EN NÚMEROS)
// ==========================================

class ProfileScreen extends StatefulWidget {
  final VoidCallback onSignOut;
  const ProfileScreen({super.key, required this.onSignOut});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _followController = TextEditingController();
  final String myUid = FirebaseAuth.instance.currentUser!.uid;

  void _followUserDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Seguir Usuario"),
        content: TextField(
          controller: _followController,
          decoration: const InputDecoration(labelText: "Nickname", hintText: "Ej: explorador99", prefixIcon: Icon(LucideIcons.search)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: JoviTheme.blue, foregroundColor: Colors.white),
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop(); 

              if (_followController.text.isNotEmpty) {
                final error = await _apiService.followUser(_followController.text);
                messenger.showSnackBar(SnackBar(
                  content: Text(error == null ? "✅ Siguiendo a ${_followController.text}" : "❌ $error"),
                  backgroundColor: error == null ? Colors.green : Colors.red,
                ));
                _followController.clear();
              }
            },
            child: const Text("Seguir"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(myUid).snapshots(),
      builder: (context, snapshot) {
        
        List<String> followers = [];
        List<String> following = [];

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          followers = List<String>.from(data['followers'] ?? []);
          following = List<String>.from(data['following'] ?? []);
        }

        return Scaffold(
          appBar: AppBar(title: const Text("Mi Perfil"), actions: [
            IconButton(icon: const Icon(LucideIcons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())))
          ]),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(radius: 50, backgroundColor: JoviTheme.blue, child: Icon(LucideIcons.user, size: 50, color: Colors.white)),
                const SizedBox(height: 10),
                Text(user?.displayName ?? "Usuario", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(user?.email ?? "", style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem("Seguidores", followers, context),
                    Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.5)),
                    _buildStatItem("Seguidos", following, context),
                  ],
                ),
                const SizedBox(height: 30),

                ElevatedButton.icon(
                  onPressed: _followUserDialog,
                  icon: const Icon(LucideIcons.userPlus),
                  label: const Text("Buscar y Seguir"),
                  style: ElevatedButton.styleFrom(backgroundColor: JoviTheme.yellow, foregroundColor: JoviTheme.blue, minimumSize: const Size(double.infinity, 50)),
                ),
                const SizedBox(height: 15),
                ListTile(
                  leading: const Icon(LucideIcons.logOut, color: Colors.red),
                  title: const Text("Cerrar Sesión"),
                  onTap: widget.onSignOut,
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildStatItem(String label, List<String> list, BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UsersListScreen(title: label, userIds: list))
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          Text(list.length.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: JoviTheme.blue)),
          Text(label, style: const TextStyle(color: Colors.grey, decoration: TextDecoration.underline)),
        ]),
      ),
    );
  }
}
