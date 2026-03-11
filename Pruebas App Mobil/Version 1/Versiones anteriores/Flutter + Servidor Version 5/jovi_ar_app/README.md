# 📱 Jovi AR App - Proyecto Final 2DAM

Esta es la aplicación móvil oficial del proyecto **Jovi AR**, desarrollada en **Flutter**. Combina geolocalización, realidad aumentada (RA) y elementos sociales para gamificar la exploración de la ciudad.

## 📋 Requisitos Previos

Antes de comenzar, asegúrate de tener instalado y configurado lo siguiente:

1.  **Flutter SDK**: [Instalar Flutter](https://docs.flutter.dev/get-started/install) (versión estable recomendada, >= 3.0.0).
2.  **Dart SDK**: Incluido con Flutter.
3.  **Editor de Código**: VS Code (con extensiones de Flutter/Dart) o Android Studio.
4.  **Cuenta de Firebase**: Para autenticación y base de datos.
5.  **Cuenta de Mapbox**: Para los mapas vectoriales.

---

## 🚀 Instalación y Puesta en Marcha

Sigue estos pasos para clonar y ejecutar el proyecto desde cero:

### 1. Clonar el Repositorio
```bash
git clone https://github.com/TuUsuario/Proyecto-Final-2DAM.git
cd "Proyecto-Final-2DAM/Pruebas App/Flutter + Servidor/jovi_ar_app"
```

### 2. Instalar Dependencias
```bash
flutter pub get
```

### 3. Configuración de Mapbox
Este proyecto utiliza `mapbox_maps_flutter`. Necesitas:

1.  Obtener un **Access Token** público en [Mapbox](https://account.mapbox.com/).
2.  Configurarlo en el archivo `lib/main.dart` (variable `MAPBOX_ACCESS_TOKEN`).
3.  **Android**: Añadir tu token secreto en `android/gradle.properties`.

### 4. Configuración de Firebase
El proyecto depende de **Firebase Auth**, **Firestore** y **Storage**.

1.  Instala [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/).
2.  Ejecuta `flutterfire configure` en la terminal dentro de la carpeta del proyecto.
3.  Selecciona tu proyecto de Firebase y las plataformas (Android/iOS).

### 5. Ejecutar la App
```bash
flutter run
```

---

## 📂 Estructura del Proyecto

El código fuente se encuentra en la carpeta `lib/` y sigue una estructura modular limpia:

```text
lib/
├── main.dart               # Punto de entrada y configuración inicial
├── firebase_options.dart   # Configuración generada por FlutterFire
├── services/               # 🧠 Lógica de Negocio y APIs
│   ├── api_service.dart      # CRUD Sitios, Votos, Admin Review
│   ├── auth_service.dart     # Gestión de Auth y Registro de Nicks
│   └── settings_service.dart # Preferencias locales
├── screens/                # 📱 Pantallas (UI)
│   ├── app_screens.dart      # Exportaciones
│   ├── auth_screens.dart     # Login/Registro
│   ├── home_screen.dart      # Dashboard
│   ├── map_screen.dart       # Mapa Interactivo
│   ├── contest_screen.dart   # Concurso de Fotos
│   ├── shop_screen.dart      # Tienda Virtual (Mockup)
│   ├── admin_review_screen.dart # Moderación de Contenido
│   └── ...
├── widgets/                # 🧩 Componentes Reutilizables
```

---

## ✨ Funcionalidades Clave

1.  **Exploración AR/Mapas**: Visualización de puntos de interés en un mapa interactivo.
2.  **Gamificación (Concursos)**: Subida de fotos para concursos escolares, sistema de likes y gestión de autoría.
3.  **Red Social**: Sistema de seguidores/seguidos entre alumnos, perfiles públicos.
4.  **Gestión de Sitios**: Los usuarios pueden subir "descubrimientos" que pasan por un flujo de aprobación (IA/Admin).
5.  **Tienda Virtual**: Catálogo demostrativo de productos Jovi.
6.  **Panel de Administración**: Herramienta interna para aprobar/denegar sitios subidos.

## ⚠️ Notas Importantes para Desarrolladores

*   **Permisos**: La app solicita permisos de Ubicación y Cámara al inicio (`main.dart`).
*   **Reglas de Firestore**: Asegúrate de que las reglas de seguridad permitan lectura/escritura a usuarios autenticados.
*   **Tienda**: La pantalla de tienda es un prototipo local sin pasarela de pago real.
