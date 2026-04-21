import 'dart:async';

class SimulationService {
  // Singleton Pattern
  static final SimulationService _instance = SimulationService._internal();
  factory SimulationService() => _instance;
  SimulationService._internal();

  // Search Event Stream
  final _searchController = StreamController<String>.broadcast();
  Stream<String> get searchEvents => _searchController.stream;

  void triggerSearch(String query) {
    _searchController.add(query);
  }

  /// Placeholder for simulation logic (currently disabled for clean production)
  Future<void> initSimulation() async {
    // Logic removed as per cleanup requirements
  }
}
