import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stripe/models/restaurant_model.dart';


class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Restaurant?> getRestaurantDetails(String restaurantId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('restaurants').doc(restaurantId).get();
      if (!doc.exists) return null;
      return Restaurant.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print("❌ Erreur récupération restaurant : $e");
      return null;
    }
  }
}
