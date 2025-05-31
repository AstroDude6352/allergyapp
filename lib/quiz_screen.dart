import 'package:allergy_app/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:allergy_app/data_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<String> tastePreferences = [
  'Spicy',
  'Sweet',
  'Savory',
  'Salty',
  'Sour',
  'Bitter',
  'Umami',
  'Mild',
  'No Preference',
];

const List<String> allergenList = [
  'Milk',
  'Eggs',
  'Fish',
  'Crustacean Shellfish',
  'Tree Nuts',
  'Peanuts',
  'Wheat',
  'Soybeans',
  'Sesame',
  'Gluten',
  'Corn',
  'Mustard',
  'Celery',
  'Lupin',
  'Sulfites',
  'Mollusks',
  'Legumes (other than peanuts/soybeans)',
  'Coconut',
  'Strawberries',
  'Kiwi',
  'Bananas',
  'Avocado',
  'Citrus Fruits',
  'Tomatoes',
  'Garlic',
  'Onions',
  'Bell Peppers',
  'Eggplant',
  'Mushrooms',
  'Chia Seeds',
  'Sunflower Seeds',
  'Poppy Seeds',
  'Fennel',
  'Artificial Food Coloring',
  'Preservatives',
  'Gelatin',
  'Yeast',
  'Alcohol',
  'Other',
  'None of these'
];

const List<String> severityLevels = ['Mild', 'Moderate', 'Severe'];

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  String? selectedTaste;
  Map<String, String> allergenSeverities = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1E33),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        width: (constraints.maxWidth *
                            (currentQuestionIndex + 1) /
                            2),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),

                if (currentQuestionIndex == 0) ...[
                  const Text("Question 1/2",
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 10),
                  const Text(
                    "What are your taste preferences?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Poppins",
                    ),
                  ),
                  const SizedBox(height: 30),
                  Column(
                    children: tastePreferences.map((taste) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTaste = taste;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 20),
                          decoration: BoxDecoration(
                            color: selectedTaste == taste
                                ? Colors.blueAccent
                                : const Color(0xFF1D1E33),
                            borderRadius: BorderRadius.circular(25),
                            border:
                                Border.all(color: Colors.blueAccent, width: 2),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  taste,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: "Nunito",
                                      fontSize: 18),
                                ),
                              ),
                              if (selectedTaste == taste)
                                const Icon(Icons.check_circle,
                                    color: Colors.white),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ] else ...[
                  const Text(
                    "Select your allergens and their severity:",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: allergenList.map((allergen) {
                      bool isSelected =
                          allergenSeverities.containsKey(allergen);
                      return Card(
                        color: const Color(0xFF2E2F45),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  allergen,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white70,
                                    fontFamily: 'Nunito',
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              DropdownButton<String>(
                                dropdownColor: const Color(0xFF2E2F45),
                                value: allergenSeverities[allergen],
                                hint: const Text(
                                  'Severity',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                iconEnabledColor: Colors.white,
                                items: severityLevels.map((level) {
                                  return DropdownMenuItem<String>(
                                    value: level,
                                    child: Text(level,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    if (value != null) {
                                      allergenSeverities[allergen] = value;
                                    } else {
                                      allergenSeverities.remove(allergen);
                                    }
                                  });
                                },
                              ),
                              Checkbox(
                                activeColor: Colors.blueAccent,
                                value: isSelected,
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      allergenSeverities[allergen] ??=
                                          severityLevels[0];
                                    } else {
                                      allergenSeverities.remove(allergen);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    if (currentQuestionIndex == 0) {
                      if (selectedTaste != null) {
                        setState(() {
                          currentQuestionIndex++;
                        });
                      }
                    } else {
                      markQuizAsCompleted();
                      Provider.of<DataProvider>(context, listen: false)
                          .updateUserPreferences(
                        selectedTaste,
                        allergenSeverities,
                      );
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                      });

                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
      ),
    );
  }
}

Future<void> markQuizAsCompleted() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('quizCompleted', true);
}
