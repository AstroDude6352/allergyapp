import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'main.dart';
import 'dart:convert';

const List<String> allergenList = ['peanuts'];
const List<String> dietList = [
  'paleo',
  'keto',
  'low-carb',
  'vegan',
  'vegetarian',
  'low-fat',
  'atkins'
];

String allergenString = allergenList.join(', ');
String dietString = dietList.join(', ');

class RecipePage extends StatefulWidget {
  @override
  _RecipePageState createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  String foodName = '';
  List<String> ingredients = [];
  List<String> steps = [];

  @override
  void initState() {
    super.initState();
    fetchCookieRecipe();
  }

  void fetchCookieRecipe() async {
    final schema = Schema.array(
      description: 'List of recipes with ingredients',
      items: Schema.object(properties: {
        'foodName':
            Schema.string(description: 'Name of the food.', nullable: false),
        'ingredientList': Schema.array(
          description: 'List of ingredients for the food.',
          items: Schema.string(description: 'An ingredient.', nullable: false),
          nullable: false,
        ),
        'steps': Schema.array(
          description: 'List of steps for the food.',
          items: Schema.string(description: 'A step.', nullable: false),
          nullable: false,
        ),
      }, requiredProperties: [
        'foodName',
        'ingredientList',
        'steps'
      ]),
    );

    final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: globalApiKey,
        generationConfig: GenerationConfig(
            responseMimeType: 'application/json', responseSchema: schema));

    final prompt =
        'List exactly 1 recipe that does not contain milk and fits in one of the following diets: vegan. Provide the ingredients and steps for how to make it.' +
            'List exactly 1 recipe that does not contain egg and fits in one of the following diets: vegetarian. Provide the ingredients and steps for how to make it.';

    final response = await model.generateContent([Content.text(prompt)]);
    print(response.text);
    final responseDisplay = response.text;
    if (responseDisplay != null) {
      try {
        // Decode the JSON string into a Map
        final recipeData = jsonDecode(responseDisplay) as List<dynamic>;
        final recipe =
            recipeData.isNotEmpty ? recipeData[0] as Map<String, dynamic> : {};

        setState(() {
          foodName = recipe['foodName'] ?? ''; // Safely access foodName
          ingredients = List<String>.from(
              recipe['ingredientList'] ?? []); // Safely convert to list
          steps = List<String>.from(
              recipe['steps'] ?? []); // Safely convert to list
        });
      } catch (e) {
        print('Error parsing recipe: $e');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipe Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: foodName.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    foodName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ingredients:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ...ingredients.map((ingredient) => Text('• $ingredient')),
                  const SizedBox(height: 16),
                  const Text(
                    'Steps:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ...steps.map((step) => Text('• $step')),
                ],
              )
            : const Center(
                child:
                    CircularProgressIndicator()), // Show loading while fetching data
      ),
    );
  }
}
