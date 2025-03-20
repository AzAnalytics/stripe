import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stripe/home_page.dart';
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

      // ✅ Forcer le rafraîchissement des informations utilisateur après connexion
      await FirebaseAuth.instance.currentUser?.reload();

      // ✅ Redirection après connexion réussie
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
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

      // 🔥 Déconnexion immédiate après l’envoi de l’email
      await _auth.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Un email de réinitialisation a été envoyé. Connectez-vous avec le nouveau mot de passe.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_handleAuthError(e))),
      );
    }
  }


  /// 🔥 Gestion des erreurs Firebase
  String _handleAuthError(dynamic error) {
    print("🔥 Firebase Error: ${error.toString()}"); // ✅ Afficher l'erreur complète dans la console

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return "Aucun utilisateur trouvé avec cet email.";
        case 'wrong-password':
          return "Mot de passe incorrect.";
        case 'invalid-email':
          return "Adresse email invalide.";
        case 'user-disabled':
          return "Ce compte a été désactivé.";
        case 'too-many-requests':
          return "Trop de tentatives, réessayez plus tard.";
        case 'operation-not-allowed':
          return "Connexion désactivée pour ce mode.";
        case 'network-request-failed':
          return "Erreur réseau. Vérifiez votre connexion.";
        case 'email-already-in-use':
          return "Cet email est déjà utilisé par un autre compte.";
        default:
          return "Erreur: ${error.message ?? "Inconnue"}"; // ✅ Récupérer le vrai message Firebase
      }
    }
    return "Erreur inconnue: ${error.toString()}"; // ✅ Retourne le message brut si ce n’est pas un FirebaseAuthException
  }

}
