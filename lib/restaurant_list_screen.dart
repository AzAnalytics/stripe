import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:stripe/restaurant_detail_screen.dart';

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  List<Map<String, dynamic>> restaurants = [];
  bool isLoading = true;
  final String defaultImageUrl = 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg';

  @override
  void initState() {
    super.initState();
    fetchRestaurants();
  }

  /// 🔹 **Formatage du nom (apostrophes, majuscules)**
  String formatRestaurantName(String rawName) {
    if (rawName.isEmpty) return "Restaurant inconnu";

    // ✅ Décode les caractères spéciaux (ex: %27 → ' )
    String formattedName = Uri.decodeComponent(rawName);

    // ✅ Remplace `_` par un espace
    formattedName = formattedName.replaceAll("_", " ");

    // ✅ 1ʳᵉ lettre en majuscule
    return formattedName[0].toUpperCase() + formattedName.substring(1);
  }

  /// 🔹 **Récupère l’image de la salle depuis Firebase Storage**
  Future<String> getDownloadUrl(String filePath) async {
    if (filePath.isEmpty) return defaultImageUrl;

    // ✅ Vérifie si l’URL est déjà complète
    if (filePath.startsWith("https://")) {
      return filePath;
    }

    // ✅ Nettoyage du chemin et encodage correct
    String cleanedPath = filePath.trim().replaceAll(" ", "%20");

    try {
      // ✅ Vérifie si l'image existe réellement dans Firebase Storage
      final ref = FirebaseStorage.instance.ref(cleanedPath);
      String downloadUrl = await ref.getDownloadURL();

      print("✅ URL Firebase obtenue: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("❌ Erreur récupération URL Firebase: $e");
      return defaultImageUrl;
    }
  }

  /// 🔹 **Récupérer les restaurants depuis Firestore**
  // 🔹 Récupère les restaurants depuis Firestore et formate les données
  Future<void> fetchRestaurants() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance.collection('restaurants').get();

      if (querySnapshot.docs.isEmpty) {
        print("❌ Aucun restaurant trouvé.");
        if (mounted) setState(() => isLoading = false);
        return;
      }

      List<Map<String, dynamic>> fetchedRestaurants = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        print("📌 Données Firestore: $data");

        // ✅ Récupération et formatage du nom
        String restaurantName = data["name"] ?? "Nom inconnu";
        restaurantName = restaurantName.replaceAllMapped(
          RegExp(r"(^\w|\s\w)"),
              (match) => match.group(0)!.toUpperCase(),
        );

        // ✅ Gestion du type de cuisine (évite l'erreur si null)
        String cuisineType = data["cuisineType"]?.toString() ?? "Type inconnu";

        // ✅ Récupération et conversion de l'image salle
        String sallePath = data["salle"] ?? "";
        String salleUrl = sallePath.isNotEmpty ? await getDownloadUrl(sallePath) : defaultImageUrl;

        fetchedRestaurants.add({
          "id": doc.id,
          "name": restaurantName,
          "cuisineType": cuisineType, // 🔥 Corrigé ici !
          "salle": salleUrl,
        });
      }

      print("✅ Restaurants récupérés : ${fetchedRestaurants.length}");

      if (mounted) {
        setState(() {
          restaurants = fetchedRestaurants;
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print("❌ Erreur lors de la récupération des restaurants : $e");
      print("📌 StackTrace : $stackTrace");

      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Restaurants',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : restaurants.isEmpty
          ? const Center(child: Text("Aucun restaurant trouvé."))
          : Padding(
        padding: const EdgeInsets.all(10),
        child: GridView.builder(
          itemCount: restaurants.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final restaurant = restaurants[index];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RestaurantDetailScreen(
                      restaurantId: restaurant['id'],
                    ),
                  ),
                );
              },
              child: Card(
                key: ValueKey(restaurant['id']),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Hero(
                        tag: 'restaurant_${restaurant['id']}',
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                          child: Image.network(
                            restaurant["salle"].isNotEmpty ? restaurant["salle"] : defaultImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print("❌ Erreur chargement image: $error");
                              print("🔍 URL utilisée: ${restaurant["salle"]}");
                              return const Icon(Icons.image_not_supported);
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurant['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            restaurant['cuisineType'] ?? "Type inconnu", // ✅ Si null, afficher "Type inconnu"
                            style: const TextStyle(color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
