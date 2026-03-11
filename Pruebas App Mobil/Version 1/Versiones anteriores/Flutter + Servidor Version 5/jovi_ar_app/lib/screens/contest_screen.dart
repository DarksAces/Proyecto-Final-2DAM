import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart'; // ApiService para votos
import '../main.dart'; // Para JoviTheme
import 'upload_contest_screen.dart'; // Importar pantalla de subida

/// Pantalla del Concurso de Fotografía.
///
/// Muestra una galería de fotos subidas por los estudiantes para el concurso.
/// Permite:
/// - Ver las fotos en detalle.
/// - Votar por las fotos favoritas (Sistema de Likes).
/// - Subir una nueva participación.
class ContestScreen extends StatefulWidget {
  const ContestScreen({super.key});

  @override
  State<ContestScreen> createState() => _ContestScreenState();
}

class _ContestScreenState extends State<ContestScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final ApiService _apiService = ApiService();
  bool isLoading = true;
  String? userSchool;
  String? userClassId;
  bool isEducational = false;
  String sortMode = 'latest'; // 'latest' | 'popular'
  String? selectedClassFilter; // 'all' (default) | actual class ID
  bool? isGlobalMode; // null = not selected yet
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // ==========================================
  // CARGA DE PERFIL DE USUARIO
  // ==========================================

  // Obtiene los datos del usuario actual (colegio, clase) para determinar qué concurso mostrar.
  // Si tiene colegio -> isEducational = true
  // Si no tiene colegio -> isGlobalMode = true (fallback a concurso general)
  Future<void> _loadUserProfile() async {
    if (currentUserId.isEmpty) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          userSchool = data['school'];
          userClassId = data['classId'];
          
          if (userSchool != null && userSchool!.isNotEmpty) {
             isEducational = true;
             // Si tiene colegio, mostramos el diálogo de elección forzando isGlobalMode a null
             // para disparar el popup en el build().
             isGlobalMode = null; 
          } else {
             isEducational = false;
             isGlobalMode = true; // Automáticamente global si no tiene cole
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error cargando perfil: $e");
      setState(() {
        isLoading = false;
        isGlobalMode = true; // Fallback ante error
      });
    }
  }

  // ==========================================
  // LÓGICA DE SELECCIÓN DE MODO (COLEGIO/GLOBAL)
  // ==========================================

  // Muestra un diálogo modal obligando al alumno a elegir qué feed ver.
  void _showModeSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Elige una categoría"),
        content: Text("Perteneces al colegio $userSchool.\n¿Qué concurso quieres ver?"),
        actions: [
          TextButton(
            onPressed: () {
               setState(() => isGlobalMode = true);
               Navigator.pop(ctx);
            },
            child: const Text("Ver Concurso Global (Todos)"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => isGlobalMode = false);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: JoviTheme.blue, foregroundColor: Colors.white),
            child: const Text("Ver Mi Colegio"),
          )
        ],
      )
    );
  }

  // ==========================================
  // QUERY DE FIRESTORE (FILTRADO)
  // ==========================================

  // Construye la query para obtener las fotos del concurso.
  // Aplica filtros dinámicos basados en la selección del usuario.
  Stream<QuerySnapshot> _getContestStream() {
    Query query = FirebaseFirestore.instance.collection('contest_entries');
    query = query.where('status', isEqualTo: 'approved');

    // FILTRO PRINCIPAL
    // Si NO estamos en modo global (es decir, modo colegio), filtramos por colegio.
    // Si estamos en modo global, NO filtramos por colegio (ver todos).
    if (isGlobalMode == false && userSchool != null) {
       query = query.where('school', isEqualTo: userSchool);
    }

    // Ordenación: Por popularidad (Likes) o Recientes
    if (sortMode == 'popular') {
      query = query.orderBy('likes', descending: true);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: JoviTheme.yellow)));
    }
    
    // Si el usuario es de colegio y aún no ha elegido modo, mostramos diálogo
    // Usamos addPostFrameCallback para evitar errores de renderizado durante build.
    if (isEducational && isGlobalMode == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) _showModeSelectionDialog();
      });
      // Mientras elige, mostramos carga o vacío
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: JoviTheme.yellow)));
    }

    bool showingSchool = isGlobalMode == false;

    return Scaffold(
      backgroundColor: JoviTheme.gray,
      appBar: AppBar(
        title: Text(
          showingSchool ? "Concurso Escolar" : "Concurso Global",
          style: JoviTheme.fontBaloo,
        ),
        backgroundColor: JoviTheme.yellow,
        foregroundColor: JoviTheme.blue,
        actions: [
          // Botón para cambiar de modo si tienes colegio
          if (isEducational)
            IconButton(
               icon: const Icon(LucideIcons.arrowRightLeft),
               onPressed: () {
                 setState(() => isGlobalMode = null); // Resetea para mostrar diálogo de nuevo
               },
               tooltip: "Cambiar Categoría",
            )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getContestStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error al cargar obras"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: JoviTheme.yellow));
          }

          var allDocs = snapshot.data?.docs ?? [];
          var displayDocs = List<QueryDocumentSnapshot>.from(allDocs);

          // Obtener clases disponibles dinámicamente
          Set<String> availableClasses = {};
          if (isEducational) {
            for (var doc in allDocs) {
              final d = doc.data() as Map<String, dynamic>;
              if (d['classId'] != null && d['classId'].toString().isNotEmpty) {
                availableClasses.add(d['classId'].toString());
              }
            }
          }
          List<String> sortedClasses = availableClasses.toList()..sort();

          // Filtrado adicional en cliente
          if (isEducational) {
             if (selectedClassFilter != null && selectedClassFilter != 'all') {
                displayDocs = displayDocs.where((d) => d['classId'] == selectedClassFilter).toList();
             }
          } else {
             displayDocs = displayDocs.where((d) => d['school'] == null || d['school'] == '').toList();
          }

          return Column(
            children: [
              // Header info
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEducational 
                        ? "Tu Clase: $userClassId ($userSchool)" 
                        : "Participando en la categoría Global/Local",
                      style: JoviTheme.fontPoppins.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (isEducational)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            const Text("Ver: ", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: (selectedClassFilter != null && sortedClasses.contains(selectedClassFilter) || selectedClassFilter == 'all') 
                                  ? selectedClassFilter ?? 'all'
                                  : 'all',
                              items: [
                                const DropdownMenuItem(value: 'all', child: Text("Todo el colegio")),
                                // Mostrar todas las clases disponibles en el colegio
                                ...sortedClasses.map((c) => DropdownMenuItem(
                                  value: c, 
                                  child: Text("Clase $c")
                                )),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  selectedClassFilter = val;
                                });
                              },
                              isDense: true,
                              underline: Container(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),

              if (displayDocs.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      isEducational
                        ? "No hay obras para mostrar."
                        : "No hay obras en el concurso global aún.",
                      textAlign: TextAlign.center,
                      style: JoviTheme.fontBaloo.copyWith(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8,
                    ),
                    itemCount: displayDocs.length,
                    itemBuilder: (context, index) {
                      final data = displayDocs[index].data() as Map<String, dynamic>;
                      final bool isMyEntry = data['authorId'] == currentUserId;

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Image.network(
                                data['imageUrl'] ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (_,__,___) => Container(color: Colors.grey[300]),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['title'] ?? 'Sin Título',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          data['author'] ?? 'Anónimo',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Botón de Like
                                  GestureDetector(
                                    onTap: () async {
                                      if (isMyEntry) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("No puedes votar tu propia obra"), duration: Duration(seconds: 1)),
                                        );
                                        return;
                                      }
                                      await _apiService.toggleContestVote(displayDocs[index].id, currentUserId);
                                    },
                                    child: Column(
                                      children: [
                                        Icon(
                                          (data['likedBy'] is List && (data['likedBy'] as List).contains(currentUserId))
                                              ? Icons.favorite
                                              : (isMyEntry ? Icons.favorite_border_outlined : Icons.favorite_border),
                                          color: isMyEntry ? Colors.grey : Colors.red, // Gris si es mía
                                          size: 24,
                                        ),
                                        // ELIMINADO: Contador de likes
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navegar a pantalla de subida de concurso
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => UploadContestEntryScreen(
              school: isEducational ? userSchool : null,
              classId: isEducational ? userClassId : null,
            )
          ));
        },
        backgroundColor: JoviTheme.blue,
        icon: const Icon(LucideIcons.upload, color: Colors.white),
        label: const Text("Subir Obra", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
