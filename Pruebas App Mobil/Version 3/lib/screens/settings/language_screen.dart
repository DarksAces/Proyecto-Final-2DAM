import 'package:flutter/material.dart';
import '../../services/settings_service.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService();
    final languages = [
      {'name': "Español (ES)", 'code': 'es'},
      {'name': "English (US)", 'code': 'en'},
      {'name': "Français (FR)", 'code': 'fr'},
      {'name': "Deutsch (DE)", 'code': 'de'},
      {'name': "Italiano (IT)", 'code': 'it'},
    ];

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Idioma"),
            centerTitle: true,
          ),
          body: ListView.builder(
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final lang = languages[index];
              final isSelected = settings.locale.languageCode == lang['code'];
              return ListTile(
                title: Text(lang['name']!),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.red) : null,
                onTap: () {
                  settings.setLanguage(lang['code']!);
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }
}
