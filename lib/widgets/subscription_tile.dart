import 'package:flutter/material.dart';
import '../service/stripe_service.dart';
import '../color.dart';


class SubscriptionTile extends StatelessWidget {
  final String title;
  final String price;
  final String priceId;
  final String uid;
  final bool isActive; // 🔥 Indique si cet abonnement est actif

  const SubscriptionTile({
    super.key,
    required this.title,
    required this.price,
    required this.priceId,
    required this.uid,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: isActive ? 6 : 3, // 🔥 Effet d'ombre plus fort pour l'abonnement actif
        color: isActive ? ColorsTheme.primary.withAlpha(230) : ColorsTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle, color: Colors.white, size: 22), // ✅ Indicateur visuel
                  ],
                ],
              ),
              const SizedBox(height: 15),
              Text(
                price,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26),
              ),
              const SizedBox(height: 20),

              // 🔥 Afficher soit "Gérer mon abonnement", soit "Choisir ce plan"
// 🔥 Afficher soit le bouton de paiement, soit "Gérer mon abonnement"
              isActive
                  ? ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                onPressed: () {
                  StripeService().customerPortal(context); // ✅ Accès au portail client au lieu de payer à nouveau
                },
                child: Text(
                  "Gérer mon abonnement",
                  style: TextStyle(color: ColorsTheme.primary, fontWeight: FontWeight.w900),
                ),
              )
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                onPressed: () => StripeService().checkoutProcess(context, uid, priceId),
                child: Text(
                  "Choisir ce plan",
                  style: TextStyle(color: ColorsTheme.primary, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
