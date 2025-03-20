import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stripe/service/firebase_service.dart';
import 'package:stripe/widgets/restaurant_comments.dart';
import '../models/restaurant_model.dart';
import '../widgets/restaurant_info_card.dart';
import '../service/coupon_service.dart';
import '../service/url_launcher_service.dart';
import '../service/storage_service.dart';
import '../widgets/qr_code_dialog.dart';
import '../widgets/image_carousel.dart';
import '../widgets/fullscreen_image.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String restaurantId;

  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UrlLauncherService _urlLauncherService = UrlLauncherService();
  final StorageService _imageService = StorageService();
  final CouponService _couponService = CouponService();

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

            /// ✅ Section Commentaires
            RestaurantComments(restaurantId: widget.restaurantId),
            const SizedBox(height: 16),

            /// ✅ Bouton pour ouvrir Google Maps avec l'adresse
            if (restaurant?.address != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.map),
                  label: const Text("Voir sur Google Maps"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () => _urlLauncherService.openGoogleMaps(restaurant!.address),
                ),
              ),
            const SizedBox(height: 16),


            /// ✅ Affichage du carrousel des plats
            if (plats.isNotEmpty)
              FutureBuilder<List<String>>(
                future: _imageService.getPlatsImages(plats),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Aucune image disponible."));
                  }

                  return ImageCarousel(
                    images: snapshot.data!,
                    onImageTap: (imagePath) { // ✅ Passe une fonction qui ouvre le FullScreenImage
                      showDialog(
                        context: context,
                        builder: (context) => FullScreenImage(imagePath: imagePath),
                      );
                    },
                  );
                },
              ),

            const SizedBox(height: 16),

            /// ✅ Affichage du coupon SEULEMENT si l'utilisateur est connecté
            if (userId != null)
              FutureBuilder<String>(
                future: _couponService.getOrCreateUserCoupon(widget.restaurantId, userId!),
                builder: (context, couponSnapshot) {
                  if (couponSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!couponSnapshot.hasData || couponSnapshot.data == "Aucun coupon disponible") {
                    return const Center(child: Text("Aucun coupon disponible."));
                  }

                  String couponCode = couponSnapshot.data!;

                  return FutureBuilder<String>(
                    future: _couponService.getCouponDescription(widget.restaurantId),
                    builder: (context, descSnapshot) {
                      if (descSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      String description = descSnapshot.data ?? "Pas de description disponible";

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
                              couponCode, // ✅ Affiche le code unique du coupon
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              description, // ✅ Affiche la description du coupon
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => showDialog(
                                context: context,
                                builder: (context) => QrCodeDialog(couponCode: couponCode),
                              ),
                              child: const Text("Afficher QR Code"),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
