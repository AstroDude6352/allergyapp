import 'package:flutter/foundation.dart';

class DataProvider extends ChangeNotifier {
  String? _selectedDiet;
  List<String> _selectedAllergens = [];

  String? get selectedDiet => _selectedDiet;
  List<String> get selectedAllergens => _selectedAllergens;

  void updateUserPreferences(String? diet, List<String> allergens) {
    _selectedDiet = diet;
    _selectedAllergens = List.from(allergens);
    notifyListeners();
  }
}
