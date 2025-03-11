import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stripe/authentification/login_page.dart';
import 'package:stripe/models/user_data.dart';
import 'package:stripe/restaurant_list_screen.dart';
import 'package:stripe/shared/checkout_page.dart';
import 'package:stripe/color.dart';
import 'package:stripe/customer_portal.dart';
import 'package:stripe/service/stripe_data.dart';
import 'package:stripe/service/user_db_service.dart';
import 'package:stripe/models/subscription_status.dart';

class HomePage extends StatefulWidget {
  final String uid;
  const HomePage({super.key, required this.uid});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late StripeData stripeData;
  late SubscriptionStatus subscriptionStatus;
  bool loadingPayment = false;

  Widget loading(String msg) => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 10),
        CircularProgressIndicator(),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (!authSnapshot.hasData) return const LoginPage();
        String uid = authSnapshot.data!.uid;

        return StreamBuilder<UserData>(
          stream: UserDbService(uid: uid).fetchUserData,
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return loading('Chargement des données utilisateur...');
            UserData userData = userSnapshot.data!;

            return FutureBuilder<StripeData>(
              future: fetchStripeData(),
              builder: (context, stripeSnapshot) {
                if (!stripeSnapshot.hasData) return loading('Chargement des données Stripe...');
                stripeData = stripeSnapshot.data!;
                if (loadingPayment) return loading('Traitement du paiement...');

                return StreamBuilder<SubscriptionStatus>(
                  stream: UserDbService(uid: uid, stripeData: stripeData).checkSubscriptionIsActive,
                  builder: (context, subSnapshot) {
                    if (!subSnapshot.hasData) return loading('Vérification de l’abonnement...');
                    subscriptionStatus = subSnapshot.data!;

                    return Scaffold(
                      backgroundColor: ColorsTheme.background,
                      appBar: AppBar(
                        title: Text(
                          'Bonjour, ${userData.name}',
                          style: const TextStyle(color: Colors.black),
                        ),
                        backgroundColor: ColorsTheme.background,
                        elevation: 0,
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.restaurant, color: Colors.black),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RestaurantListScreen()),
                              );
                            },
                          ),

                          TextButton(
                            onPressed: () => logoutUser(context),
                            child: const Text('Déconnexion'),
                          ),
                        ],
                      ),
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 30),
                            if (!subscriptionStatus.subIsActive ||
                                subscriptionStatus.activePriceId == stripeData.sub1priceId)
                              subscriptionTile('Starter Plan', '80.00 €', stripeData.sub1priceId),
                            const SizedBox(height: 10),
                            if (!subscriptionStatus.subIsActive ||
                                subscriptionStatus.activePriceId == stripeData.sub2priceId)
                              subscriptionTile('Pro Plan', '120.00 €', stripeData.sub2priceId),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  /// 🔥 Fonction de déconnexion
  void logoutUser(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
    );
  }

  /// 🔥 Widget des abonnements
  Widget subscriptionTile(String title, String price, String priceId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 4,
        color: ColorsTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 20),
              ),
              const SizedBox(height: 20),
              Text(
                price,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                onPressed: () => checkoutProcess(title == 'Starter Plan' ? 'sub1' : 'sub2'),
                child: Text(
                  'Choisir ce plan',
                  style: TextStyle(color: ColorsTheme.primary, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔥 Récupération dynamique du Price ID
  Future<String?> getPriceIdFromStripeData(String subscriptionType) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('stripe_data')
          .limit(1) // 🔥 Récupère seulement le premier document
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("❌ Aucun document trouvé dans stripe_data");
        return null;
      }

      var doc = querySnapshot.docs.first; // ✅ Récupère le premier document
      print("✅ Document récupéré : ${doc.id}");

      // 🔥 Récupère l'ID du prix en fonction du type d'abonnement
      String? priceId = doc.data()[subscriptionType == "sub1" ? 'sub1priceId' : 'sub2priceId'];

      if (priceId == null || !priceId.startsWith("price_")) {
        print("❌ ID de prix invalide : $priceId");
        return null;
      }

      print("✅ Price ID trouvé : $priceId");
      return priceId;
    } catch (e) {
      print("❌ Erreur lors de la récupération du Price ID : $e");
      return null;
    }
  }


  Future<void> checkoutProcess(String subscriptionType) async {
    setState(() => loadingPayment = true);

    try {
      // 🔥 Récupération du Price ID depuis Firestore
      String? priceId = await getPriceIdFromStripeData(subscriptionType);
      if (priceId == null) {
        print("❌ Erreur : Price ID introuvable.");
        setState(() => loadingPayment = false);
        return;
      }

      // 🔥 Création de la session de paiement Stripe
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('checkout_sessions')
          .add({
        'tax_rates': ["txr_1QzxNnCLyuydnuvxBkiltguy"],
        'price': priceId,
        'success_url': 'https://success.com',
        'cancel_url': 'https://cancel.com',
      });

      // 🔥 Écoute des mises à jour de Firestore
      docRef.snapshots().listen((ds) async {
        if (!ds.exists) return;

        String? error;
        try {
          error = ds.get('error');
        } catch (_) {}

        if (error != null) {
          print("❌ Erreur de paiement : $error");
          setState(() => loadingPayment = false);
        } else {
          String url = ds.get('url');
          var res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CheckoutPage(url: url)),
          );

          setState(() => loadingPayment = false);
          if (res == 'success') {
            print('✅ Paiement réussi');
          } else {
            print('❌ Paiement annulé');
          }
        }
      });
    } catch (e) {
      print("❌ Erreur lors du traitement du paiement : $e");
      setState(() => loadingPayment = false);
    }
  }


  Future<void> customerPortal() async {
    try {
      HttpsCallable callable =
      FirebaseFunctions.instance.httpsCallable('ext-firestore-stripe-payments-createPortalLink');
      HttpsCallableResult result = await callable.call({'returnUrl': 'https://cancel.com'});

      if (result.data != null) {
        String url = result.data['url'];
        Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerPortal(url: url)));
      }
    } catch (e) {
      print("Erreur lors de l'accès au portail client : $e");
    }
  }
}
