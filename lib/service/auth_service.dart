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

  /// 🔥 Connexion utilisateur
  Future<String?> loginUser(BuildContext context, String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());

      // ✅ Redirection après connexion réussie
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
      return null; // Aucun message d'erreur (succès)
    } catch (e) {
      return _handleAuthError(e);
    }
  }

  /// 🔥 Réinitialisation du mot de passe
  Future<void> resetPassword(BuildContext context, String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer votre email.")),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Un email de réinitialisation a été envoyé.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_handleAuthError(e))),
      );
    }
  }

  /// 🔥 Gestion des erreurs Firebase
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return "Aucun utilisateur trouvé avec cet email.";
        case 'wrong-password':
          return "Mot de passe incorrect.";
        case 'invalid-email':
          return "Adresse email invalide.";
        default:
          return "Erreur lors de l'authentification.";
      }
    }
    return "Erreur inconnue.";
  }
}
