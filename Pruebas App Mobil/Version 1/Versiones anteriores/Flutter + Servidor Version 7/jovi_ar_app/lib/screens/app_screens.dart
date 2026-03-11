// lib/screens/app_screens.dart

/// Pantalla de Inicio (Dashboard).
///
/// Muestra las funcionalidades principales de la aplicación en formato de tarjetas grandes:
/// - Tienda Jovi
/// - Concurso
/// - Escáner AR
/// - Feed Social
/// - Galería y Perfil
export 'home_screen.dart';

/// Pantalla de la Tienda Virtual (Mockup).
///
/// Presenta un catálogo de productos Jovi hardcodeados para demostrar
/// la interfaz de usuario de compras. Incluye carrito de compras local.
export 'shop_screen.dart'; // Corrected from jovi_shop_screen.dart based on file list (shop_screen.dart exists)
export 'social_screen.dart';
export 'map_screen.dart';
export 'gallery_screen.dart';

/// Pantalla de Perfil de Usuario.
///
/// Muestra estadísticas (seguidores/seguidos) y permite buscar otros usuarios
/// para seguirlos.
export 'profile_screen.dart';
export 'users_list_screen.dart';

/// Pantalla del Escáner de Realidad Aumentada.
///
/// Muestra la vista previa de las cámaras disponibles en el dispositivo.
/// Actualmente sirve como una base para futuras implementaciones de AR
/// (como detección de planos o marcadores).
export 'ar_scanner_screen.dart';

/// Pantalla para añadir un nuevo sitio (Stop).
///
/// Recoge:
/// - Imagen (Cámara).
/// - Título y Categoría.
/// - Ubicación actual (GPS).
///
/// Sube los datos a Firestore mediante [ApiService].
export 'add_stop_screen.dart';