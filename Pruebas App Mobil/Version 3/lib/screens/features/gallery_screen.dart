import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  String _selectedType = "Todo";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Column(
          children: [
            Text("Mi Galería", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("ARte Explorer",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Buscando en galería...")));
              },
              icon: const Icon(Icons.search, size: 28))
        ],
      ),
      body: Column(
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => _selectedType = "Todo"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _selectedType == "Todo" ? AppTheme.arteRed : null,
                  ),
                  child: const Text("Todo"),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                    onPressed: () {},
                    child: const Row(children: [
                      Text("Fecha "),
                      Icon(Icons.keyboard_arrow_down, size: 16)
                    ])),
                const SizedBox(width: 10),
                OutlinedButton(
                    onPressed: () => setState(() => _selectedType = "Video"),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _selectedType == "Video"
                          ? AppTheme.arteRed.withAlpha(30)
                          : null,
                    ),
                    child: const Row(children: [
                      Text("Video "),
                    ])),
                const SizedBox(width: 10),
                OutlinedButton(
                    onPressed: () {},
                    child: const Row(children: [
                      Text("Lugar "),
                      Icon(Icons.keyboard_arrow_down, size: 16)
                    ])),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Mis Creaciones",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Go back to Map/Home
                    },
                    child: const Text("VER MAPA",
                        style: TextStyle(
                            color: AppTheme.arteRed,
                            fontWeight: FontWeight.bold)))
              ],
            ),
          ),

          // Dynamic Grid from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sitios')
                  .where('isBot', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text("Error al cargar la galería"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                // Client-side filtering for demo simplicity
                final filteredDocs = _selectedType == "Todo"
                    ? docs
                    : docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (_selectedType == "Video")
                          return data['isVideo'] == true;
                        return true;
                      }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined,
                            size: 80, color: Colors.grey.withAlpha(100)),
                        const SizedBox(height: 10),
                        const Text("No tienes creaciones aún",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    final docId = filteredDocs[index].id;
                    return _GalleryCard(
                      title: data['content'] ?? "Sin título",
                      imageUrl: data['imageUrl'] ??
                          "https://picsum.photos/seed/$docId/600/600",
                      docId: docId,
                    );
                  },
                );
              },
            ),
          ),

          // Cloud Storage Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Espacio en la Nube",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("64%",
                        style: TextStyle(
                            color: AppTheme.arteRed,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 0.64,
                    minHeight: 15,
                    backgroundColor: Colors.grey.shade300,
                    color: AppTheme.arteRed,
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                    child: Text(
                        "\"Tus recuerdos AR están a salvo en ARte Cloud\"",
                        style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                            fontSize: 12)))
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _GalleryCard extends StatefulWidget {
  final String title;
  final String imageUrl;
  final String docId;

  const _GalleryCard({
    required this.title,
    required this.imageUrl,
    required this.docId,
  });

  @override
  State<_GalleryCard> createState() => _GalleryCardState();
}

class _GalleryCardState extends State<_GalleryCard> {
  bool _showOverlay = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showOverlay = !_showOverlay),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
              image: NetworkImage(widget.imageUrl), fit: BoxFit.cover),
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withAlpha(200),
                        Colors.transparent
                      ])),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: AppTheme.arteYellow, shape: BoxShape.circle),
                child: const Icon(Icons.center_focus_weak, size: 20),
              ),
            ),
            Positioned(
              bottom: 15,
              left: 15,
              right: 15,
              child: Text(
                widget.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            if (_showOverlay)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(100),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Eliminar Obra"),
                              content: const Text(
                                  "¿Estás seguro de que quieres eliminar esta creación de tu galería?"),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("No")),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text("Sí, eliminar")),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await FirebaseFirestore.instance
                                .collection('sitios')
                                .doc(widget.docId)
                                .delete();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Obra eliminada")));
                            }
                          }
                        },
                        child: const CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 25,
                            child: Icon(Icons.delete, color: AppTheme.arteRed)),
                      ),
                      const SizedBox(width: 15),
                      const CircleAvatar(
                          backgroundColor: AppTheme.arteRed,
                          radius: 25,
                          child: Icon(Icons.share, color: Colors.white)),
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
