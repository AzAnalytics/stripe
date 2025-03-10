import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// 🔹 Ouvrir Google Maps avec l'adresse du restaurant
  void _openGoogleMaps(String address) async {
    final Uri googleMapsUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");

    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir Google Maps")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> images = restaurant?['plats'] != null
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
          : Column(
        children: [
          const SizedBox(height: 16),

          // 🔹 Carrousel des plats
          if (images.isNotEmpty) _buildImageCarousel(images),

          const SizedBox(height: 16),

          // 🔹 Bouton pour ouvrir Google Maps avec l'adresse du restaurant
          if (restaurant?['address'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text("Voir sur Google Maps"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                onPressed: () => _openGoogleMaps(restaurant!['address']),
              ),
            ),
        ],
      ),
    );
  }

  /// 🔹 Widget du Carrousel d'images des plats
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
                onTap: () => _showFullImage(images[index]),
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
  void _showFullImage(String imagePath) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: InteractiveViewer(child: Image.network(imagePath, fit: BoxFit.contain)),
          ),
        );
      },
    );
  }
}