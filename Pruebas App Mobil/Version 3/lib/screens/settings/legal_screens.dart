import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Términos de Servicio", style: GoogleFonts.outfit()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("1. Aceptación de los Términos"),
            _buildSectionBody(
                "Al descargar y utilizar ARte, aceptas cumplir con estos términos. Si no estás de acuerdo, por favor no utilices la plataforma."),
            _buildSectionTitle("2. Uso de Realidad Aumentada"),
            _buildSectionBody(
                "El usuario es el único responsable del uso de la tecnología AR en entornos físicos. No debes utilizar la aplicación mientras conduces o en lugares donde pongas en riesgo tu seguridad o la de terceros."),
            _buildSectionTitle("3. Contenido del Usuario"),
            _buildSectionBody(
                "Conservas los derechos de autor sobre el arte AR que crees. Sin embargo, al publicarlo en ARte, nos otorgas una licencia mundial para mostrarlo y promocionarlo dentro de la red social."),
            _buildSectionTitle("4. Conducta Prohibida"),
            _buildSectionBody(
                "No se permite contenido ofensivo, violento o que infrinja la propiedad intelectual. Nos reservamos el derecho de eliminar cualquier contenido que viole estas normas."),
            _buildSectionTitle("5. Limitación de Responsabilidad"),
            _buildSectionBody(
                "ARte no se hace responsable de daños físicos o materiales derivados del uso indebido de las funciones de geolocalización o realidad aumentada."),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget _buildSectionBody(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87, height: 1.5),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Política de Privacidad", style: GoogleFonts.outfit()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Información que Recopilamos"),
            _buildSectionBody(
                "Recopilamos tu ubicación en tiempo real para mostrarte arte AR cercano y permitir que otros te vean en el mapa (si activas la visibilidad). También guardamos tus datos de perfil e imágenes subidas."),
            _buildSectionTitle("Uso de los Datos"),
            _buildSectionBody(
                "Utilizamos tus datos para personalizar tu experiencia, gestionar el sistema de puntos y permitir la interacción social entre artistas."),
            _buildSectionTitle("Compartir Información"),
            _buildSectionBody(
                "No vendemos tus datos personales. Tu nombre artístico y ubicación (si es pública) son visibles para otros usuarios de la red social."),
            _buildSectionTitle("Seguridad"),
            _buildSectionBody(
                "Implementamos medidas de seguridad para proteger tu información, aunque ninguna transmisión por internet es 100% segura."),
            _buildSectionTitle("Tus Derechos"),
            _buildSectionBody(
                "Puedes eliminar tu cuenta y todos tus datos asociados en cualquier momento desde los ajustes de la aplicación."),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget _buildSectionBody(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87, height: 1.5),
    );
  }
}

class SoftwareLicensesScreen extends StatelessWidget {
  const SoftwareLicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        cardTheme: const CardThemeData(color: Colors.white),
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      child: const LicensePage(
        applicationName: "ARte",
        applicationVersion: "2.4.0",
        applicationIcon: Padding(
          padding: EdgeInsets.all(20),
          child: Icon(Icons.palette, size: 60, color: Colors.red),
        ),
        applicationLegalese: "© 2024 ARte Team. Todos los derechos reservados.",
      ),
    );
  }
}
