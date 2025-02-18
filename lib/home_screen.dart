import 'package:allergy_app/restaurant_screen.dart';
import 'package:allergy_app/scanner.dart';
import 'package:flutter/material.dart';
import '../recipe_screen.dart';
import '../profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String firstName = "Aditya"; // Placeholder name

    return Scaffold(
      backgroundColor: Color(0xFF1D1E33), // Consistent dark theme
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF282A45), // Dark modern app bar
        elevation: 4,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Welcome,\n',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: Colors.tealAccent, // Accent color
                        ),
                      ),
                      TextSpan(
                        text: firstName,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: Colors.white, // High contrast
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(
                Icons.medical_services,
                size: 40,
                color: Colors.tealAccent, // Allergy-related icon
              ),
            ],
          ),
        ),
        toolbarHeight: 120,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              const Text(
                'Explore New Recipes',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent, // Standout button color
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecipeScreen(
                        diet: 'Any',
                        allergens: [],
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Find Recipes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),
              AllergyNewsSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Color(0xFF282A45), // Dark footer for consistency
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _buildNavBarItem(Icons.home, 'Home', Colors.tealAccent, context, const HomeScreen()),
              _buildNavBarItem(Icons.local_dining, 'Scan', Colors.blueGrey, context, const ScannerScreen()),
              _buildNavBarItem(Icons.food_bank, 'Restaurants', Colors.blueGrey, context, RestaurantScreen()),
              _buildNavBarItem(Icons.person, 'Profile', Colors.blueGrey, context, const ProfileScreen()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, String label, Color color, BuildContext context, Widget screen) {
    return IconButton(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
      },
      icon: Icon(icon, size: 28),
      color: color,
    );
  }
}

class AllergyNewsSection extends StatefulWidget {
  @override
  _AllergyNewsSectionState createState() => _AllergyNewsSectionState();
}

class _AllergyNewsSectionState extends State<AllergyNewsSection> {
  final String apiKey = "6097e0789cb9402ab822540deb360dbc"; // Replace with your NewsAPI key
  List articles = [];

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    final String url =
        "https://newsapi.org/v2/everything?q=food+allergy&language=en&sortBy=publishedAt&apiKey=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          articles = data["articles"].take(5).toList(); // Limit to 5 articles
        });
      } else {
        throw Exception("Failed to load news");
      }
    } catch (error) {
      print("Error fetching news: $error");
    }
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Allergy News & Alerts',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        articles.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
            : Column(
          children: articles.map((article) {
            return ListTile(
              leading: const Icon(Icons.newspaper, color: Colors.tealAccent, size: 30), // News icon
              title: Text(
                article["title"],
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              trailing: const Icon(Icons.open_in_new, color: Colors.tealAccent), // Open link icon
              onTap: () => _launchURL(article["url"]),
            );

          }).toList(),
        ),
      ],
    );
  }
}