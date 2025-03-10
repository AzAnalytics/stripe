import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:stripe/authentification/signup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Capture les erreurs Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("🔥 Erreur Flutter : ${details.exceptionAsString()}");
  };

  // Capture les erreurs asynchrones (ex : Firebase)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint("🚨 Erreur asynchrone : $error");
    return true;
  };

  // Initialisation Firebase AVANT de lancer l'application
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gourmet Pass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const SignupPage(), // Redirection directe après Firebase init
    );
  }
}
