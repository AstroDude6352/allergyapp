import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:swipe_cards/swipe_cards.dart';

const String spoonacularApiKey = 'db9ded054e0d4745a6636108c3987351'; // Replace with your API key

class RecipeScreen extends StatefulWidget {
  final String diet;
  final List<String> allergens;

  const RecipeScreen({Key? key, required this.diet, required this.allergens})
      : super(key: key);

  @override
  _RecipeScreenState createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  List<SwipeItem> swipeItems = [];
  late MatchEngine matchEngine;
  bool isFetching = true;

  @override
  void initState() {
    super.initState();
    fetchRecipes();
  }

  Future<void> fetchRecipes() async {
    final allergenString = widget.allergens.join(', ');
    final url = Uri.parse(
      'https://api.spoonacular.com/recipes/complexSearch?'
          'diet=${widget.diet}&excludeIngredients=$allergenString&apiKey=$spoonacularApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final recipes = List<Map<String, dynamic>>.from(
          data['results'].map((recipe) => {
            'id': recipe['id'],
            'name': recipe['title'],
            'image': recipe['image'] ?? '',
          }),
        );

        setState(() {
          swipeItems = recipes
              .map(
                (recipe) => SwipeItem(
              content: recipe,
              likeAction: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Liked: ${recipe['name']}")),
                );
              },
              nopeAction: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Disliked: ${recipe['name']}")),
                );
              },
            ),
          )
              .toList();
          matchEngine = MatchEngine(swipeItems: swipeItems);
          isFetching = false;
        });
      } else {
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      print('Error fetching recipes: $e');
      setState(() {
        isFetching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Swipe Recipes')),
      body: isFetching
          ? const Center(child: CircularProgressIndicator())
          : swipeItems.isEmpty
          ? const Center(child: Text('No recipes found'))
          : Center(
        child: SwipeCards(
          matchEngine: matchEngine,
          itemBuilder: (context, index) {
            final recipe = swipeItems[index].content as Map<String, dynamic>;
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RecipeDetailScreen(recipeId: recipe['id']),
                  ),
                );
              },
              child: Card(
                elevation: 5,
                margin: const EdgeInsets.all(16.0),
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
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        recipe['name'],
                        style: const TextStyle(
                          fontSize: 20,
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
          onStackFinished: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("You've swiped through all recipes!"),
              ),
            );
          },
          upSwipeAllowed: false, // Disable up-swipe action
          fillSpace: true,
        ),
      ),
    );
  }
}

class RecipeDetailScreen extends StatelessWidget {
  final int recipeId;

  const RecipeDetailScreen({Key? key, required this.recipeId}) : super(key: key);

  Future<Map<String, dynamic>> fetchRecipeDetails(int recipeId) async {
    final url = Uri.parse(
        'https://api.spoonacular.com/recipes/$recipeId/information?apiKey=$spoonacularApiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'name': data['title'] ?? 'Unknown Recipe',
          'image': data['image'] ?? '',
          'rating': (data['spoonacularScore'] ?? 0) / 20.0, // Convert to 5-star scale
          'description': data['summary'] != null
              ? data['summary']
              .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
              : 'No description available.',
          'ingredients': data['extendedIngredients'] != null
              ? List<Map<String, dynamic>>.from(
              data['extendedIngredients'].map((ingredient) => {
                'name': ingredient['name'],
                'quantity': ingredient['amount'],
                'unit': ingredient['unit'] ?? '',
              }))
              : [],
          'instructions': data['instructions'] != null
              ? data['instructions']
              .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
              : 'No instructions available.',
          'reviews': [], // Spoonacular API does not provide reviews; use placeholders or omit.
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
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 16,
                      child: IconButton(
                        icon: const Icon(Icons.share, color: Colors.white),
                        onPressed: () {
                          // Implement share functionality
                        },
                      ),
                    ),
                  ],
                ),

                // Recipe Details
                DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      // Title and Rating
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
                              ),
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
                                    full: const Icon(Icons.star, color: Colors.amber),
                                    half: const Icon(Icons.star_half, color: Colors.amber),
                                    empty: const Icon(Icons.star_border, color: Colors.amber),
                                  ),
                                  itemSize: 20,
                                  onRatingUpdate: (double value) {},
                                ),
                                const SizedBox(width: 8),
                                Text('${recipe['rating']} stars'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              recipe['description'],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),

                      // TabBar
                      const TabBar(
                        tabs: [
                          Tab(text: 'Ingredients'),
                          Tab(text: 'Recipe'),
                          Tab(text: 'Reviews'),
                        ],
                        indicatorColor: Colors.orange,
                        labelColor: Colors.orange,
                        unselectedLabelColor: Colors.grey,
                      ),

                      // TabBarView
                      SizedBox(
                        height: 400, // Set a height for the TabBarView
                        child: TabBarView(
                          children: [
                            // Ingredients Tab
                            ListView(
                              padding: const EdgeInsets.all(16.0),
                              children: recipe['ingredients']
                                  .map<Widget>(
                                    (ingredient) => Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(ingredient['name']),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () {
                                            // Decrease quantity logic
                                          },
                                        ),
                                        Text('${ingredient['quantity']}'),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () {
                                            // Increase quantity logic
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                                  .toList(),
                            ),

                            // Recipe Instructions Tab
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Instructions:',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    recipe['instructions'],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),

                            // Reviews Tab
                            ListView(
                              padding: const EdgeInsets.all(16.0),
                              children: recipe['reviews']
                                  .map<Widget>(
                                    (review) => ListTile(
                                  leading: const Icon(Icons.comment),
                                  title: Text(review),
                                ),
                              )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Get Recipe Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Implement "Get Recipe" functionality
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      'Get Recipe',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


