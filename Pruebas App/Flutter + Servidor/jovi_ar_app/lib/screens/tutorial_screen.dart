import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../main.dart';
import '../settings_service.dart';

class TutorialScreen extends StatefulWidget {
  final VoidCallback onDone;
  final String userId;
  const TutorialScreen({super.key, required this.onDone, required this.userId});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      "title": "¡Bienvenido a Jovi AR!",
      "desc": "Explora el mundo y descubre lugares increíbles escondidos a tu alrededor.",
      "icon": LucideIcons.map,
      "color": JoviTheme.blue,
    },
    {
      "title": "Realidad Aumentada",
      "desc": "Usa la cámara para escanear y encontrar objetos ocultos en el mundo real.",
      "icon": LucideIcons.scanLine,
      "color": JoviTheme.red,
    },
    {
      "title": "Comparte y Descubre",
      "desc": "Sube tus propios descubrimientos y sigue a otros exploradores.",
      "icon": LucideIcons.users,
      "color": JoviTheme.yellow,
    },
  ];

  void _finishTutorial() async {
    await SettingsService().setTutorialShown(widget.userId);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: page['color'].withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page['icon'], size: 80, color: page['color']),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page['title'],
                          style: JoviTheme.fontBaloo.copyWith(fontSize: 28, fontWeight: FontWeight.bold, color: JoviTheme.blue),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          page['desc'],
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) => 
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index ? JoviTheme.blue : Colors.grey.withOpacity(0.3),
                  ),
                )
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JoviTheme.yellow,
                    foregroundColor: JoviTheme.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                    } else {
                      _finishTutorial();
                    }
                  },
                  child: Text(
                    _currentPage == _pages.length - 1 ? "¡COMENZAR!" : "SIGUIENTE",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
