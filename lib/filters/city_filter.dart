import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CityFilter extends StatelessWidget {
  final String? selectedCity;
  final Function(String?) onCitySelected;

  const CityFilter({
    super.key,
    required this.selectedCity,
    required this.onCitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        List<String> cities = snapshot.data!.docs
            .map((doc) => doc['city'].toString())
            .toSet()
            .toList();

        return DropdownButtonFormField<String>(
          value: selectedCity,
          hint: const Text("Sélectionner une ville"),
          onChanged: (value) => onCitySelected(value),
          items: cities.map((city) {
            return DropdownMenuItem(value: city, child: Text(city));
          }).toList(),
        );
      },
    );
  }
}
