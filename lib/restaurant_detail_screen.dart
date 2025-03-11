import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String restaurantId;

  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? restaurant;
  bool isLoading = true;
  int _currentIndex = 0;
  final String defaultImageUrl = 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg';

  @override
  void initState() {
    super.initState();
    fetchRestaurantDetails();
  }

  /// 🔹 Récupérer les détails du restaurant depuis Firestore
  Future<void> fetchRestaurantDetails() async {
    try {
      DocumentSnapshot doc =
      await _firestore.collection('restaurants').doc(widget.restaurantId).get();

      if (doc.exists) {
        if (mounted) {
          setState(() {
            restaurant = doc.data() as Map<String, dynamic>;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// 🔹 Récupère les images des plats depuis Firebase Storage
  Future<List<String>> getPlatsImages(List<dynamic> plats) async {
    List<String> imageUrls = [];

    for (String filePath in plats) {
      if (filePath.startsWith("https://")) {
        imageUrls.add(filePath);
      } else {
        try {
          String url = await FirebaseStorage.instance.ref(filePath).getDownloadURL();
          imageUrls.add(url);
        } catch (e) {
          print("❌ Erreur récupération image: $e");
          imageUrls.add(defaultImageUrl);
        }
      }
    }
    return imageUrls;
  }

  /// 🔹 Ouvrir Google Maps avec l'adresse
  void openGoogleMaps(String address) async {
    final Uri googleMapsAppUri = Uri.parse("geo:0,0?q=${Uri.encodeComponent(address)}");
    final Uri googleMapsWebUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");

    if (await canLaunchUrl(googleMapsAppUri)) {
      await launchUrl(googleMapsAppUri);
    } else if (await canLaunchUrl(googleMapsWebUri)) {
      await launchUrl(googleMapsWebUri, mode: LaunchMode.externalApplication);
    } else {
      print("❌ Impossible d'ouvrir Google Maps");
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> plats = restaurant?['plats'] != null
        ? List<String>.from(restaurant!['plats'])
        : [];

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant?['name'] ?? 'Détails du restaurant'),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : restaurant == null
          ? const Center(child: Text("Restaurant introuvable."))
          : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ✅ Présentation du restaurant
            _buildRestaurantInfo(),

            const SizedBox(height: 16),

            // ✅ Bouton pour ouvrir Google Maps
            if (restaurant?['address'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.map),
                  label: const Text("Voir sur Google Maps"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: () => openGoogleMaps(restaurant!['address']),
                ),
              ),

            const SizedBox(height: 16),

            // ✅ Carrousel des plats avec affichage plein écran
            if (plats.isNotEmpty)
              FutureBuilder<List<String>>(
                future: getPlatsImages(plats),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _buildImageCarousel(snapshot.data!);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Présentation du restaurant
  Widget _buildRestaurantInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: Column(
          children: [
            // ✅ Nom du restaurant
            Text(
              restaurant?['name'] ?? "Nom inconnu",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // ✅ Description
            Text(
              restaurant?['description'] ?? "Description non disponible.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // ✅ Infos détaillées
            _buildInfoRow(Icons.restaurant, "Cuisine", restaurant?['cuisineType']),
            _buildInfoRow(Icons.location_pin, "Adresse", restaurant?['address']),
            _buildInfoRow(Icons.location_city, "Ville", restaurant?['city']),
            _buildInfoRow(Icons.access_time, "Horaires", restaurant?['hours']),
          ],
        ),
      ),
    );
  }

  /// 🔹 Générer une ligne d'info
  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return value != null
        ? Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange),
          const SizedBox(width: 8),
          Text("$label : ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    )
        : const SizedBox.shrink();
  }

  /// 🔹 Carrousel des plats avec zoom plein écran
  Widget _buildImageCarousel(List<String> images) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showFullImage(context, images[index]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _buildImageIndicator(images.length),
      ],
    );
  }

  /// 🔹 Indicateurs sous le carrousel
  Widget _buildImageIndicator(int length) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentIndex == index ? 12 : 8,
          height: _currentIndex == index ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentIndex == index ? Colors.orange : Colors.grey,
          ),
        );
      }),
    );
  }

  /// 🔹 Afficher une image en plein écran
  void _showFullImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: InteractiveViewer(
              child: Image.network(imagePath, fit: BoxFit.contain),
            ),
          ),
        );
      },
    );
  }
}
