import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stripe/models/restaurant_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔥 Récupérer les détails d'un restaurant
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

  /// 🔥 Récupérer les restaurants filtrés par ville et/ou type de cuisine
  Future<List<Restaurant>> getFilteredRestaurants(String? city, String? cuisine) async {
    try {
      Query query = _firestore.collection('restaurants');

      // 🔹 Appliquer le filtre ville si sélectionné
      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      // 🔹 Appliquer le filtre type de cuisine si sélectionné
      if (cuisine != null && cuisine.isNotEmpty) {
        query = query.where('cuisineType', isEqualTo: cuisine);
      }

      QuerySnapshot snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return Restaurant.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print("❌ Erreur récupération restaurants filtrés : $e");
      return [];
    }
  }
}
