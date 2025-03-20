import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:stripe/filters/city_filter.dart';
import 'package:stripe/filters/cuisine_filter.dart';
import 'package:stripe/restaurant_detail_screen.dart';


class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  List<Map<String, dynamic>> restaurants = [];
  bool isLoading = true;
  String? selectedCity;
  String? selectedCuisine;
  final String defaultImageUrl = 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg';

  @override
  void initState() {
    super.initState();
    fetchRestaurants();
  }

  /// 🔹 **Récupérer les restaurants avec filtres**
  Future<void> fetchRestaurants() async {
    setState(() => isLoading = true);

    try {
      Query query = FirebaseFirestore.instance.collection('restaurants');

      // ✅ Filtre par ville
      if (selectedCity != null && selectedCity!.isNotEmpty) {
        query = query.where('city', isEqualTo: selectedCity);
      }

      // ✅ Filtre par type de cuisine
      if (selectedCuisine != null && selectedCuisine!.isNotEmpty) {
        query = query.where('cuisineType', isEqualTo: selectedCuisine);
      }

      var querySnapshot = await query.get();

      List<Map<String, dynamic>> fetchedRestaurants = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        String restaurantName = data["name"] ?? "Nom inconnu";
        String cuisineType = data["cuisineType"]?.toString() ?? "Type inconnu";
        String sallePath = data["salle"] ?? "";
        String salleUrl = sallePath.isNotEmpty ? await getDownloadUrl(sallePath) : defaultImageUrl;

        fetchedRestaurants.add({
          "id": doc.id,
          "name": restaurantName,
          "cuisineType": cuisineType,
          "salle": salleUrl,
        });
      }

      if (mounted) {
        setState(() {
          restaurants = fetchedRestaurants;
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Erreur lors de la récupération des restaurants : $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// 🔹 **Récupère l’image de la salle depuis Firebase Storage**
  Future<String> getDownloadUrl(String filePath) async {
    if (filePath.isEmpty) return defaultImageUrl;
    if (filePath.startsWith("https://")) return filePath;

    try {
      final ref = FirebaseStorage.instance.ref(filePath.trim());
      return await ref.getDownloadURL();
    } catch (e) {
      print("❌ Erreur récupération URL Firebase: $e");
      return defaultImageUrl;
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
        actions: [
          // ✅ Icône de filtre par ville
          IconButton(
            icon: const Icon(Icons.location_city),
            tooltip: "Filtrer par ville",
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Sélectionner une ville"),
                  content: CityFilter(
                    selectedCity: selectedCity,
                    onCitySelected: (city) {
                      setState(() {
                        selectedCity = city;
                      });
                      fetchRestaurants();
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            },
          ),

          // ✅ Icône de filtre par type de cuisine
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            tooltip: "Filtrer par type de cuisine",
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Sélectionner un type de cuisine"),
                  content: CuisineFilter(
                    selectedCuisine: selectedCuisine,
                    onCuisineSelected: (cuisine) {
                      setState(() {
                        selectedCuisine = cuisine;
                      });
                      fetchRestaurants();
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            },
          ),
        ],
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
                            restaurant['cuisineType'] ?? "Type inconnu",
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
