import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class CouponService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔥 Récupérer la description du coupon depuis le restaurant
  Future<String> getCouponDescription(String restaurantId, String uniqueCode) async {
    try {
      var couponSnapshot = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('coupons')
          .where('uniqueCode', isEqualTo: uniqueCode)
          .limit(1)
          .get();

      return couponSnapshot.docs.firstOrNull?.get('description') ?? "Pas de description disponible";
    } catch (e) {
      print("❌ Erreur récupération description coupon : $e");
      return "Erreur lors du chargement";
    }
  }

  /// 🔹 Obtenir ou créer un coupon unique pour un utilisateur et un restaurant
  Future<String> getOrCreateUserCoupon(String restaurantId, String userId) async {
    try {
      var query = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('coupons')
          .where("userId", isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.get('uniqueCode') ?? "Erreur";
      }

      String uniqueCode = generateUniqueCode();
      DocumentReference docRef = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('coupons')
          .add({
        "restaurantId": restaurantId,
        "userId": userId,
        "uniqueCode": uniqueCode,
        "isActive": true,
        "createdAt": Timestamp.now(),
        "usedAt": null,
      });

      print("✅ Coupon ajouté avec ID : ${docRef.id}");
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
