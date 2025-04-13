import 'package:flutter/material.dart';

class FoodDetailView extends StatelessWidget {
  final Map<String, dynamic> foodData;
  final TextEditingController servingsController = TextEditingController();

  FoodDetailView({required this.foodData, required String foodName});

  List<String> parseStringList(String data) {
    // Remove wrapping c(...) and quotes, then split
    return data
        .replaceAll(RegExp(r'c\(|\)|\\n|\"'), '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final foodName = foodData['Name'] ?? 'Food Item';
    final nutrition = {
      'Calories': '${foodData['Calories_per_100g']} kcal',
      'Protein': '${foodData['ProteinContent_per_100g']} g',
      'Carbs': '${foodData['CarbohydrateContent_per_100g']} g',
      'Fat': '${foodData['FatContent_per_100g']} g',
    };

    final ingredients = parseStringList(foodData['RecipeIngredientParts'] ?? '');
    final quantities = parseStringList(foodData['RecipeIngredientQuantities'] ?? '');
    final instructions = parseStringList(foodData['RecipeInstructions'] ?? '');
    final description = foodData['Description'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(foodName),
        backgroundColor: const Color.fromRGBO(247, 186, 106, 1),
      ),
      backgroundColor: const Color.fromRGBO(250, 236, 217, 1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🍽 Description
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(description, style: const TextStyle(fontSize: 16)),
              ),

            /// 🧪 Nutrition Info
            const Text("Nutrition (per 100g):",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...nutrition.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text("${entry.key}: ${entry.value}", style: const TextStyle(fontSize: 15)),
            )),
            const SizedBox(height: 20),

            /// 🥕 Ingredients & Quantities
            const Text("Ingredients:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...List.generate(
              ingredients.length,
                  (index) {
                final ingredient = ingredients[index];
                final quantity = index < quantities.length ? quantities[index] : '-';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text("- $ingredient: $quantity", style: const TextStyle(fontSize: 15)),
                );
              },
            ),
            const SizedBox(height: 20),

            /// 🧑‍🍳 Instructions
            const Text("Instructions:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...instructions.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text("${entry.key + 1}. ${entry.value}", style: const TextStyle(fontSize: 15)),
            )),
            const SizedBox(height: 30),

            /// 🔢 Servings Input
            TextField(
              controller: servingsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Enter number of servings",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            /// ➕ Add Food Button
            ElevatedButton(
              onPressed: () {
                final servings = int.tryParse(servingsController.text) ?? 1;
                Navigator.pop(context, servings);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(232, 134, 7, 1),
                foregroundColor: Colors.white,
              ),
              child: const Text("Add Food"),
            ),
          ],
        ),
      ),
    );
  }
}
