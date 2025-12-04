import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../main.dart';
import '../api_service.dart';

// ==========================================
// 4. PANTALLA GALERÍA
// ==========================================

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: const Text("Mi Galería"), backgroundColor: JoviTheme.yellow),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('sitios').where('authorId', isEqualTo: user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          final count = docs.length;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: count >= 5 ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(count >= 5 ? LucideIcons.alertTriangle : LucideIcons.checkCircle, color: count >= 5 ? Colors.red : Colors.green),
                    const SizedBox(width: 10),
                    Expanded(child: Text("Has usado $count/5 espacios.", style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: data['imageUrl'], fit: BoxFit.cover)),
                        Positioned(
                          top: 5, right: 5,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => ApiService().deleteStop(docs[index].id, user.uid, data['imageUrl']),
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
