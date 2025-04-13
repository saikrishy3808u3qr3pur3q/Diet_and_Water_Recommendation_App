import 'package:flutter/material.dart';

class ERecipePage extends StatelessWidget {
  final String foodName;
  final String description;
  final List<String> steps;
  final List<String> ingredients;

  const ERecipePage({
    Key? key,
    required this.foodName,
    required this.description,
    required this.steps,
    required this.ingredients,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(250, 236, 217, 1),
      appBar: AppBar(
        title: Text(foodName),
        backgroundColor: Color.fromRGBO(247, 186, 106, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              Text(
                description,
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 20),

              // Ingredients List
              const Text(
                'Ingredients',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...ingredients.map((ingredient) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('- $ingredient', style: const TextStyle(fontSize: 16)),
                );
              }).toList(),
              const SizedBox(height: 20),

              // Preparation Steps
              const Text(
                'Preparation Steps',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...steps.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text('${entry.key + 1}. ${entry.value}', style: const TextStyle(fontSize: 16)),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}