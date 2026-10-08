import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GpuGridApp());
}

class AppColors {
  static const bg = Color(0xFF0B1220);
  static const card = Color(0xFF111B2E);
  static const accent = Color(0xFF00E5A8);
  static const accent2 = Color(0xFF3D8BFF);
  static const danger = Color(0xFFFF5470);
  static const textDim = Color(0xFF8FA3C2);
}

class GpuGridApp extends StatelessWidget {
  const GpuGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
    ).copyWith(primary: AppColors.accent, secondary: AppColors.accent2);

    return MaterialApp(
      title: 'GPUGrid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: AppColors.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.card,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF1E2C47)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF16233B),
          labelStyle: const TextStyle(color: AppColors.textDim),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      // Initialize Firebase ผ่าน FutureBuilder
      home: FutureBuilder<FirebaseApp>(
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Firebase error: ${snapshot.error}',
                      textAlign: TextAlign.center),
                ),
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(
                  child: CircularProgressIndicator(color: AppColors.accent)),
            );
          }
          return const AuthGate();
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
                child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }
        if (snap.hasData) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}
