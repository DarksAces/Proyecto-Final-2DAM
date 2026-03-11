import 'package:flutter/material.dart';
import 'capture_screen.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _startNewSession() async {
    setState(() => _isLoading = true);
    try {
      final session = await _apiService.createSession("New Capture");
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CaptureScreen(session: session),
        ),
      );
    } catch (e) {
      if (mounted) showSnackBar(context, "Error creating session: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Object Capture 3D')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, size: 100, color: Colors.grey),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _startNewSession,
                    icon: const Icon(Icons.add),
                    label: const Text('New Capture Session'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
