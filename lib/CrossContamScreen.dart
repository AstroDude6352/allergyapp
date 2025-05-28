import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart';

class CrossContamRiskScreen extends StatefulWidget {
  @override
  _CrossContamRiskScreenState createState() => _CrossContamRiskScreenState();
}

class _CrossContamRiskScreenState extends State<CrossContamRiskScreen> {
  List<Map<String, dynamic>> restaurants = [];
  final String googleApiKey = "YOUR_GOOGLE_API_KEY";
  final String spoonacularApiKey = "YOUR_SPOONACULAR_API_KEY";
  double? latitude;
  double? longitude;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
    });
    await _fetchNearbyRestaurants();
  }

  Future<void> _fetchNearbyRestaurants() async {
    if (latitude == null || longitude == null) return;

    final googlePlacesUrl = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
      "?location=$latitude,$longitude"
      "&rankby=distance"
      "&type=restaurant"
      "&key=$googleApiKey",
    );

    final response = await http.get(googlePlacesUrl);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Map<String, dynamic>> fetchedRestaurants = [];

      for (int i = 0; i < data['results'].length && i < 5; i++) {
        final r = data['results'][i];
        fetchedRestaurants.add({
          "name": r['name'],
          "placeId": r['place_id'],
          "menuItems": [],
          "risk": "Unknown"
        });
      }

      setState(() {
        restaurants = fetchedRestaurants;
      });

      for (final restaurant in restaurants) {
        await _fetchMenuItemsAndAssessRisk(restaurant);
      }
    }
  }

  Future<void> _fetchMenuItemsAndAssessRisk(
      Map<String, dynamic> restaurant) async {
    final name = restaurant["name"];
    final url = Uri.parse(
      "https://api.spoonacular.com/food/menuItems/search"
      "?query=${Uri.encodeComponent(name)}&number=10&apiKey=$spoonacularApiKey",
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final menuItems = data['menuItems'] ?? [];
      restaurant['menuItems'] = menuItems;
      restaurant['risk'] = _assessCrossContamRisk(menuItems);
      setState(() {});
    }
  }

  String _assessCrossContamRisk(List<dynamic> menuItems) {
    final userAllergens = Provider.of<DataProvider>(context)
        .allergens
        .keys
        .map((key) => key.toLowerCase())
        .toList();

    int riskyCount = 0;
    for (final item in menuItems) {
      final allergens = item['allergens'] ?? [];
      if (allergens
          .any((a) => userAllergens.contains(a.toString().toLowerCase()))) {
        riskyCount++;
      }
    }

    final ratio = menuItems.isEmpty ? 0 : riskyCount / menuItems.length;

    if (ratio > 0.5) return "High Risk";
    if (ratio > 0.2) return "Medium Risk";
    return "Low Risk";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1E33),
      appBar: AppBar(
        title: const Text("Cross Contamination Risk",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF282A45),
      ),
      body: Builder(
        builder: (context) {
          if (latitude == null || longitude == null) {
            return const Center(
              child: Text(
                "Getting your location...",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (restaurants.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView.builder(
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final r = restaurants[index];
              return Card(
                margin: const EdgeInsets.all(10),
                color: const Color(0xFF282A45),
                child: ListTile(
                  title: Text(r['name'],
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text("Risk: ${r['risk']}",
                      style: const TextStyle(color: Colors.white70)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
