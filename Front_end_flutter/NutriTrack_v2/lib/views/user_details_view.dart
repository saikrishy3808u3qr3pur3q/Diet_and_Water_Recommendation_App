import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_details_viewmodel.dart';
import 'dashboard_view.dart';

class UserDetailsView extends StatelessWidget {
  final InputDecorationTheme inputTheme = const InputDecorationTheme(
    labelStyle: TextStyle(color: Color(0xFFE88607)),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFFE88607)),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFFF7BA6A), width: 2),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final userDetailsViewModel = Provider.of<UserDetailsViewModel>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Theme(
      data: Theme.of(context).copyWith(inputDecorationTheme: inputTheme),
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF0DF),
        appBar: AppBar(
          title: const Text(
            "User Details",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFF7BA6A),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                userDetailsViewModel.saveUserDetails();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User details saved!')),
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardView()),
                );
              },
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: screenHeight * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!keyboardVisible) ...[
                    Text(
                      "Tell Us About Yourself!",
                      style: TextStyle(
                        fontSize: screenHeight * 0.05,
                        color: const Color(0xFFE88607),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],

                  TextField(
                    decoration: const InputDecoration(labelText: 'Height (cm)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => userDetailsViewModel.height = double.tryParse(value) ?? 0,
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  TextField(
                    decoration: const InputDecoration(labelText: 'Weight (kg)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => userDetailsViewModel.weight = double.tryParse(value) ?? 0,
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: userDetailsViewModel.dateOfBirth ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        userDetailsViewModel.dateOfBirth = picked;
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date of Birth'),
                      child: Text(
                        userDetailsViewModel.dateOfBirth != null
                            ? "${userDetailsViewModel.dateOfBirth!.toLocal()}".split(' ')[0]
                            : 'Select date',
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Blood Group'),
                    value: userDetailsViewModel.bloodGroup,
                    items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                        .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) => userDetailsViewModel.bloodGroup = value,
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Activity Level'),
                    value: userDetailsViewModel.activityLevel,
                    items: [
                      'Sedentary',
                      'Lightly Active',
                      'Moderately Active',
                      'Very Active',
                      'Extra Active'
                    ].map((value) => DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) => userDetailsViewModel.activityLevel = value,
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Gender'),
                    value: userDetailsViewModel.gender,
                    items: ['Male', 'Female'].map((value) => DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) => userDetailsViewModel.gender = value,
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  SwitchListTile(
                    title: const Text("Do you have a heart condition?"),
                    value: userDetailsViewModel.hasHeartCondition == 1,
                    onChanged: userDetailsViewModel.setHeartCondition,
                    activeColor: const Color(0xFFE88607),
                  ),
                  SwitchListTile(
                    title: const Text("Interested in muscle gain?"),
                    value: userDetailsViewModel.wantsMuscleGain == 1,
                    onChanged: userDetailsViewModel.setMuscleGainInterest,
                    activeColor: const Color(0xFFE88607),
                  ),
                  SwitchListTile(
                    title: const Text("Do you have diabetes?"),
                    value: userDetailsViewModel.hasDiabetes == 1,
                    onChanged: userDetailsViewModel.setDiabetes,
                    activeColor: const Color(0xFFE88607),
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  TextField(
                    decoration: const InputDecoration(labelText: 'Weight Goal (kg)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                    userDetailsViewModel.weightGoal = double.tryParse(value) ?? 0,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Weeks Needed'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                    userDetailsViewModel.weeks = int.tryParse(value) ?? 0,
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  Center(
                    child: SizedBox(
                      width: 160,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          userDetailsViewModel.saveUserDetails();
                          await userDetailsViewModel.makePrediction();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User details saved and prediction fetched!')),
                          );
                          Navigator.pushReplacementNamed(context, '/mainApp');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD196),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Continue",
                          style: TextStyle(
                            color: Color(0xFFE88607),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
