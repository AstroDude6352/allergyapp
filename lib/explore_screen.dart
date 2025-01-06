import 'package:allergy_app/recipe_screen.dart';
import 'package:flutter/material.dart';

class ExploreScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Explore'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Category Selector
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('Recipes', true),
                  _buildCategoryChip('Ingredients', false),
                  _buildCategoryChip('Restaurants', false),
                ],
              ),
            ),
          ),
          // Content List
          Expanded(
            child: ListView(
              children: [
                _buildRecipeCard('Nut-Free Chocolate Cake', 'Nut-Free', 'assets/cake.jpg', context),
                _buildRecipeCard('Gluten-Free Pasta', 'Gluten-Free', 'assets/pasta.jpg', context),
                _buildRestaurantCard('Healthy Bites', 'New York, NY', 'assets/restaurant.jpg', context),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.filter_list),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.green,
        onSelected: (bool selected) {},
      ),
    );
  }

  Widget _buildRecipeCard(String title, String label, String imagePath, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeScreen(diet: '', allergens: [],),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(imagePath, height: 150, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(label, style: TextStyle(fontSize: 14, color: Colors.grey)),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeScreen(diet: '', allergens: [],),
                        ),
                      );
                    },
                    child: Text('View Recipe'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(String name, String location, String imagePath, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsPage(title: name, type: 'Restaurant'),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(imagePath, height: 150, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(location, style: TextStyle(fontSize: 14, color: Colors.grey)),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('Reserve'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class DetailsPage extends StatelessWidget {
  final String title;
  final String type;

  DetailsPage({required this.title, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$type Details'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Text('Details for $title', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
