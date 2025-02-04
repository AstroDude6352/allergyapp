import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

const String openFoodFactsApiUrl = 'https://world.openfoodfacts.org/api/v0/product/'; // API URL for Open Food Facts

class RecipeScreen extends StatefulWidget {
  final String diet;
  final List<String> allergens;

  const RecipeScreen({Key? key, required this.diet, required this.allergens})
      : super(key: key);

  @override
  _RecipeScreenState createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  bool isFetching = true;
  Map<String, List<Map<String, dynamic>>> categorizedRecipes = {};

  @override
  void initState() {
    super.initState();
    fetchRecipes();
  }

  Future<void> fetchRecipes() async {
    final allergenString = widget.allergens.join(',');
    final url = Uri.parse(
        'https://api.spoonacular.com/recipes/complexSearch?'
            'diet=${widget.diet}&excludeIngredients=$allergenString&apiKey=db9ded054e0d4745a6636108c3987351'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final recipes = List<Map<String, dynamic>>.from(
          data['results'].map((recipe) => {
            'name': recipe['title'] ?? 'Unknown Recipe',
            'image': recipe['image'] ?? '',
            'category': _getRecipeCategory(recipe),
          }),
        );

        // Categorize the recipes
        Map<String, List<Map<String, dynamic>>> categorized = {};
        for (var recipe in recipes) {
          final category = recipe['category'];
          if (!categorized.containsKey(category)) {
            categorized[category] = [];
          }
          categorized[category]?.add(recipe);
        }

        setState(() {
          categorizedRecipes = categorized;
          isFetching = false;
        });
      } else {
        setState(() {
          isFetching = false;
        });
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      print('Error fetching recipes: $e');
      setState(() {
        isFetching = false;
      });
    }
  }

  String _getRecipeCategory(Map<String, dynamic> recipe) {
    String category = 'Miscellaneous'; // Default category
    List<String> tags = List<String>.from(recipe['tags'] ?? []);
    String title = recipe['title']?.toLowerCase() ?? '';

    // Check for known tags or keywords in the recipe title
    if (tags.contains('appetizer') || title.contains('appetizer')) {
      category = 'Appetizers';
    } else if (tags.contains('main course') || title.contains('main course') || title.contains('entree')) {
      category = 'Main Courses';
    } else if (tags.contains('dessert') || title.contains('dessert')) {
      category = 'Desserts';
    } else if (title.contains('salad')) {
      category = 'Salads';
    } else if (title.contains('soup')) {
      category = 'Soups';
    }

    // Additional check for unknown categories
    if (category == 'Miscellaneous' && title.isNotEmpty) {
      category = 'Miscellaneous';
    }

    return category;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipe Categories')),
      body: isFetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: categorizedRecipes.entries.map((entry) {
              final category = entry.key;
              final recipes = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 250,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          return GestureDetector(
                            onTap: () {
                              // Navigate to recipe details (could be another screen)
                            },
                            child: Card(
                              elevation: 5,
                              margin: const EdgeInsets.all(8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: recipe['image'],
                                    placeholder: (context, url) =>
                                    const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                                    height: 150,
                                    width: 150,
                                    fit: BoxFit.cover,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      recipe['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
