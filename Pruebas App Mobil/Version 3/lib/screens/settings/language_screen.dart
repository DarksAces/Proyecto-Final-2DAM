import 'package:flutter/material.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languages = [
      "Español (ES)",
      "English (US)",
      "Français (FR)",
      "Deutsch (DE)",
      "Italiano (IT)",
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Idioma"),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: languages.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(languages[index]),
            trailing:
                index == 0 ? const Icon(Icons.check, color: Colors.red) : null,
            onTap: () => Navigator.pop(context),
          );
        },
      ),
    );
  }
}
