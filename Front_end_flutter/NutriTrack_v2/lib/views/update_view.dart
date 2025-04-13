import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'login_view.dart';

class UpdateView extends StatefulWidget {
  @override
  _UpdateViewState createState() => _UpdateViewState();
}

class _UpdateViewState extends State<UpdateView> {
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  DateTime? selectedDate;
  String? selectedBloodGroup;
  String? selectedActivityLevel;
  bool isLoading = true;

  void fetchUserDetails(String uid) async {
    final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (docSnapshot.exists) {
      final userData = docSnapshot.data();
      if (userData != null) {
        setState(() {
          heightController.text = (userData['height'] ?? '').toString();
          weightController.text = (userData['weight'] ?? '').toString();
          selectedDate = userData['dateOfBirth'] != null ? DateTime.parse(userData['dateOfBirth']) : null;
          selectedBloodGroup = userData['bloodGroup'];
          selectedActivityLevel = userData['activityLevel'];
          isLoading = false;
        });
      }
    }
  }

  Future<void> updateUserDetails(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'height': double.tryParse(heightController.text),
      'weight': double.tryParse(weightController.text),
      'dateOfBirth': selectedDate != null ? selectedDate!.toIso8601String() : null,
      'bloodGroup': selectedBloodGroup,
      'activityLevel': selectedActivityLevel,
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Details updated successfully")));
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    if (authViewModel.user == null) {
      return Scaffold(
        body: Center(child: Text("No user logged in")),
      );
    }

    if (isLoading) {
      fetchUserDetails(authViewModel.user!.uid);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF0DF),
      appBar: AppBar(
        title: const Text("Update Details"),
        backgroundColor: Color.fromRGBO(247, 186, 106, 1),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authViewModel.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginView()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, ${authViewModel.user!.email}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromRGBO(232, 134, 7, 1)),
            ),
            const SizedBox(height: 16),
            _buildTextField(heightController, "Height (cm)"),
            const SizedBox(height: 16),
            _buildTextField(weightController, "Weight (kg)"),
            const SizedBox(height: 16),
            _buildDatePicker(context),
            const SizedBox(height: 16),
            _buildDropdown("Blood Group", ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'], selectedBloodGroup, (String? newValue) {
              setState(() {
                selectedBloodGroup = newValue;
              });
            }),
            const SizedBox(height: 16),
            _buildDropdown("Activity Level", ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active', 'Extra Active'], selectedActivityLevel, (String? newValue) {
              setState(() {
                selectedActivityLevel = newValue;
              });
            }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => updateUserDetails(authViewModel.user!.uid),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(255, 209, 150, 1),
                ),
                child: Text(
                  "Save Changes",
                  style: TextStyle(color: Color.fromRGBO(232, 134, 7, 1), fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.orange),
        border: OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromRGBO(247, 186, 106, 1), width: 2.0),
          borderRadius: BorderRadius.circular(10.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromRGBO(232, 134, 7, 1), width: 2.5),
          borderRadius: BorderRadius.circular(10.0),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            selectedDate = picked;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: 'Date of Birth'),
        child: Text(selectedDate != null ? "${selectedDate!.toLocal()}".split(' ')[0] : 'Select date'),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      value: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
