class UserData {
  String name;
  String stripeId;

  UserData({required this.name, required this.stripeId});

  /// 🔥 Convertir depuis Firestore
  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'] ?? 'Utilisateur inconnu',
      stripeId: json['stripeId'] ?? '',
    );
  }

  /// 🔥 Convertir en JSON pour Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'stripeId': stripeId,
    };
  }
}
