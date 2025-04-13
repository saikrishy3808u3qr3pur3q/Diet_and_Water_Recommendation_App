import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/services/firebase_auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? user;

  Future<bool> signUp(String email, String password) async {
    final userCredential = await _authService.signUpWithEmail(email, password);
    if (userCredential != null) {
      user = UserModel(
        uid: userCredential.uid,
        email: userCredential.email!,
        height: null,
        weight: null,
        dateOfBirth: null,
        bloodGroup: null,
        activityLevel: null,
        gender: null,
        hasHeartCondition: null,
        wantsMuscleGain: null,
        hasDiabetes: null,
        weightGoal: null,
        weeks: null,
      );

      // Store user data in Firestore with all fields
      await _firestore.collection('users').doc(user!.uid).set(user!.toJson());

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> login(String email, String password) async {
    final userCredential = await _authService.signInWithEmail(email, password);
    if (userCredential != null) {
      // ✅ Fetch full user data from Firestore
      final userDoc = await _firestore.collection('users').doc(userCredential.uid).get();
      if (userDoc.exists) {
        user = UserModel.fromJson(userDoc.data()!);
      } else {
        // fallback if document is missing
        user = UserModel(uid: userCredential.uid, email: userCredential.email!);
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() async {
    await _authService.signOut();
    user = null;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    return await _authService.resetPassword(email);
  }
}
