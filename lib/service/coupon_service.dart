import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class CouponService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔥 Récupérer la description du coupon depuis le restaurant
  Future<String> getCouponDescription(String restaurantId) async {
    try {
      var couponSnapshot = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('coupons')
          .limit(1) // ✅ Récupère uniquement le premier coupon
          .get();

      if (couponSnapshot.docs.isNotEmpty) {
        return couponSnapshot.docs.first.get('description') ?? "Pas de description disponible";
      }
      return "Pas de description disponible";
    } catch (e) {
      print("❌ Erreur récupération description coupon : $e");
      return "Erreur lors du chargement";
    }
  }




  /// 🔹 Obtenir ou créer un coupon unique pour un utilisateur et un restaurant
  Future<String> getOrCreateUserCoupon(String restaurantId, String userId) async {
    try {
      // 🔍 Vérifie si l'utilisateur a déjà un coupon unique
      var existingCoupon = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('coupons')
          .where("userId", isEqualTo: userId)
          .limit(1)
          .get();

      if (existingCoupon.docs.isNotEmpty) {
        return existingCoupon.docs.first.get('uniqueCode'); // 🔥 Retourne le code existant
      }

      // 🔍 Récupère le coupon global du restaurant
      var restaurantCoupon = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('coupons')
          .limit(1) // 🔥 Récupère uniquement le 1er coupon du restaurant
          .get();

      if (restaurantCoupon.docs.isEmpty) {
        return "Erreur : Aucun coupon disponible"; // ❌ Aucun coupon global trouvé
      }

      // 🔥 Génère un code unique pour l'utilisateur
      String uniqueCode = generateUniqueCode();

      // 📝 Ajoute l'utilisateur à un coupon unique basé sur le coupon global
      DocumentReference userCouponRef = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('coupons')
          .add({
        "restaurantId": restaurantId,
        "userId": userId,
        "uniqueCode": uniqueCode,
        "description": restaurantCoupon.docs.first.get('description'), // 🔥 Récupère la description du coupon global
        "discountPercentage": restaurantCoupon.docs.first.get('discountPercentage'),
        "maxPeople": restaurantCoupon.docs.first.get('maxPeople'),
        "isActive": true,
        "createdAt": Timestamp.now(),
        "usedAt": null,
      });

      print("✅ Nouveau coupon généré avec ID : ${userCouponRef.id} pour l'utilisateur $userId");
      return uniqueCode;
    } catch (e) {
      print("❌ Erreur génération coupon : $e");
      return "Erreur";
    }
  }


  /// 🔹 Générer un code unique aléatoire
  String generateUniqueCode() {
    const String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  /// 🔹 Utiliser un coupon et le désactiver
  Future<bool> useCoupon(String uniqueCode) async {
    try {
      var query = await _firestore
          .collectionGroup("coupons") // 🔥 Recherche dans toutes les collections `coupons`
          .where("uniqueCode", isEqualTo: uniqueCode)
          .where("isActive", isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return false; // ❌ Coupon invalide ou déjà utilisé
      }

      String couponId = query.docs.first.id;
      String restaurantId = query.docs.first.get("restaurantId");

      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection("coupons")
          .doc(couponId)
          .update({
        "isActive": false,
        "usedAt": Timestamp.now(),
      });

      return true; // ✅ Coupon utilisé avec succès
    } catch (e) {
      print("❌ Erreur validation coupon : $e");
      return false;
    }
  }
}
