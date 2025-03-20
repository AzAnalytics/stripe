import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CuisineFilter extends StatelessWidget {
  final String? selectedCuisine;
  final Function(String?) onCuisineSelected;

  const CuisineFilter({
    super.key,
    required this.selectedCuisine,
    required this.onCuisineSelected,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        List<String> cuisines = snapshot.data!.docs
            .map((doc) => doc['cuisineType'].toString())
            .toSet()
            .toList();

        return DropdownButtonFormField<String>(
          value: selectedCuisine,
          hint: const Text("Sélectionner un type de cuisine"),
          onChanged: (value) => onCuisineSelected(value),
          items: cuisines.map((cuisine) {
            return DropdownMenuItem(value: cuisine, child: Text(cuisine));
          }).toList(),
        );
      },
    );
  }
}
