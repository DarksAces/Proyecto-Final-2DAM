import 'package:flutter/material.dart';

class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  bool _is2FAEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Autenticación (2FA)"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: const Text("Estado de 2FA"),
              subtitle: Text(_is2FAEnabled ? "Activado" : "Desactivado"),
              trailing: Switch(
                value: _is2FAEnabled,
                onChanged: (val) => setState(() => _is2FAEnabled = val),
                activeColor: Colors.red,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "La autenticación en dos pasos añade una capa extra de seguridad a tu cuenta.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
