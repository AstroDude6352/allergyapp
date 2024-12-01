import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'recipe_page.dart';

const globalApiKey = 'AIzaSyCzPlrOqftEAJSIkNFjzyKUr3pGKWPKl5o';
const List<String> allergenList = ['peanuts'];
const List<String> dietList = ['paleo', 'keto', 'low-carb', 'vegan', 'vegetarian', 'low-fat', 'atkins'];

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key); // Proper constructor with key

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Allergy Recipe App',
      home: RecipePage(), // Navigate to RecipePage when the app starts
    );
  }
}
