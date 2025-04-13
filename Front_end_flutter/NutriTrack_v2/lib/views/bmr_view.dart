import 'package:flutter/material.dart';
import 'package:nutritrack_v2/viewmodels/user_details_viewmodel.dart';
import 'package:provider/provider.dart';
import 'dietChart_view.dart';

int calculateAge(DateTime birthDate) {
  final today = DateTime.now();
  int age = today.year - birthDate.year;
  if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
    age--;
  }
  return age;
}

class BMRCalculator extends StatefulWidget {
  @override
  _BMRCalculatorState createState() => _BMRCalculatorState();
}

class _BMRCalculatorState extends State<BMRCalculator> {
  double _weightToLose = 0;
  double _weeksNeeded = 0;
  double _bmr = 0;
  double _calories = 0;
  String _activityLevel = 'Sedentary';

  void _calculateBMR(UserDetailsViewModel userViewModel) {
    double weight = userViewModel.weight ?? 0;
    double height = userViewModel.height ?? 0;
    int age = calculateAge(userViewModel.dateOfBirth ?? DateTime.now());
    String gender = userViewModel.gender ?? 'Male';

    setState(() {
      if (gender == 'Male') {
        _bmr = 66 + (6.23 * weight * 2.204) + (12.7 * height * 0.3937) -
            (6.8 * age);
      } else {
        _bmr = 655 + (4.35 * weight * 2.204) + (4.7 * height * 0.3937) -
            (4.7 * age);
      }

      setState(() {
        switch (_activityLevel) {
          case 'Sedentary':
            _calories = _bmr * 1.2;
            break;
          case 'Lightly Active':
            _calories = _bmr * 1.375;
            break;
          case 'Moderately Active':
            _calories = _bmr * 1.55;
            break;
          case 'Very Active':
            _calories = _bmr * 1.725;
            break;
          case 'Extra Active':
            _calories = _bmr * 1.9;
            break;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = Provider.of<UserDetailsViewModel>(
        context, listen: true);
    double weight = userViewModel.weight ?? 0;
    double height = userViewModel.height ?? 0;
    int age = calculateAge(userViewModel.dateOfBirth ?? DateTime.now());
    String gender = userViewModel.gender ?? 'Male';

    return GestureDetector(
      onTap: () {
        FocusScope.of(context)
            .unfocus(); // Unfocus text fields when tapping outside
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF0DF),
        appBar: AppBar(
          title: Text('BMR & Calorie Calculator',
              style: TextStyle(color: Colors.black)),
          backgroundColor: Color.fromRGBO(247, 186, 106, 1),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 18, color: Color.fromRGBO(232, 134, 7, 1)),
                  children: [
                    TextSpan(text: 'Weight: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '$weight kg'),
                  ],
                ),
              ),
              SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 18, color: Color.fromRGBO(232, 134, 7, 1)),
                  children: [
                    TextSpan(text: 'Height: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '$height cm'),
                  ],
                ),
              ),
              SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 18, color: Color.fromRGBO(232, 134, 7, 1)),
                  children: [
                    TextSpan(text: 'Age: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '$age years'),
                  ],
                ),
              ),
              SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 18, color: Color.fromRGBO(232, 134, 7, 1)),
                  children: [
                    TextSpan(text: 'Gender: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '$gender'),
                  ],
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _activityLevel,
                decoration: InputDecoration(
                  labelText: 'Activity Level',
                  labelStyle: TextStyle(color: Color.fromRGBO(232, 134, 7, 1)),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color.fromRGBO(247, 186, 106, 1), width: 2.0),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color.fromRGBO(232, 134, 7, 1), width: 2.5),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Color(0xFFFDF0DF),
                ),
                dropdownColor: Color(0xFFFDF0DF),
                items: [
                  'Sedentary',
                  'Lightly Active',
                  'Moderately Active',
                  'Very Active',
                  'Extra Active'
                ]
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _activityLevel = value!),
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Weight to Lose/Gain (kg)',
                  labelStyle: TextStyle(color: Color.fromRGBO(232, 134, 7, 1)),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color.fromRGBO(247, 186, 106, 1), width: 2.0),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color.fromRGBO(232, 134, 7, 1), width: 2.5),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Color(0xFFFDF0DF),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _weightToLose = double.tryParse(value) ?? 0;
                  });
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Weeks Needed',
                  labelStyle: TextStyle(color: Color.fromRGBO(232, 134, 7, 1)),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color.fromRGBO(247, 186, 106, 1), width: 2.0),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color.fromRGBO(232, 134, 7, 1), width: 2.5),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Color(0xFFFDF0DF),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _weeksNeeded = double.tryParse(value) ?? 0;
                  });
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(255, 209, 150, 1)),
                child: Text('Calculate',
                    style: TextStyle(color: Color.fromRGBO(232, 134, 7, 1))),
                onPressed: () => _calculateBMR(userViewModel),
              ),
              SizedBox(height: 24),
              Text('Your BMR: ${_bmr.toStringAsFixed(2)} cal/day',
                  style: TextStyle(
                    color: Color.fromRGBO(232, 134, 7, 1),
                    fontSize: 20,
                    fontWeight: FontWeight.bold
                  ), textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text('Calories to maintain weight: ${_calories.toStringAsFixed(
                  2)} cal/day',
                  style: TextStyle(
                    color: Color.fromRGBO(232, 134, 7, 1),
                    fontSize: 20,
                      fontWeight: FontWeight.bold
                  ), textAlign: TextAlign.center),
              SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(255, 209, 150, 1)),
                child: Text('Generate Diet Chart',
                    style: TextStyle(color: Color.fromRGBO(232, 134, 7, 1))),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DietChartPage(
                            weight: weight,
                            height: height,
                            age: age,
                            bmr: _bmr,
                            gender: gender,
                            weightToLose: _weightToLose,
                            weeksNeeded: _weeksNeeded,
                            activityLevel: _calories / _bmr,
                            calories: _calories,
                          ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}