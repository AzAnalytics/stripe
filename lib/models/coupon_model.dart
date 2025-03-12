import 'package:cloud_firestore/cloud_firestore.dart';

class CouponModel {
  final String id;
  final String restaurantId;
  final String userId;
  final String description;
  final int discountPercentage;
  final int maxPeople;
  final bool isActive;
  final String uniqueCode;
  final DateTime createdAt;
  final DateTime? usedAt;

  CouponModel( {
    required this.userId,
    required this.id,
    required this.restaurantId,
    required this.description,
    required this.discountPercentage,
    required this.maxPeople,
    required this.isActive,
    required this.uniqueCode,
    required this.createdAt,
    this.usedAt,
  });

  /// 🔹 Convertir un document Firestore en objet `CouponModel`
  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] as String,
      restaurantId: json['restaurantId'] as String,
      description: json['description'] as String,
      discountPercentage: json['discountPercentage'] as int,
      maxPeople: json['maxPeople'] as int,
      isActive: json['isActive'] as bool,
      uniqueCode: json['uniqueCode'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      usedAt: json['usedAt'] != null ? (json['usedAt'] as Timestamp).toDate() : null,
      userId: json['userId'] as String,
    );
  }

  /// 🔹 Convertir un objet `CouponModel` en Map pour Firestore
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "restaurantId": restaurantId,
      "description": description,
      "discountPercentage": discountPercentage,
      "maxPeople": maxPeople,
      "isActive": isActive,
      "uniqueCode": uniqueCode,
      "createdAt": Timestamp.fromDate(createdAt),
      "usedAt": usedAt != null ? Timestamp.fromDate(usedAt!) : null,
    };
  }

  /// 🔹 Créer une copie du coupon avec des valeurs modifiées
  CouponModel copyWith({
    String? userId,
    String? id,
    String? restaurantId,
    String? description,
    int? discountPercentage,
    int? maxPeople,
    bool? isActive,
    String? uniqueCode,
    DateTime? createdAt,
    DateTime? usedAt,
  }) {
    return CouponModel(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      description: description ?? this.description,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      maxPeople: maxPeople ?? this.maxPeople,
      isActive: isActive ?? this.isActive,
      uniqueCode: uniqueCode ?? this.uniqueCode,
      createdAt: createdAt ?? this.createdAt,
      usedAt: usedAt ?? this.usedAt,
      userId: userId ?? this.userId,
    );
  }
}