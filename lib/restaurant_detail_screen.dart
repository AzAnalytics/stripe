import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stripe/service/firebase_service.dart';
import '../models/restaurant_model.dart';
import '../widgets/restaurant_info_card.dart';
import '../service/coupon_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String restaurantId;

  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Restaurant? restaurant;
  bool isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    fetchUserId();
    fetchRestaurantDetails();
  }

  /// 🔹 Récupérer l'ID utilisateur Firebase
  void fetchUserId() {
    _auth.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          userId = user?.uid;
        });
      }
    });
  }

  /// 🔹 Récupérer les détails du restaurant
  Future<void> fetchRestaurantDetails() async {
    restaurant = await _firebaseService.getRestaurantDetails(widget.restaurantId);
    if (mounted) setState(() => isLoading = false);
  }

  /// 🔹 Ouvrir Google Maps avec l'adresse du restaurant
  void openGoogleMaps(String address) async {
    final Uri googleMapsAppUri = Uri.parse("geo:0,0?q=${Uri.encodeComponent(address)}");
    final Uri googleMapsWebUri =
    Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");

    if (await canLaunchUrl(googleMapsAppUri)) {
      await launchUrl(googleMapsAppUri);
    } else if (await canLaunchUrl(googleMapsWebUri)) {
      await launchUrl(googleMapsWebUri, mode: LaunchMode.externalApplication);
    } else {
      print("❌ Impossible d'ouvrir Google Maps");
    }
  }

  /// 🔹 Récupérer les images des plats depuis Firebase Storage
  Future<List<String>> getPlatsImages(List<String> plats) async {
    List<String> imageUrls = [];
    for (String filePath in plats) {
      try {
        String url = await FirebaseStorage.instance.ref(filePath).getDownloadURL();
        imageUrls.add(url);
      } catch (e) {
        print("❌ Erreur récupération image: $e");
      }
    }
    return imageUrls;
  }

  /// 🔹 Afficher le QR Code
  void _showQrCodeDialog(String couponCode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Votre QR Code"),
          content: SizedBox(
            width: 250,
            height: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QrImageView(
                  data: couponCode,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
                const SizedBox(height: 10),
                Text(
                  "Code : $couponCode",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer"),
            ),
          ],
        );
      },
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
            child: InteractiveViewer(
              child: Image.network(imagePath, fit: BoxFit.contain),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> plats = restaurant?.plats ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant?.name ?? 'Détails du restaurant'),
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
            RestaurantInfoCard(restaurant: restaurant!),
            const SizedBox(height: 16),

            /// ✅ Bouton pour ouvrir Google Maps avec l'adresse
            if (restaurant?.address != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.map),
                  label: const Text("Voir sur Google Maps"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: () => openGoogleMaps(restaurant!.address),
                ),
              ),

            const SizedBox(height: 16),

            /// ✅ Affichage du carrousel des plats
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

            const SizedBox(height: 16),

            /// ✅ Affichage du coupon SEULEMENT si l'utilisateur est connecté
            if (userId == null)
              const Center(
                child: Text("🔒 Connectez-vous pour voir votre coupon !"),
              )
            else
              FutureBuilder<String>(
                future: CouponService().getOrCreateUserCoupon(widget.restaurantId, userId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("❌ Impossible de récupérer le coupon."));
                  }

                  return Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Votre Coupon",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          snapshot.data!,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            _showQrCodeDialog(snapshot.data!);
                          },
                          child: const Text("Afficher QR Code"),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Afficher le carrousel des images des plats
  Widget _buildImageCarousel(List<String> images) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            itemCount: images.length,
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
      ],
    );
  }
}
