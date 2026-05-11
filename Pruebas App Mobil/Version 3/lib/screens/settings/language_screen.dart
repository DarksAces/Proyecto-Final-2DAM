import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../../l10n/app_localizations.dart';



class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService();
    final languages = [
      {'name': "Español (ES)", 'code': 'es'},
      {'name': "English (US)", 'code': 'en'},
    ];


    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.language),
            centerTitle: true,
          ),

          body: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: languages.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lang = languages[index];
              final isSelected = settings.locale.languageCode == lang['code'];
              return Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.red : Colors.grey.shade200,
                    width: 1.5,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Colors.red.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  title: Text(
                    lang['name']!,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.red : Colors.black87,
                    ),
                  ),
                  trailing: isSelected 
                    ? const Icon(Icons.check_circle, color: Colors.red) 
                    : const Icon(Icons.circle_outlined, color: Colors.grey),
                  onTap: () {
                    settings.setLanguage(lang['code']!);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        );
      },
    );

  }
}
