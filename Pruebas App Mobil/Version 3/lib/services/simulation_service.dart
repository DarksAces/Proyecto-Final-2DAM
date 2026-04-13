import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';

class SimulationService {
  // Singleton Pattern
  static final SimulationService _instance = SimulationService._internal();
  factory SimulationService() => _instance;
  SimulationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Search Event Stream
  final _searchController = StreamController<String>.broadcast();
  Stream<String> get searchEvents => _searchController.stream;

  void triggerSearch(String query) {
    _searchController.add(query);
  }

  // Fake users data
  final List<Map<String, dynamic>> _fakeUsersData = [
    {
      'displayName': 'María García',
      'bio': 'Artista digital y amante del AR 🎨',
      'level': 'Creador Experto',
      'avatarColor': 0xFFE91E63,
    },
    {
      'displayName': 'Carlos Ruiz',
      'bio': 'Escultor 3D | Futurist',
      'level': 'Maestro AR',
      'avatarColor': 0xFF2196F3,
    },
    {
      'displayName': 'Ana López',
      'bio': 'Exploradora urbana 🌍',
      'level': 'Explorador',
      'avatarColor': 0xFF4CAF50,
    },
    {
      'displayName': 'David Chen',
      'bio': 'Fotógrafo de realidades mixtas',
      'level': 'Visionario',
      'avatarColor': 0xFFFF9800,
    },
    {
      'displayName': 'Sofia K.',
      'bio': 'Diseñadora de filtros',
      'level': 'Estrella en ascenso',
      'avatarColor': 0xFF9C27B0,
    },
  ];

  final List<Map<String, dynamic>> _botProfiles = [
    {
      'username': 'DragonMaster',
      'displayName': 'Dragon Master',
      'avatarUrl': null,
      'bio': 'Maestro de la escultura AR.',
      'avatarColor': 0xFFE91E63,
    },
    {
      'username': 'CosmicExplorer',
      'displayName': 'Cosmic Explorer',
      'avatarUrl': null,
      'bio': 'Explorando lo desconocido.',
      'avatarColor': 0xFF2196F3,
    },
    {
      'username': 'NatureCollector',
      'displayName': 'Nature Collector',
      'avatarUrl': null,
      'bio': 'Coleccionista de bytes naturales.',
      'avatarColor': 0xFF4CAF50,
    },
  ];

  // Fake post contents
  final List<String> _postContents = [
    '¡Acabo de dejar una escultura increíble en el parque central! 🌳✨ #AuraAR',
    'Creando nuevos filtros para el concurso de esta semana. ¿Qué opinan? 🤔',
    '¡Encontré un easter egg oculto en el mapa! 🥚🗺️',
    'Mi galería está creciendo. ¡Gracias por el apoyo! ❤️',
    'Probando los nuevos pinceles de neón. ¡Son brutales! 🖌️🔥',
    '¿Alguien para salir a cazar arte este fin de semana? 🚶‍♂️🎨',
  ];

  // Fake post images
  final List<String> _postImages = [
    'https://picsum.photos/seed/ar1/600/400',
    'https://picsum.photos/seed/ar2/600/400',
    'https://picsum.photos/seed/ar3/600/400',
    'https://picsum.photos/seed/ar4/600/400',
    'https://picsum.photos/seed/ar5/600/400',
  ];

  // Fake locations
  final List<String> _locations = [
    'Barrio Gótico, Barcelona',
    'Parque del Retiro, Madrid',
    'Plaza Mayor, Madrid',
    'Jardines de Sabatini',
    'Museo del Prado',
    'Casa Batlló, Barcelona',
  ];

  /// Initialize simulation: Create demo data if collections are empty
  Future<void> initSimulation() async {
    try {
      // Check 'sitios'
      final QuerySnapshot snapshot = await _firestore
          .collection('sitios')
          .where('status', isEqualTo: 'accepted')
          .get();
      if (snapshot.docs.length < 3) {
        debugPrint('🤖 Simulation: Seeding demo content...');
        await _seedDemoContent();
      }

      // Check 'products' - Seed if empty or few products (ensuring our new Aura list is there)
      final prodSnapshot = await _firestore
          .collection('products')
          .limit(10)
          .get();
      if (prodSnapshot.docs.length < 5) {
        debugPrint('🤖 Simulation: Seeding shop products (Aura Catalog)...');
        await _seedProducts();
      }

      // Check 'users'
      final usersSnapshot = await _firestore.collection('users').limit(1).get();
      if (usersSnapshot.docs.isEmpty) {
        debugPrint('🤖 Simulation: Seeding fake users...');
        for (var userData in [..._fakeUsersData, ..._botProfiles]) {
          await _createBotUser(userData);
        }
      }

      // Cleanup problematic data as requested by user
      await _cleanupProblematicData();
    } catch (e) {
      debugPrint('❌ Simulation Error: $e');
    }
  }

  Future<void> _cleanupProblematicData() async {
    debugPrint('🧹 Simulation: Cleaning up problematic content...');
    // Scan users
    final users = await _firestore.collection('users').get();
    for (var doc in users.docs) {
      final data = doc.data();
      final name = (data['displayName'] ?? '').toString().toLowerCase();
      final bio = (data['bio'] ?? '').toString().toLowerCase();

      if (name.contains('chocpo') ||
          name.contains('sexu') ||
          bio.contains('chocpo') ||
          bio.contains('sexu')) {
        debugPrint('🗑️ Deleting problematic user: ${doc.id}');
        await doc.reference.delete();
      }
    }

    // Scan sitios (posts)
    // Scan sitios (posts)
    debugPrint('🧹 Simulation: Thorough cleanup of problematic content...');
    final terms = ['chocpo', 'sexu', 'chico sexu', 'chico'];
    final collections = [
      'users',
      'sitios',
      'contest_entries',
      'notifications',
      'products',
    ];

    for (var colName in collections) {
      try {
        final snapshot = await _firestore.collection(colName).get();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          bool shouldDelete = false;

          data.forEach((key, value) {
            if (value != null) {
              final valStr = value.toString().toLowerCase();
              for (var term in terms) {
                if (valStr.contains(term)) {
                  shouldDelete = true;
                  break;
                }
              }
            }
          });

          if (shouldDelete) {
            debugPrint('🗑️ Deleting problematic doc from $colName: ${doc.id}');
            await doc.reference.delete();
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error cleaning $colName: $e');
      }
    }
  }

  Future<void> _seedDemoContent() async {
    final List<Map<String, dynamic>> premiumPosts = [
      {
        'username': 'DragonMaster',
        'userTitle': 'Escultor AR Maestro',
        'userAvatarColor': 0xFFE91E63,
        'userDegree': '1º',
        'content':
            '¡El Fénix de Cristal ha renacido en el centro! 🏙️✨ #AR #CrystalPhoenix',
        'imageUrl':
            'https://images.unsplash.com/photo-1614850523296-d8c1af93d400?q=80&w=1000&auto=format&fit=crop',
        'isVideo': false,
        'location': 'Plaza de Cibeles, Madrid',
        'latitude': 40.4193,
        'longitude': -3.6931,
        'status': 'accepted',
        'badge': 'AR DISCOVERY',
        'likes': 142,
        'comments': 12,
        'shares': 5,
        'isBot': true,
        'timestamp': FieldValue.serverTimestamp(),
      },
      {
        'username': 'CosmicExplorer',
        'userTitle': 'Explorador Visionario',
        'userAvatarColor': 0xFF2196F3,
        'userDegree': '2º',
        'content':
            'Encontré un portal interdimensional en el museo. 🌌🌀 #AuraAR #Mystery',
        'imageUrl':
            'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?q=80&w=1000&auto=format&fit=crop',
        'isVideo': false,
        'location': 'Museo del Prado, Madrid',
        'latitude': 40.4137,
        'longitude': -3.6921,
        'status': 'accepted',
        'badge': 'LIVE EXPERIENCE',
        'likes': 328,
        'comments': 45,
        'shares': 18,
        'isBot': false,
        'timestamp': FieldValue.serverTimestamp(),
      },
      {
        'username': 'NatureCollector',
        'userTitle': 'Biólogo Digital',
        'userAvatarColor': 0xFF4CAF50,
        'userDegree': '1º',
        'content':
            'La selva bioluminiscente sobre el puente. 🌿💡 #NatureAR #Magic',
        'imageUrl':
            'https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?q=80&w=1000&auto=format&fit=crop',
        'isVideo': true,
        'videoDuration': '0:45',
        'reproCount': '12.4k',
        'location': 'Puente de Segovia, Madrid',
        'latitude': 40.4133,
        'longitude': -3.7226,
        'status': 'accepted',
        'badge': 'AR DISCOVERY',
        'likes': 856,
        'comments': 92,
        'shares': 42,
        'isBot': false,
        'timestamp': FieldValue.serverTimestamp(),
      },
      {
        'username': 'CyberArt',
        'userTitle': 'Cyber Runner',
        'userAvatarColor': 0xFFFF9800,
        'userDegree': '3º',
        'content':
            'Estructura de datos flotante detectada. 🧪📉 #Cyberpunk #DataArt',
        'imageUrl':
            'https://images.unsplash.com/photo-1550745165-9bc0b252726f?q=80&w=1000&auto=format&fit=crop',
        'isVideo': true,
        'videoDuration': '0:15',
        'reproCount': '5.1k',
        'location': 'Gran Vía, Madrid',
        'latitude': 40.4199,
        'longitude': -3.7025,
        'status': 'accepted',
        'badge': 'LIVE EXPERIENCE',
        'likes': 215,
        'comments': 28,
        'shares': 12,
        'isBot': true,
        'timestamp': FieldValue.serverTimestamp(),
      },
    ];

    for (var post in premiumPosts) {
      await _firestore.collection('sitios').add(post);
    }

    // Also seed some contest entries
    for (var post in premiumPosts) {
      await _firestore.collection('contest_entries').add({
        'title': post['content'].split('!')[0],
        'description': post['content'],
        'imageUrl': post['imageUrl'],
        'artistName': post['username'],
        'status': 'accepted',
        'likes': post['likes'],
        'timestamp': FieldValue.serverTimestamp(),
        'schoolId': 'demo_school_1',
        'scope': 'Global',
      });
    }
  }

  Future<void> _seedProducts() async {
    final List<Map<String, dynamic>> products = [
      {
        'title': 'Plastilina Aura - Pack 10 Pastillas Surtidas (50g)',
        'rating': 4.9,
        'reviews': 3200,
        'price': '5,45€',
        'oldPrice': '8,50€',
        'discount': '-36%',
        'tag': 'TOP VENTAS',
        'subTag': 'MEJOR VALORADO',
        'imageUrl':
            'https://images.unsplash.com/photo-1513364776144-60967b0f800f?q=80&w=800&auto=format&fit=crop',
        'isRedButton': true,
        'category': 'Plastilina',
        'description':
            'Plastilina vegetal de gran plasticidad. No endurece al aire, es reutilizable y muy fácil de moldear. Ideal para el desarrollo de la motricidad fina.',
      },
      {
        'title': 'Pintura de Dedos Aura - Pack 5 Botes Fluorescentes',
        'rating': 4.7,
        'reviews': 1200,
        'price': '12,99€',
        'oldPrice': '18,50€',
        'discount': '-30%',
        'tag': 'OFERTA',
        'subTag': 'AR READY',
        'imageUrl':
            'https://images.unsplash.com/photo-1547826039-bfc35e0f1ea8?q=80&w=800&auto=format&fit=crop',
        'isRedButton': true,
        'category': 'Pintura',
        'description':
            'Pintura de dedos ideal para los más pequeños. Colores vivos y mezclables. Se lava fácilmente de manos y ropa.',
      },
      {
        'title': 'Témpera Líquida Aura - Set 6 Botellas Brillantes',
        'rating': 4.8,
        'reviews': 850,
        'price': '8,90€',
        'oldPrice': '12,00€',
        'discount': '-25%',
        'tag': 'NUEVO',
        'subTag': 'CREATIVITY KIT',
        'imageUrl':
            'https://images.unsplash.com/photo-1513364776144-60967b0f800f?q=80&w=800&auto=format&fit=crop', // Reuse or use specific
        'isRedButton': false,
        'category': 'Pintura',
        'description':
            'Témpera lista para usar. Gran cobertura y secado rápido. Perfecta para papel, cartón, madera y tela.',
      },
      {
        'title': 'Pasta de Modelar Aura Air Dry - Blanco 1kg',
        'rating': 5.0,
        'reviews': 2100,
        'price': '4,20€',
        'oldPrice': '6,50€',
        'discount': '-35%',
        'tag': 'IMPULSO',
        'subTag': 'SECADO AL AIRE',
        'imageUrl':
            'https://images.unsplash.com/photo-1560421683-6856ea585c78?q=80&w=800&auto=format&fit=crop',
        'isRedButton': true,
        'category': 'Plastilina',
        'description':
            'Pasta de modelar que se endurece al aire sin necesidad de cocción. Tacto fresco y agradable. Una vez seca se puede pintar.',
      },
      {
        'title': 'Ceras Oso Aura - 12 Colores Triangulares',
        'rating': 4.6,
        'reviews': 450,
        'price': '3,75€',
        'oldPrice': '5,00€',
        'discount': '-25%',
        'tag': null,
        'subTag': 'ERGO DESIGN',
        'imageUrl':
            'https://images.unsplash.com/photo-1513364776144-60967b0f800f?q=80&w=800&auto=format&fit=crop',
        'isRedButton': true,
        'category': 'Ceras',
        'description':
            'Ceras de colores con forma de oso, diseñadas para las manos más pequeñas. Colores intensos y resistentes.',
      },
      {
        'title': 'Acuarelas Aura - Estuche 24 Pastillas con Pincel',
        'rating': 4.9,
        'reviews': 980,
        'price': '7,50€',
        'oldPrice': '10,95€',
        'discount': '-31%',
        'tag': 'RECOMENDADO',
        'subTag': 'PREMIUM',
        'imageUrl':
            'https://images.unsplash.com/photo-1547826039-bfc35e0f1ea8?q=80&w=800&auto=format&fit=crop',
        'isRedButton': false,
        'category': 'Pintura',
        'description':
            'Acuarelas de alta calidad con gran concentración de pigmento. Incluye pincel sintético de gran suavidad.',
      },
    ];

    // Clean existing products first to ensure fresh demo data
    final existing = await _firestore.collection('products').get();
    for (var doc in existing.docs) {
      await doc.reference.delete();
    }

    for (var product in products) {
      await _firestore.collection('products').add({
        ...product,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _createBotUser(Map<String, dynamic> userData) async {
    await _firestore.collection('users').add({
      ...userData,
      'isBot': true,
      'createdAt': FieldValue.serverTimestamp(),
      'followers': _random.nextInt(500) + 50,
      'following': _random.nextInt(100) + 10,
      'points': _random.nextInt(5000) + 100,
    });
  }

  Future<void> _createBotPost() async {
    final botsQuery = await _firestore
        .collection('users')
        .where('isBot', isEqualTo: true)
        .get();
    if (botsQuery.docs.isEmpty) return;

    final randomBot = botsQuery.docs[_random.nextInt(botsQuery.docs.length)];
    final botData = randomBot.data();
    final content = _postContents[_random.nextInt(_postContents.length)];
    final image = _postImages[_random.nextInt(_postImages.length)];
    final location = _locations[_random.nextInt(_locations.length)];
    final isVideo = _random.nextDouble() < 0.3;

    await _firestore.collection('sitios').add({
      'userId': randomBot.id,
      'username': botData['displayName'],
      'userTitle': botData['bio'] ?? 'Explorador AR',
      'userAvatarColor': botData['avatarColor'],
      'userDegree': '${_random.nextInt(3) + 1}º',
      'content': content,
      'imageUrl': image,
      'isVideo': isVideo,
      'videoDuration': isVideo ? '0:${_random.nextInt(45) + 15}' : null,
      'location': location,
      'latitude': 40.4168 + (_random.nextDouble() - 0.5) * 0.01,
      'longitude': -3.7038 + (_random.nextDouble() - 0.5) * 0.01,
      'status': 'accepted',
      'badge': _random.nextBool() ? 'AR DISCOVERY' : 'LIVE EXPERIENCE',
      'likes': _random.nextInt(200),
      'comments': _random.nextInt(50),
      'shares': _random.nextInt(20),
      'reproCount': isVideo
          ? '${(_random.nextDouble() * 5).toStringAsFixed(1)}k'
          : null,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _generateNotificationForUser(String userId) async {
    final botsQuery = await _firestore
        .collection('users')
        .where('isBot', isEqualTo: true)
        .get();
    if (botsQuery.docs.isEmpty) return;

    final randomBot = botsQuery.docs[_random.nextInt(botsQuery.docs.length)];
    final botData = randomBot.data();
    final types = ['like', 'follow', 'comment', 'suggestion', 'new_post'];
    final type = types[_random.nextInt(types.length)];
    String message = '';

    switch (type) {
      case 'like':
        message = 'le gustó tu publicación reciente.';
        break;
      case 'follow':
        message = 'comenzó a seguirte.';
        break;
      case 'comment':
        message = 'comentó: "¡Genial! 🔥"';
        break;
      case 'suggestion':
        message = 'quizás conozcas a este artista AR.';
        break;
      case 'new_post':
        message = 'publicó una nueva obra: "Atardecer Cyberpunk"';
        break;
    }

    await _firestore.collection('notifications').add({
      'userId': userId,
      'type': type,
      'message': '${botData['displayName']} $message',
      'fromUser': randomBot.id,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
}
