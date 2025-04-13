import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserDetails(String uid, Map<String, dynamic> userDetails) async {
    try {
      await _firestore.collection('users').doc(uid).set(userDetails, SetOptions(merge: true));
    } catch (e) {
      print("Error in saving user details: $e");
    }
  }

  Future<Map<String, dynamic>?> getUserDetails(String uid) async {
    try {
      DocumentSnapshot document = await _firestore.collection('users').doc(uid).get();
      return document.exists ? document.data() as Map<String, dynamic> : null;
    } catch (e) {
      print("Error in fetching user details: $e");
      return null;
    }
  }
}