import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class CouponService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Obtenir ou créer un coupon unique pour un utilisateur et un restaurant
  Future<String> getOrCreateUserCoupon(String restaurantId, String userId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('coupons')
          .where("restaurantId", isEqualTo: restaurantId)
          .where("userId", isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first['uniqueCode']; // 🔥 Retourne le code existant
      }

      String uniqueCode = generateUniqueCode();
      DocumentReference docRef = await _firestore.collection('coupons').add({
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
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  Future<bool> useCoupon(String uniqueCode) async {
    try {
      QuerySnapshot query = await _firestore
          .collection("coupons")
          .where("uniqueCode", isEqualTo: uniqueCode)
          .where("isActive", isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return false; // ❌ Coupon invalide ou déjà utilisé
      }

      String couponId = query.docs.first.id;
      await _firestore.collection("coupons").doc(couponId).update({
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
