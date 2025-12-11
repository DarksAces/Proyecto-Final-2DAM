import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../api_service.dart';
import '../main.dart'; // For JoviTheme

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Administración"),
        backgroundColor: JoviTheme.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _apiService.getSitesForReview(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay sitios pendientes de revisión."));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final siteId = docs[index].id;
              final status = data['status'] ?? 'pending_review';
              
              Color statusColor = Colors.grey;
              if (status == 'ai_approved') statusColor = Colors.green[300]!;
              if (status == 'ai_denied') statusColor = Colors.red[300]!;
              if (status == 'appeal_pending') statusColor = Colors.orange;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: data['imageUrl'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (c, u) => Container(height: 200, color: Colors.grey[200]),
                          errorWidget: (c, u, e) => Container(height: 200, color: Colors.grey, child: const Icon(Icons.error)),
                        ),
                        Positioned(
                          top: 10, right: 10,
                          child: Chip(
                            label: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                            backgroundColor: statusColor,
                          ),
                        )
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['title'] ?? 'Sin Título', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("Por: ${data['author'] ?? 'Anon'}", style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 10),
                          if (status == 'appeal_pending')
                            Container(
                               padding: const EdgeInsets.all(8),
                               decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                               child: Text("📝 Razón de Apelación: ${data['appealReason']}", style: const TextStyle(color: Colors.orange)),
                            ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _ActionButton(
                                icon: LucideIcons.check,
                                label: "APROBAR",
                                color: Colors.green,
                                onTap: () => _handleDecision(siteId, 'approved'),
                              ),
                              _ActionButton(
                                icon: LucideIcons.x,
                                label: "DENEGAR",
                                color: Colors.red,
                                onTap: () => _handleDenial(siteId),
                              ),
                            ],
                          ),
                          const Divider(),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            children: [
                               TextButton(
                                onPressed: () => _apiService.simulateAIProcess(siteId, true),
                                child: const Text("Simular AI: Aprobar"),
                              ),
                              TextButton(
                                onPressed: () => _apiService.simulateAIProcess(siteId, false),
                                child: const Text("Simular AI: Denegar", style: TextStyle(color: Colors.red)),
                              ),
                            ]
                          )
                        ],
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
  }

  void _handleDecision(String siteId, String status) async {
    await _apiService.reviewSite(siteId, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sitio movido a $status")));
    }
  }

  void _handleDenial(String siteId) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text("Denegar Sitio"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: "Razón (Opcional)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
               await _apiService.reviewSite(siteId, 'denied', denialReason: reasonController.text);
               if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sitio denegado.")));
               }
            },
            child: const Text("Confirmar Denegación"),
          )
        ],
      )
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
