/// Script de migración: fusiona colección `username` → `users`
///
/// Ejecutar UNA SOLA VEZ con:
///   dart run lib/scripts/merge_username_to_users.dart
///
/// Requisitos: tener configurado Firebase Admin SDK o usar
/// firebase_core + cloud_firestore en modo standalone.
///
/// IMPORTANTE: este script hace merge (no sobrescribe).
/// Después de verificar en la consola de Firebase que los datos
/// se copiaron correctamente, elimina manualmente la colección
/// `username` desde https://console.firebase.google.com
///
/// NOTA: En la mayoría de los casos la colección `username` puede
/// estar vacía o contener only username-check documents (e.g. para
/// verificar unicidad de username). Revisa la consola antes de ejecutar.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;

  print('=== Migración: username → users ===\n');

  // 1. Leer todos los docs de la colección `username`
  final snapshot = await firestore.collection('username').get();

  if (snapshot.docs.isEmpty) {
    print('✅ La colección `username` está vacía. No hay nada que migrar.');
    print(
        '\n👉 Puedes eliminar la colección `username` desde Firebase Console.');
    return;
  }

  print('📦 Documentos encontrados en `username`: ${snapshot.docs.length}\n');

  int migrated = 0;
  int skipped = 0;

  for (final doc in snapshot.docs) {
    final data = doc.data();
    final docId = doc.id;

    if (data.isEmpty) {
      print('⚠️  Doc "$docId" vacío — ignorado');
      skipped++;
      continue;
    }

    try {
      // Merge: no sobreescribe campos ya existentes en `users`
      await firestore
          .collection('users')
          .doc(docId)
          .set(data, SetOptions(merge: true));
      print('✅ Migrado: $docId');
      migrated++;
    } catch (e) {
      print('❌ Error migrando "$docId": $e');
      skipped++;
    }
  }

  print('\n=== RESUMEN ===');
  print('Migrados: $migrated');
  print('Omitidos: $skipped');
  print('\n👉 Verifica los datos en Firebase Console y luego elimina');
  print('   manualmente la colección `username`.');
}
