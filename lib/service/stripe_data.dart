import 'package:cloud_firestore/cloud_firestore.dart';

class StripeData {
  final String sub1priceId;
  final String sub2priceId;

  const StripeData({
    required this.sub1priceId,
    required this.sub2priceId,
  });

  factory StripeData.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) throw Exception("Données Stripe introuvables");

    return StripeData(
      sub1priceId: data['sub1priceId'] ?? '',
      sub2priceId: data['sub2priceId'] ?? '',
    );
  }
}

Future<StripeData> fetchStripeData() async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot<Map<String, dynamic>> ds = await firestore
        .collection('stripe_data')
        .doc('QvkA78Mnc1Tx6hths2Qy')
        .get();

    if (!ds.exists || ds.data() == null) {
      throw Exception("Les données Stripe sont introuvables.");
    }

    return StripeData.fromDocument(ds);
  } catch (e) {
    print("Erreur lors de la récupération des données Stripe : $e");
    throw Exception("Impossible de récupérer les données Stripe.");
  }
}

