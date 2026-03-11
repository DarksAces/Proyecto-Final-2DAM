package com.example.jovi_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Registra los plugins, incluyendo los de Firebase
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        // Llama a la implementación base si es necesario, aunque en Flutter 
        // moderno GeneratedPluginRegistrant suele ser suficiente.
        super.configureFlutterEngine(flutterEngine) 
    }
}