import 'package:flutter/material.dart';

class DataProvider with ChangeNotifier {
  String? _selectedDiet;
  List<String> _selectedAllergens = [];

  String? get selectedDiet => _selectedDiet;
  List<String> get selectedAllergens => _selectedAllergens;

  // Set the selected diet
  void setSelectedDiet(String? diet) {
    _selectedDiet = diet;
    notifyListeners();  // Notify listeners when the diet changes
  }

  // Add an allergen to the list
  void addAllergen(String allergen) {
    _selectedAllergens.add(allergen);
    notifyListeners();  // Notify listeners when an allergen is added
  }

  // Remove an allergen from the list
  void removeAllergen(String allergen) {
    _selectedAllergens.remove(allergen);
    notifyListeners();  // Notify listeners when an allergen is removed
  }

  // Set the selected allergens list
  void setSelectedAllergens(List<String> allergens) {
    _selectedAllergens = allergens;
    notifyListeners();  // Notify listeners when allergens list is updated
  }
}
