import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Términos de Servicio"), centerTitle: true),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text("Aquí van los términos de servicio de Aura AR..."),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Política de Privacidad"), centerTitle: true),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text("Aquí va la política de privacidad de Aura AR..."),
      ),
    );
  }
}

class SoftwareLicensesScreen extends StatelessWidget {
  const SoftwareLicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Licencias de Software"), centerTitle: true),
      body: const LicensePage(
        applicationName: "Aura AR",
        applicationVersion: "1.0.0",
      ),
    );
  }
}
