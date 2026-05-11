import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';

import 'screens/main_wrapper.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/features/gallery_screen.dart';
import 'screens/splash_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final settingsService = SettingsService();
  await settingsService.init();

  // Background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Notification Service
  NotificationService().initialize().catchError((e) {
    debugPrint("Error initializing notifications: $e");
  });

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(MyApp(settingsService: settingsService));
}

class MyApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  final SettingsService settingsService;

  const MyApp({super.key, required this.settingsService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: settingsService,
        builder: (context, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'ARte',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsService.themeMode,
            locale: settingsService.locale,
            home: const SplashScreen(),
            routes: {
              '/auth': (context) => const AuthWrapper(),
              '/welcome': (context) => const WelcomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const MainWrapper(),
              '/gallery': (context) => const GalleryScreen(),
            },
          );
        });
  }
}
