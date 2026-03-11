import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../main.dart';

// ==========================================
// 2. PANTALLA SOCIAL (CON FOLLOWERS)
// ==========================================

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return const Center(child: Text("Debes iniciar sesión."));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, userSnapshot) {
        
        if (userSnapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator(color: JoviTheme.yellow));
        }

        List<dynamic> rawFollowing = [];
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          if (userData != null && userData.containsKey('following')) {
            rawFollowing = userData['following'];
          }
        }

        final List<String> followingIds = List<String>.from(rawFollowing);

        if (followingIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.users, size: 60, color: Colors.grey),
                const SizedBox(height: 20),
                const Text("No sigues a nadie aún.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                TextButton(
                  onPressed: () => DefaultTabController.of(context)?.animateTo(4),
                  child: const Text("Buscar gente para seguir", style: TextStyle(color: JoviTheme.blue))
                )
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Tus Seguidos"), 
            backgroundColor: JoviTheme.gray, 
            elevation: 0
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sitios')
                .where('authorId', whereIn: followingIds)
                .where('status', isEqualTo: 'approved') // SOLO APROBADOS
                .orderBy('createdAt', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, sitiosSnapshot) {
              if (sitiosSnapshot.hasError) {
                 return Center(
                   child: SingleChildScrollView(
                     padding: const EdgeInsets.all(16),
                     child: SelectableText(
                       "⚠️ ERROR DE FIREBASE:\n\n${sitiosSnapshot.error}",
                       style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                       textAlign: TextAlign.center,
                     ),
                   ),
                 );
              }
              if (sitiosSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: JoviTheme.yellow));
              }
              if (!sitiosSnapshot.hasData || sitiosSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Tus seguidos no han subido nada reciente."));
              }

              final docs = sitiosSnapshot.data!.docs;
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: JoviTheme.yellow, 
                            child: Text(data['author']?[0].toUpperCase() ?? '?')
                          ),
                          title: Text(data['author'] ?? 'Desconocido', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Descubrió: ${data['title']}"),
                        ),
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                          child: CachedNetworkImage(
                            imageUrl: data['imageUrl'],
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (c,u) => Container(height: 200, color: Colors.grey[200]),
                            errorWidget: (c,u,e) => Container(height: 200, color: Colors.grey, child: const Icon(Icons.error)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
