import 'package:allergy_app/allergy_insights.dart';
import 'package:allergy_app/data_provider.dart';
import 'package:allergy_app/reaction_log.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _currentIndex = 0; // Home is index 0

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<DataProvider>(context, listen: false).loadUserPreferences();
    });
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;

    Widget destination;
    switch (index) {
      case 0:
        destination = const HomeScreen();
        break;
      case 1:
        destination = const ReactionLogScreen();
        break;
      case 2:
        destination = AllergyInsightsScreen();
        break;
      case 3:
        destination = const ProfileScreen();
        break;
      default:
        destination = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1E33), // Consistent dark theme
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF282A45), // Dark modern app bar
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
                        text: 'Welcome!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: Colors.tealAccent, // Accent color
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

              // Motivational Quote Section
              Card(
                color: Colors.tealAccent.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: const Text(
                    'Stay safe! Your allergies are manageable with the right info.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // You can add your recipe list or placeholder here...

              // Allergy News & Alerts Section
              const AllergyNewsSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2E2F45),
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white70,
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Reactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// AllergyNewsSection remains unchanged
class AllergyNewsSection extends StatefulWidget {
  const AllergyNewsSection({super.key});

  @override
  _AllergyNewsSectionState createState() => _AllergyNewsSectionState();
}

class _AllergyNewsSectionState extends State<AllergyNewsSection> {
  final String apiKey =
      "6097e0789cb9402ab822540deb360dbc"; // Replace with your NewsAPI key
  List articles = [];

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    final query = Uri.encodeComponent(
        'allergy OR "food allergy" OR "allergic reaction" OR "allergy alert"');
    final String url =
        "https://newsapi.org/v2/everything?q=$query&language=en&sortBy=publishedAt&apiKey=$apiKey";

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
          'Allergy News',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 10),
        articles.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: Colors.tealAccent))
            : Column(
                children: articles.map((article) {
                  return ListTile(
                    leading: const Icon(Icons.newspaper,
                        color: Colors.tealAccent, size: 30), // News icon
                    title: Text(
                      article["title"],
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    trailing: const Icon(Icons.open_in_new,
                        color: Colors.tealAccent), // Open link icon
                    onTap: () => _launchURL(article["url"]),
                  );
                }).toList(),
              ),
      ],
    );
  }
}
