import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const globalApiKey = 'AIzaSyCzPlrOqftEAJSIkNFjzyKUr3pGKWPKl5o';
const List<String> dietList = [
  'paleo',
  'keto',
  'low-carb',
  'vegan',
  'vegetarian',
  'low-fat',
  'atkins'
];

const List<String> allergenList = [
  'Milk',
  'Eggs',
  'Fish',
  'Crustacean shellfish',
  'Tree nuts',
  'Peanuts',
  'Wheat',
  'Soybeans',
  'Sesame seeds',
  'Mustard',
  'Celery',
  'Lupin',
  'Buckwheat',
  'Corn',
  'Poppy seeds',
  'Chili peppers',
  'Triticale',
  'Fruits',
  'Vegetables',
  'Gelatin',
  'Spices',
  'Chocolate',
  'Alcohol',
  'Fennel',
  'Coconut',
  'Rice',
  'Peas',
  'Spinach',
  'Asparagus',
  'Quinoa',
  'Tomato',
  'Dairy products',
  'Seaweed',
  'Sulfites',
  'Avocados',
  'Mangoes',
  'Honey',
  'Wormwood',
  'Cashews',
  'Pistachios',
  'Sunflower seeds',
];

List<String> selectedAllergens = [];
String? selectedDiet;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QuizScreen(),
    );
  }
}

class QuizScreen extends StatefulWidget {
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  String? selectedOption;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1E33),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          width: (constraints.maxWidth *
                              (currentQuestionIndex + 1) /
                              2), // Only 2 steps (Diet and Summary)
                          decoration: BoxDecoration(
                            color: Colors.pink,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Diet Question
              if (currentQuestionIndex == 0) ...[
                Text(
                  "Question 1/2",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "What is your preferred diet?",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Poppins",
                  ),
                ),
                const SizedBox(height: 30),
                Column(
                  children: dietList.map((diet) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDiet = diet;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                        decoration: BoxDecoration(
                          color: selectedDiet == diet
                              ? Colors.blueAccent
                              : const Color(0xFF1D1E33),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.blueAccent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                diet,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            if (selectedDiet == diet)
                              const Icon(Icons.check_circle,
                                  color: Colors.white),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ]
              // Final Step: Review and update allergen list
              else ...[
                Text(
                  "Final Step: Review and update your allergen list",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allergenList.map((allergen) {
                    final isSelected = selectedAllergens.contains(allergen);
                    return FilterChip(
                      label: Text(allergen),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedAllergens.add(allergen);
                          } else {
                            selectedAllergens.remove(allergen);
                          }
                        });
                      },
                      selectedColor: Colors.blueAccent,
                      backgroundColor: Colors.grey[600],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    );
                  }).toList(),
                ),
              ],
              const Spacer(),

              // Next Button
              ElevatedButton(
                onPressed: () {
                  if (currentQuestionIndex == 0) {
                    if (selectedDiet != null) {
                      setState(() {
                        currentQuestionIndex++;
                      });
                    }
                  } else {
                    // Final summary confirmation
                    print("Final Selected Diet: $selectedDiet");
                    print("Final Selected Allergens: $selectedAllergens");
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Thank You"),
                        content: const Text("Your preferences have been saved."),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Optionally navigate to another screen or restart
                            },
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Center(
                  child: Text(
                    currentQuestionIndex == 0 ? "Next" : "Finish",
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
