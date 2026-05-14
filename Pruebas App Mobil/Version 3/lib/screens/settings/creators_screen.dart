import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class CreatorsScreen extends StatelessWidget {
  const CreatorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Creadores"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.groups_rounded, size: 60, color: AppTheme.arteRed),
            const SizedBox(height: 16),
            const Text(
              "El equipo detrás de ARte",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Proyecto Final 2º DAM\nInnovación y Realidad Aumentada",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // Equipo de desarrollo de ARte
            _CreatorCard(
              name: "Daniel García Brun",
              linkedinUrl: "https://www.linkedin.com/in/daniel-garcia-brun-98a54b274/",
              avatarColor: AppTheme.arteRed,
            ),
            const SizedBox(height: 20),
            _CreatorCard(
              name: "Eric Morales Roura",
              linkedinUrl: "https://www.linkedin.com/in/eric-morales-roura-a64a5b273/",
              avatarColor: AppTheme.arteBlue,
            ),
            const SizedBox(height: 20),
            _CreatorCard(
              name: "Daniel Zorita Fontanet",
              linkedinUrl: "https://www.linkedin.com/in/daniel-zorita-fontanet-968a482b4/",
              avatarColor: AppTheme.arteYellow,
            ),
            
            const SizedBox(height: 60),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              "© 2026 ARte Go. Todos los derechos reservados.",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorCard extends StatelessWidget {
  final String name;
  final String linkedinUrl;
  final Color avatarColor;

  const _CreatorCard({
    required this.name,
    required this.linkedinUrl,
    required this.avatarColor,
  });

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(linkedinUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: avatarColor.withOpacity(0.1),
            child: Text(
              name[0],
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: avatarColor),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _launchUrl,
              icon: const Icon(Icons.link, size: 18),
              label: const Text("LinkedIn"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077B5), // LinkedIn Color
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
