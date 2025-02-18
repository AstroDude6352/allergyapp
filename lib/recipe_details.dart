import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const String spoonacularApiKey =
    'db9ded054e0d4745a6636108c3987351'; // Replace with your API key

class RecipeDetailScreen extends StatelessWidget {
  final int recipeId;

  const RecipeDetailScreen({Key? key, required this.recipeId})
      : super(key: key);

  Future<Map<String, dynamic>> fetchRecipeDetails(int recipeId) async {
    final url = Uri.parse(
        'https://api.spoonacular.com/recipes/$recipeId/information?includeNutrition=true&apiKey=$spoonacularApiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final int calories = (data['nutrition']?['nutrients']?.firstWhere(
              (nutrient) => nutrient['name'] == 'Calories',
              orElse: () => {'amount': null},
            )['amount'] as num?)
                ?.toInt() ??
            0;

        final int protein = (data['nutrition']?['nutrients']?.firstWhere(
              (nutrient) => nutrient['name'] == 'Protein',
              orElse: () => {'amount': null},
            )['amount'] as num?)
                ?.toInt() ??
            0;

        final int fat = (data['nutrition']?['nutrients']?.firstWhere(
              (nutrient) => nutrient['name'] == 'Fat',
              orElse: () => {'amount': null},
            )['amount'] as num?)
                ?.toInt() ??
            0;

        print(
            'Extracted from API -> Calories: $calories, Protein: $protein g, Fat: $fat g');

        return {
          'name': data['title'] ?? 'Unknown Recipe',
          'image': data['image'] ?? '',
          'rating': double.parse(((data['spoonacularScore'] ?? 0) / 20.0)
              .toStringAsFixed(1)), // Round rating to 1 decimal

          'calories': calories ?? 'N/A',
          'protein': protein ?? 'N/A',
          'fat': fat ?? 'N/A',
          'ingredients': data['extendedIngredients'] != null
              ? List<Map<String, dynamic>>.from(
                  data['extendedIngredients'].map((ingredient) => {
                        'name': ingredient['name'],
                        'quantity': ingredient['amount'],
                        'unit': ingredient['unit'] ?? '',
                      }))
              : [],
          'instructions': data['analyzedInstructions'] != null &&
                  data['analyzedInstructions'].isNotEmpty
              ? List<String>.from(data['analyzedInstructions'][0]['steps']
                  .map((step) => step['step'].toString()))
              : ['No instructions available.'],
        };
      } else {
        throw Exception('Failed to fetch recipe details');
      }
    } catch (e) {
      print('Error fetching recipe details: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1D1E33),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchRecipeDetails(recipeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No details available'));
          }

          final recipe = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              children: [
                // Recipe Image and Actions
                Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: recipe['image'],
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 40,
                      left: 16,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),

                // Recipe Details
                DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      // Title, Rating, and Nutrition Info
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe['name'],
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                RatingBar(
                                  initialRating: recipe['rating'],
                                  direction: Axis.horizontal,
                                  allowHalfRating: true,
                                  ignoreGestures: true, // Makes it read-only
                                  itemCount: 5,
                                  ratingWidget: RatingWidget(
                                    full: const Icon(Icons.star,
                                        color: Colors.amber),
                                    half: const Icon(Icons.star_half,
                                        color: Colors.amber),
                                    empty: const Icon(Icons.star_border,
                                        color: Colors.amber),
                                  ),
                                  itemSize: 20,
                                  onRatingUpdate: (double value) {},
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${recipe['rating']} stars',
                                  style: TextStyle(
                                      fontFamily: 'Nunito',
                                      color: Colors.yellow),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Nutrition Info Circles
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNutritionCircle(
                                    'Calories', recipe['calories'].toString()),
                                _buildNutritionCircle('Protein',
                                    '${recipe['protein'].toString()}g'),
                                _buildNutritionCircle(
                                    'Fat', '${recipe['fat'].toString()}g'),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // TabBar
                      const TabBar(
                        tabs: [
                          Tab(text: 'Ingredients'),
                          Tab(text: 'Recipe'),
                        ],
                        indicatorColor: Colors.greenAccent,
                        labelColor: Colors.greenAccent,
                        unselectedLabelColor: Colors.grey,
                      ),

                      // TabBarView
                      SizedBox(
                        height: 500, // Fixed height to prevent RenderBox error
                        child: TabBarView(
                          children: [
                            // Ingredients Tab
                            ListView(
                              padding: const EdgeInsets.all(16.0),
                              children: recipe['ingredients']
                                  .map<Widget>(
                                    (ingredient) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            ingredient['name'],
                                            style: TextStyle(
                                                fontFamily: 'Nunito',
                                                color: Colors.white),
                                          ),
                                          Text(
                                            '${ingredient['quantity']} ${ingredient['unit']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Nunito',
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),

                            SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: recipe['instructions']
                                      .map<Widget>(
                                        (step) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${recipe['instructions'].indexOf(step) + 1}. ',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Nunito',
                                                    color: Colors.white),
                                              ),
                                              Expanded(
                                                  child: Text(step,
                                                      style: TextStyle(

                                                          fontFamily: 'Nunito',
                                                          color:
                                                              Colors.white))),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNutritionCircle(String label, String value) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.greenAccent,
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
