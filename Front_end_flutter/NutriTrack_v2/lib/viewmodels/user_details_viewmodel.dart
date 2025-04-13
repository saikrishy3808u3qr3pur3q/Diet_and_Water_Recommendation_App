import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/services/firebase_firestore_service.dart';
import '../core/services/firebase_auth_service.dart';
import 'package:http/http.dart' as http;

class UserDetailsViewModel extends ChangeNotifier {
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  double height = 0;
  double weight = 0;
  DateTime? dateOfBirth;
  String? bloodGroup;
  String? activityLevel;
  String? gender;

  // ✅ New fields
  int hasHeartCondition = 0;
  int wantsMuscleGain = 0;
  int hasDiabetes = 0;
  double weightGoal = 0;
  int weeks = 0;

  Map<String, dynamic>? predictionResponse;

  bool isLoading = false;

  UserDetailsViewModel() {
    loadUserDetails();
  }

  // ✅ Setters for boolean flags
  void setHeartCondition(bool value) {
    hasHeartCondition = value ? 1 : 0;
    notifyListeners();
  }

  void setMuscleGainInterest(bool value) {
    wantsMuscleGain = value ? 1 : 0;
    notifyListeners();
  }

  void setDiabetes(bool value) {
    hasDiabetes = value ? 1 : 0;
    notifyListeners();
  }

  void setWeightGoal(double value) {
    weightGoal = value;
    notifyListeners();
  }

  void setWeeks(int value) {
    weeks = value;
    notifyListeners();
  }

  Future<void> saveUserDetails() async {
    final user = _authService.getCurrentUser();
    if (user == null) return;

    if (height == 0 || weight == 0 || dateOfBirth == null || bloodGroup == null || activityLevel == null || gender == null) {
      return;
    }

    final userDetails = {
      'height': height,
      'weight': weight,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'bloodGroup': bloodGroup,
      'activityLevel': activityLevel,
      'gender': gender,
      'hasHeartCondition': hasHeartCondition,
      'wantsMuscleGain': wantsMuscleGain,
      'hasDiabetes': hasDiabetes,
      'weightGoal': weightGoal,
      'weeks': weeks,
    };

    try {
      await _firestoreService.saveUserDetails(user.uid, userDetails);
    } catch (e) {
      print("Error saving user details: $e");
    }
    notifyListeners();
  }

  Future<void> loadUserDetails() async {
    final user = _authService.getCurrentUser();
    if (user == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final userDetails = await _firestoreService.getUserDetails(user.uid);
      if (userDetails != null) {
        height = (userDetails['height'] ?? 0).toDouble();
        weight = (userDetails['weight'] ?? 0).toDouble();
        dateOfBirth = userDetails['dateOfBirth'] != null ? DateTime.parse(userDetails['dateOfBirth']) : null;
        bloodGroup = userDetails['bloodGroup'];
        activityLevel = userDetails['activityLevel'];
        gender = userDetails['gender'];
        hasHeartCondition = userDetails['hasHeartCondition'] ?? 0;
        wantsMuscleGain = userDetails['wantsMuscleGain'] ?? 0;
        hasDiabetes = userDetails['hasDiabetes'] ?? 0;

        weightGoal = (userDetails['weightGoal'] ?? 0).toDouble();
        weeks = userDetails['weeks'] ?? 0;
      }
    } catch (e) {
      print("Error loading user details: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> makePrediction() async {
    try {
      final bmr = 10 * weight + 6.25 * height - 5 * 25 + (gender == "Male" ? 5 : -161);
      final bmi = weight / ((height / 100) * (height / 100));
      final activityMultiplier = {
        "Sedentary": 1.2,
        "Lightly Active": 1.375,
        "Moderately Active": 1.55,
        "Very Active": 1.725,
        "Extra Active": 1.9
      }[activityLevel] ?? 1.2;

      final body = {
        "attributes": {
          "age": 25, // Replace with real DOB calculation if needed
          "weight": weight,
          "height": height / 100,
          "BMI": double.parse(bmi.toStringAsFixed(2)),
          "BMR": double.parse(bmr.toStringAsFixed(2)),
          "activity_level": activityMultiplier,
          "gender_F": gender == "Female" ? 1 : 0,
          "gender_M": gender == "Male" ? 1 : 0,
        },
        "weight_goal_kg": weightGoal-weight,
        "weeks": weeks,
        "heart_condition": hasHeartCondition == 1,
        "db": hasDiabetes == 1,
        "mg": wantsMuscleGain == 1,
        "wl": wantsMuscleGain == 0
      };

      print("Sending prediction request with body:");
      print(jsonEncode(body));

      final res = await http.post(
        Uri.parse('http://10.0.2.2:5000/predict'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        predictionResponse = jsonDecode(res.body);
        notifyListeners();
      } else {
        throw Exception("Prediction failed: ${res.body}");
      }
    } catch (e) {
      print("Error during prediction: $e");
    }
  }
}
