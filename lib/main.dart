import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'routes/app_routes.dart';

void main() async {
  // Ensure Flutter is initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase before running the app - with proper error handling
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized successfully');
    } else {
      debugPrint('✅ Firebase was already initialized');
    }
  } catch (e) {
    debugPrint('⚠️ Firebase initialization error: $e');
    // Continue anyway - the app should still work for UI testing
  }
  
  runApp(const RizzumeApp());
}

class RizzumeApp extends StatelessWidget {
  const RizzumeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rizzume',
      theme: ThemeData(
        fontFamily: 'SplineSans',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF120B17),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'SplineSans'),
          displayMedium: TextStyle(fontFamily: 'SplineSans'),
          displaySmall: TextStyle(fontFamily: 'SplineSans'),
          headlineLarge: TextStyle(fontFamily: 'SplineSans'),
          headlineMedium: TextStyle(fontFamily: 'SplineSans'),
          headlineSmall: TextStyle(fontFamily: 'SplineSans'),
          titleLarge: TextStyle(fontFamily: 'SplineSans'),
          titleMedium: TextStyle(fontFamily: 'SplineSans'),
          titleSmall: TextStyle(fontFamily: 'SplineSans'),
          bodyLarge: TextStyle(fontFamily: 'SplineSans'),
          bodyMedium: TextStyle(fontFamily: 'SplineSans'),
          bodySmall: TextStyle(fontFamily: 'SplineSans'),
          labelLarge: TextStyle(fontFamily: 'SplineSans'),
          labelMedium: TextStyle(fontFamily: 'SplineSans'),
          labelSmall: TextStyle(fontFamily: 'SplineSans'),
        ),
      ),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}
