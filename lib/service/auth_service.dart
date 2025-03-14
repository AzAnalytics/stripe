import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../authentification/login_page.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 Récupérer l'utilisateur actuellement connecté
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 🔹 Déconnexion
  Future<void> logout(BuildContext context) async {
    await _auth.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }
}
