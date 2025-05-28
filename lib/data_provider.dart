import 'package:flutter/foundation.dart';

class DataProvider extends ChangeNotifier {
  String? _selectedTaste;
  Map<String, String> _allergens = {}; // allergen name -> severity

  String? get selectedTaste => _selectedTaste;
  Map<String, String> get allergens => _allergens;

  void updateUserPreferences(
    String? taste,
    Map<String, String> allergens, // includes severity
  ) {
    _selectedTaste = taste;
    _allergens = allergens;
    notifyListeners();
  }
}
