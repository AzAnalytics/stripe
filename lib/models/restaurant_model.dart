class Restaurant {
  final String name;
  final String description;
  final String cuisineType;
  final String address;
  final String city;
  final String hours;
  final List<String> ratings;
  final String salle;  // 📌 Vérifier ce champ
  final List<String> plats;

  Restaurant({
    required this.name,
    required this.description,
    required this.cuisineType,
    required this.address,
    required this.city,
    required this.hours,
    required this.ratings,
    required this.salle,
    required this.plats,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json, String id) {
    return Restaurant(
      name: json['name'] as String,
      description: json['description'] as String,
      cuisineType: json['cuisineType'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      hours: json['hours'] as String,
      ratings: List<String>.from(json['ratings'] ?? []),
      salle: json['salle'] as String,  // 📌 Vérifier ici
      plats: List<String>.from(json['plats'] ?? []),
    );
  }
}

