import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart'; // Your provider with userAllergens list

import 'home_screen.dart';
import 'reaction_log.dart';
import 'profile_screen.dart';

class AllergyInsightsScreen extends StatelessWidget {
  const AllergyInsightsScreen({super.key});

  final Map<String, String> allergenTips = const {
    'Milk': 'Try plant-based alternatives like oat or almond milk.',
    'Eggs': 'Chia seeds and flax eggs work as egg substitutes in baking.',
    'Fish': 'Algae-based omega-3s are a good alternative.',
    'Crustacean Shellfish':
        'Be cautious in seafood restaurants due to cross-contact.',
    'Tree Nuts': 'Try seeds like pumpkin or sunflower instead.',
    'Peanuts': 'Sunflower seed butter is a safe peanut-free option.',
    'Wheat': 'Choose gluten-free grains like rice or quinoa.',
    'Soybeans':
        'Legumes like lentils or chickpeas can work as protein sources.',
    'Sesame': 'Use olive or avocado oil instead of sesame oil.',
    'Gluten':
        'Gluten-free flours (like almond or coconut) are widely available.',
    'Corn': 'Avoid corn syrup; look for rice-based or potato-based snacks.',
    'Mustard': 'Check sauces and dressings for hidden mustard.',
    'Celery': 'Common in stocks—look for "celery-free" labeling.',
    'Sulfites': 'Often in dried fruits and wines—read labels carefully.',
    'Alcohol':
        'Some beverages contain gluten or sulfites—opt for pure spirits.',
    'Artificial Food Coloring': 'Avoid processed foods—look for natural dyes.',
    'Preservatives':
        'Fresh foods are best—check for "no preservatives" labels.',
    'Gelatin': 'Plant-based gelatin alternatives include agar agar.',
    'Yeast': 'Avoid baked goods and fermented items—check with your doctor.',
  };

  final Map<String, List<String>> alternativeSuggestions = const {
    'Milk': ['Oat milk', 'Almond milk', 'Coconut milk'],
    'Eggs': ['Chia seeds', 'Flax eggs', 'Applesauce'],
    'Peanuts': ['Sunflower seed butter', 'Pumpkin seed butter'],
    'Wheat': ['Rice flour', 'Quinoa', 'Buckwheat'],
    'Soybeans': ['Lentils', 'Chickpeas', 'Pea protein'],
    'Tree Nuts': ['Pumpkin seeds', 'Sunflower seeds'],
    'Fish': ['Algae oil (omega-3)', 'Tofu (if not allergic to soy)'],
    'Gluten': ['Brown rice', 'Corn flour', 'Sorghum'],
    'Alcohol': ['Mocktails', 'Kombucha (watch for fermentation if sensitive)'],
    'Gelatin': ['Agar agar', 'Pectin', 'Carrageenan'],
  };

  final int _currentIndex = 2; // Insights is index 2

  void _onNavBarTap(BuildContext context, int index) {
    if (index == _currentIndex) return;

    Widget destination;
    switch (index) {
      case 0:
        destination = const HomeScreen();
        break;
      case 1:
        destination = const ReactionLogScreen();
        break;
      case 2:
        destination = const AllergyInsightsScreen();
        break;
      case 3:
        destination = const ProfileScreen();
        break;
      default:
        destination = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAllergens = context.watch<DataProvider>().allergens;
    final allergenKeys = userAllergens.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1D1E33),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Allergy Insights',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.greenAccent,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E2F45),
        elevation: 4,
      ),
      body: userAllergens.isEmpty || userAllergens.containsKey('None of these')
          ? const Center(
              child: Text(
                'No allergens saved.\nUpdate your profile to get personalized insights.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: allergenKeys.length,
              itemBuilder: (context, index) {
                final allergen = allergenKeys[index];
                final tips = allergenTips[allergen] ??
                    'Watch for $allergen in processed and prepared foods.';
                final alternatives = alternativeSuggestions[allergen] ??
                    [
                      'No specific alternatives available — consult a dietitian.'
                    ];

                return Card(
                  color: const Color(0xFF2E2F45),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          allergen,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tip: $tips',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Safe Alternatives:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueAccent,
                          ),
                        ),
                        ...alternatives.map(
                          (alt) => Text(
                            '- $alt',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2E2F45),
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white70,
        currentIndex: _currentIndex,
        onTap: (index) => _onNavBarTap(context, index),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Reactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
