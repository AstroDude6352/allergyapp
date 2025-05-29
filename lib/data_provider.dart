import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DataProvider extends ChangeNotifier {
  String? _selectedTaste;
  Map<String, String> _allergens = {}; // allergen name -> severity

  String? get selectedTaste => _selectedTaste;
  Map<String, String> get allergens => _allergens;

  // Load user preferences from Firestore
  Future<void> loadUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      _selectedTaste = data?['selectedTaste'];
      Map<String, dynamic>? allergenData = data?['allergens'];
      if (allergenData != null) {
        _allergens =
            allergenData.map((key, value) => MapEntry(key, value.toString()));
      }
      notifyListeners();
    }
  }

  // Save user preferences to Firestore
  Future<void> updateUserPreferences(
    String? taste,
    Map<String, String> allergens,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _selectedTaste = taste;
    _allergens = allergens;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'selectedTaste': taste,
          'allergens': allergens,
        },
        SetOptions(
            merge: true)); // merge so it won't overwrite other data if present

    notifyListeners();
  }
}
