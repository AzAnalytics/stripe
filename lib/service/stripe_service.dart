import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../shared/checkout_page.dart';
import '../customer_portal.dart';

class StripeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Récupération dynamique du Price ID
  Future<String?> getPriceId(String subscriptionType) async {
    try {
      var querySnapshot = await _firestore.collection('stripe_data').limit(1).get();
      if (querySnapshot.docs.isEmpty) {
        print("❌ Aucun document trouvé dans stripe_data");
        return null;
      }

      var doc = querySnapshot.docs.first;
      String? priceId = doc.data()[subscriptionType == "sub1" ? 'sub1priceId' : 'sub2priceId'];

      if (priceId == null || !priceId.startsWith("price_")) {
        print("❌ ID de prix invalide : $priceId");
        return null;
      }

      return priceId;
    } catch (e) {
      print("❌ Erreur récupération Price ID: $e");
      return null;
    }
  }


  /// 🔹 Lancer le processus de paiement
  Future<void> checkoutProcess(BuildContext context, String uid, String subscriptionType) async {
    try {
      String? priceId = await getPriceId(subscriptionType);
      if (priceId == null) {
        print("❌ Price ID non trouvé pour l'abonnement $subscriptionType");
        return;
      }

      DocumentReference docRef = await _firestore.collection('users').doc(uid).collection('checkout_sessions').add({
        'tax_rates': ["txr_1QzxNnCLyuydnuvxBkiltguy"],
        'price': priceId,
        'success_url': 'https://success.com',
        'cancel_url': 'https://cancel.com',
      });

      // ✅ Gérer l'écoute et l'annuler après paiement
      StreamSubscription? subscription;
      subscription = docRef.snapshots().listen((ds) async {
        if (!ds.exists) return;

        print("📡 Firestore data reçu : ${ds.data()}"); // 🔍 Debugging

        String? error;
        try {
          error = ds.get('error');
        } catch (_) {}

        if (error != null) {
          print("❌ Erreur de paiement: $error");
        } else {
          // ✅ Vérification avant d'utiliser "url"
          final Map<String, dynamic>? data = ds.data() as Map<String, dynamic>?;

          if (data != null && data.containsKey('url')) {
            String url = data['url'];

            // ✅ Annule l'écoute avant d'ouvrir la page de paiement
            subscription?.cancel();

            var res = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CheckoutPage(url: url)),
            );

            if (res == 'success') {
              print('✅ Paiement réussi');
            } else {
              print('❌ Paiement annulé');
            }
          } else {
            print("⚠️ En attente de l'URL Stripe...");
          }
        }
      });

    } catch (e) {
      print("❌ Erreur paiement: $e");
    }
  }


  /// 🔹 Accès au portail client Stripe
  Future<void> customerPortal(BuildContext context) async {
    try {
      HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('ext-firestore-stripe-payments-createPortalLink');
      HttpsCallableResult result = await callable.call({'returnUrl': 'https://cancel.com'});

      if (result.data != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CustomerPortal(url: result.data['url'])),
        );
      }
    } catch (e) {
      print("❌ Erreur accès portail client: $e");
    }
  }
}
