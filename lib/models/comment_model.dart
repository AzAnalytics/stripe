class Comment {
  final String id;
  final String userId;
  final String name;
  final String restaurantId;
  final String text;
  final double rating;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.name,
    required this.restaurantId,
    required this.text,
    required this.rating,
    required this.createdAt,
  });

  /// Convertir un commentaire en JSON pour Firestore
  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "name": name,
      "restaurantId": restaurantId,
      "text": text,
      "rating": rating,
      "createdAt": createdAt.toIso8601String(),
    };
  }

  /// Créer un objet Comment depuis un snapshot Firestore
  factory Comment.fromJson(String id, Map<String, dynamic> json) {
    return Comment(
      id: id,
      userId: json["userId"],
      name: json["name"],
      restaurantId: json["restaurantId"],
      text: json["text"],
      rating: json["rating"].toDouble(),
      createdAt: DateTime.parse(json["createdAt"]),
    );
  }
}
