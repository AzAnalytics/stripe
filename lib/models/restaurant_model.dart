import 'coupon_model.dart';

class RestaurantModel {
  final String id;
  final String name;
  final String description;
  final String cuisineType;
  final String address;
  final String city;
  final String hours;
  final String salle; // ✅ Image principale du restaurant
  final List<String> plats; // ✅ Cinq images URLs max
  final List<CouponModel> coupons;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.description,
    required this.cuisineType,
    required this.address,
    required this.city,
    required this.hours,
    required this.salle,
    required List<String> plats, // ✅ Validation pour limiter à 2 images
    required this.coupons,
  }) : plats = plats.length > 5 ? plats.sublist(0, 5) : plats; // ✅ Max 2 images pour plats

  /// 🔹 Convertir un document Firestore en objet `RestaurantModel`
  factory RestaurantModel.fromJson(Map<String, dynamic> json, String id) {
    return RestaurantModel(
      id: id,
      name: json['name'] as String,
      description: json['description'] as String,
      cuisineType: json['cuisineType'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      hours: json['hours'] as String,
      salle: json['salle'] ?? '', // ✅ Image principale
      plats: List<String>.from(json['plats'] ?? []).take(5).toList(), // ✅ Max 2 images
      coupons: (json['coupons'] as List<dynamic>?)
          ?.map((coupon) => CouponModel.fromJson(coupon as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  /// 🔹 Convertir un objet `RestaurantModel` en Map pour Firestore
  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "description": description,
      "cuisineType": cuisineType,
      "address": address,
      "city": city,
      "hours": hours,
      "salle": salle, // ✅ Image principale
      "plats": plats.take(5).toList(), // ✅ Max 2 images stockées
      "coupons": coupons.map((coupon) => coupon.toJson()).toList(),
    };
  }

  /// 🔹 Créer une copie du restaurant avec des valeurs modifiées
  RestaurantModel copyWith({
    String? name,
    String? description,
    String? cuisineType,
    String? address,
    String? city,
    String? hours,
    String? salle,
    List<String>? plats,
    List<CouponModel>? coupons,
  }) {
    return RestaurantModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      cuisineType: cuisineType ?? this.cuisineType,
      address: address ?? this.address,
      city: city ?? this.city,
      hours: hours ?? this.hours,
      salle: salle ?? this.salle,
      plats: plats != null ? plats.take(5).toList() : this.plats, // ✅ Max 2 images
      coupons: coupons ?? this.coupons,
    );
  }
}
