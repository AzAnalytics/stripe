import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';

class RestaurantInfoCard extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantInfoCard({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1)],
      ),
      child: Column(
        children: [
          Text(restaurant.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(restaurant.description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.restaurant, "Cuisine", restaurant.cuisineType),
          _buildInfoRow(Icons.location_pin, "Adresse", restaurant.address),
          _buildInfoRow(Icons.location_city, "Ville", restaurant.city),
          _buildInfoRow(Icons.access_time, "Horaires", restaurant.hours),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange),
          const SizedBox(width: 8),
          Text("$label : ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}
