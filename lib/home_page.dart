import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stripe/authentification/login_page.dart';
import 'package:stripe/service/auth_service.dart';
import 'package:stripe/service/user_db_service.dart';
import 'package:stripe/models/user_data.dart';
import 'package:stripe/widgets/subscription_tile.dart';
import 'package:stripe/color.dart';
import 'package:stripe/restaurant_list_screen.dart';
import 'package:stripe/models/subscription_status.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, authSnapshot) {
        if (!authSnapshot.hasData) return const LoginPage();
        String uid = authSnapshot.data!.uid;

        return StreamBuilder<UserData>(
          stream: UserDbService(uid: uid).fetchUserData,
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

            return StreamBuilder<SubscriptionStatus>(
              stream: UserDbService(uid: uid).checkSubscriptionIsActive,
              builder: (context, subSnapshot) {
                if (!subSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                bool hasSubscription = subSnapshot.data!.subIsActive;
                String activePriceId = subSnapshot.data!.activePriceId;

                print("🔍 Abonnement actif détecté: $activePriceId");

                return Scaffold(
                  backgroundColor: ColorsTheme.background,
                  appBar: AppBar(
                    title: Text(
                      "Bonjour ${userSnapshot.data!.name}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: ColorsTheme.primary,
                    elevation: 0,
                    actions: [
                      if (hasSubscription)
                        IconButton(
                          icon: const Icon(Icons.restaurant, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RestaurantListScreen()),
                            );
                          },
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.restaurant, color: Colors.grey),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("🔒 Vous devez être abonné pour accéder aux restaurants."),
                              ),
                            );
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.exit_to_app, color: Colors.white),
                        onPressed: () => _logout(context),
                      ),
                    ],
                  ),
                  body: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          "Choisissez votre abonnement",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 20),

                        // ✅ Correction de l'affichage des abonnements
                        if (!hasSubscription)
                          Column(
                            children: [
                              SubscriptionTile(
                                title: "Starter Plan",
                                price: "80.00 €",
                                priceId: "sub1",
                                uid: uid,
                                isActive: activePriceId == "sub1",
                              ),
                              const SizedBox(height: 15),
                              SubscriptionTile(
                                title: "Pro Plan",
                                price: "120.00 €",
                                priceId: "sub2",
                                uid: uid,
                                isActive: activePriceId == "sub2",
                              ),
                            ],
                          )
                        else
                          SubscriptionTile(
                            title: activePriceId == "sub1" ? "Starter Plan" : "Pro Plan",
                            price: activePriceId == "sub1" ? "80.00 €" : "120.00 €",
                            priceId: activePriceId,
                            uid: uid,
                            isActive: true, // ✅ Maintenant on affiche l'abonnement actif
                          ),
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
  }



  /// 🔥 Fonction de déconnexion
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
    );
  }
}
