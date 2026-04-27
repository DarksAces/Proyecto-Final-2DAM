import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class SimulationService {
  // Singleton Pattern
  static final SimulationService _instance = SimulationService._internal();
  factory SimulationService() => _instance;
  SimulationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search Event Stream
  final _searchController = StreamController<String>.broadcast();
  Stream<String> get searchEvents => _searchController.stream;

  void triggerSearch(String query) {
    _searchController.add(query);
  }

  /// Initialize simulation: Only cleanup problematic data, no seeding
  Future<void> initSimulation() async {
    try {
      debugPrint('🤖 Simulation: Initializing clean environment...');
      // Cleanup problematic data as requested by user
      await _cleanupProblematicData();
    } catch (e) {
      debugPrint('❌ Simulation Error: $e');
    }
  }

  Future<void> _cleanupProblematicData() async {
    debugPrint('🧹 Simulation: Cleaning up problematic content...');
    
    // Terms to search for and delete
    final terms = ['chocpo', 'sexu', 'chico sexu', 'chico'];
    final collections = [
      'users',
      'sitios',
      'contest_entries',
      'notifications',
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
}
