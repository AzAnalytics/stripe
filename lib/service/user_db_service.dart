import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stripe/service/stripe_data.dart';
import 'package:stripe/models/user_data.dart';
import 'package:stripe/models/subscription_status.dart';

class UserDbService {
  final String uid;
  final StripeData? stripeData;
  UserDbService({required this.uid, this.stripeData});

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// 🔥 Récupération des données utilisateur
  Stream<UserData> get fetchUserData {
    return firestore.collection('users').doc(uid).snapshots().map((ds) {
      try {
        return UserData.fromJson(ds.data() ?? {});
      } catch (e) {
        return UserData(name: 'Erreur', stripeId: '');
      }
    });
  }

  /// 🔥 Vérification en temps réel de l’abonnement actif
  Stream<SubscriptionStatus> get checkSubscriptionIsActive {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('subscriptions')
        .snapshots()
        .map((event) => _checkUserHaveActiveSubscription(event));
  }

  /// 🔥 Vérifier une seule fois l'abonnement actif (sans Stream)
  Future<SubscriptionStatus> getUserSubscriptionStatus() async {
    QuerySnapshot qs = await firestore.collection('users').doc(uid).collection('subscriptions').get();
    return _checkUserHaveActiveSubscription(qs);
  }

  /// 🔥 Vérifie si l'utilisateur a un abonnement actif
  SubscriptionStatus _checkUserHaveActiveSubscription(QuerySnapshot qs) {
    for (var ds in qs.docs) {
      final data = ds.data() as Map<String, dynamic>?;

      if (data == null) continue;

      final String? status = data["status"];
      if (status == 'trialing' || status == 'active') {
        final DocumentReference? priceDocRef = data['price'];
        String currentPriceId = '';

        if (priceDocRef != null && stripeData != null) {
          if (priceDocRef.id == stripeData!.sub1priceId) {
            currentPriceId = stripeData!.sub1priceId;
          } else if (priceDocRef.id == stripeData!.sub2priceId) {
            currentPriceId = stripeData!.sub2priceId;
          }
        }

        return SubscriptionStatus(
          subIsActive: true,
          status: status ?? '',
          activePriceId: currentPriceId,
        );
      }
    }
    return SubscriptionStatus(subIsActive: false, status: '', activePriceId: '');
  }
}
