import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'recipe_view.dart';

class DietChartPage extends StatefulWidget {
  final double weight;
  final double height;
  final int age;
  final double bmr;
  final String gender;
  final double weightToLose;
  final double weeksNeeded;
  final double activityLevel;
  final double calories;

  const DietChartPage({
    Key? key,
    required this.weight,
    required this.height,
    required this.age,
    required this.bmr,
    required this.gender,
    required this.weightToLose,
    required this.weeksNeeded,
    required this.activityLevel,
    required this.calories,
  }) : super(key: key);

  @override
  _DietChartPageState createState() => _DietChartPageState();
}

class _DietChartPageState extends State<DietChartPage> {
  Map<String, dynamic>? recommendation;

  @override
  void initState() {
    super.initState();
    fetchRecommendation();
  }

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> fetchRecommendation() async {
    final url = Uri.parse('http://10.0.2.2:5000/recommend');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          recommendation = jsonDecode(response.body);
        });
      } else {
        print('Failed to get recommendation. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching recommendation: $e');
    }
  }


  List<String> _parseList(dynamic input) {
    if (input is String) {
      input = input.replaceAll('[', '').replaceAll(']', '').replaceAll("'", '').trim();
      return input.isNotEmpty ? input.split(',').map((e) => e.trim()).toList() : [];
    } else if (input is List) {
      return List<String>.from(input);
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(250, 236, 217, 1),
      appBar: AppBar(
        title: const Text('Personalized Diet Plan'),
        backgroundColor: Color.fromRGBO(247, 186, 106, 1),
      ),
      body: recommendation == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recommended Meals',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ...recommendation!.entries.map((entry) {
                      final mealType = entry.key;
                      final mealData = entry.value;
                      final name = mealData['name'] ?? 'Unknown';
                      final macros = mealData['estimated_macros'] ?? {};
                      final quantity = mealData['estimated_quantity_g']?.toStringAsFixed(2) ?? 'N/A';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Text(capitalize(mealType),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Name: $name'),
                          Text('Quantity: $quantity g'),
                          ...macros.entries.map((macro) {
                            return Text(
                                '${capitalize(macro.key.replaceAll("_", " "))}: ${macro.value}');
                          }),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}