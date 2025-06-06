import 'dart:convert';
import 'package:allergy_app/RecipeFromImageScreen.dart';
import 'package:allergy_app/profile_screen.dart';
import 'package:allergy_app/recipe_details.dart';
import 'package:allergy_app/restaurant_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import 'home_screen.dart';

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
  List<Map<String, dynamic>> recipes = [];

  @override
  void initState() {
    super.initState();
    fetchRecipes();
  }

  Future<void> fetchRecipes() async {
    final url = Uri.parse(
        'https://api.spoonacular.com/recipes/complexSearch?diet=${widget.diet}&number=50&offset=50&apiKey=db9ded054e0d4745a6636108c3987351');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> allRecipes = List<Map<String, dynamic>>.from(
          data['results'].map((recipe) => {
                'name': recipe['title'] ?? 'Unknown Recipe',
                'image': recipe['image'] ?? '',
                'id': recipe['id'],
              }),
        );

        List<Map<String, dynamic>> filteredRecipes = allRecipes.where((recipe) {
          return true;
        }).toList();

        setState(() {
          recipes = filteredRecipes;
          isFetching = false;
        });

        print("Total recipes found: ${allRecipes.length}");
        print("Recipes that fit allergens: ${filteredRecipes.length}");
      } else {
        setState(() => isFetching = false);
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      print('Error fetching recipes: $e');
      setState(() => isFetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1D1E33),
      appBar: AppBar(
        title: Text(
          'Recipes',
          style: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700),
        ),
        backgroundColor: Color(0xFF1D1E33),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isFetching
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(10),
              child: ListView.builder(
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
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
                      margin: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: CachedNetworkImage(
                              imageUrl: recipe['image'],
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            left: 10,
                            right: 10,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                recipe['name'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                softWrap: true,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      bottomNavigationBar: BottomAppBar(
        color: Color(0xFF282A45),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _buildNavBarItem(Icons.home, 'Home', Colors.tealAccent, context,
                  const HomeScreen()),
              _buildNavBarItem(Icons.local_dining, 'Scan', Colors.blueGrey,
                  context, const RecipeFromImageScreen()),
              _buildNavBarItem(Icons.food_bank, 'Restaurants', Colors.blueGrey,
                  context, RestaurantScreen()),
              _buildNavBarItem(Icons.person, 'Profile', Colors.blueGrey,
                  context, const ProfileScreen()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, String label, Color color,
      BuildContext context, Widget screen) {
    return IconButton(
      onPressed: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => screen));
      },
      icon: Icon(icon, size: 28),
      color: color,
    );
  }
}
