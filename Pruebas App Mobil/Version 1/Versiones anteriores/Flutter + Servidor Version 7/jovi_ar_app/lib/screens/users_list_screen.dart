import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

// ==========================================
// 5. NUEVA PANTALLA: LISTA DE USUARIOS (SEGUIDORES/SEGUIDOS)
// ==========================================
class UsersListScreen extends StatelessWidget {
  final String title;
  final List<String> userIds;

  const UsersListScreen({super.key, required this.title, required this.userIds});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: JoviTheme.yellow,
        foregroundColor: JoviTheme.blue,
      ),
      body: userIds.isEmpty
          ? const Center(child: Text("La lista está vacía."))
          : ListView.builder(
              itemCount: userIds.length,
              itemBuilder: (context, index) {
                final uid = userIds[index];
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const ListTile(title: Text("Cargando..."));
                    
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final nickname = data?['nickname'] ?? data?['email'] ?? "Usuario Desconocido";

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: JoviTheme.blue,
                        child: Text(nickname.isNotEmpty ? nickname[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(nickname, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data?['email'] ?? ""),
                    );
                  },
                );
              },
            ),
    );
  }
}
