pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")

// ============================================================
// CONFIGURACIÓN FINAL CORREGIDA
// ============================================================
dependencyResolutionManagement {
    // Usamos PREFER_SETTINGS para centralizar todo aquí
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    
    repositories {
        google()
        mavenCentral()
        
        // 1. ESTO ARREGLA EL ERROR "Could not find io.flutter..."
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        
        // 2. ESTO ARREGLA EL ERROR DE MAPBOX
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            authentication {
                create<BasicAuthentication>("basic")
            }
            credentials {
                username = "mapbox"
                // ⚠️ PON AQUÍ TU NUEVO TOKEN CREADO CON EL CHECK 'DOWNLOADS:READ' MARCADO
                password = "sk.eyJ1IjoiZGFuaWVsZ2FyYnJ1IiwiYSI6ImNtaWVwNmU2dTA1YWkzZHM5MWZjNG9oZTQifQ.nZSbLC9WlMBQHFMa4uS3UQ" 
            }
        }
    }
}