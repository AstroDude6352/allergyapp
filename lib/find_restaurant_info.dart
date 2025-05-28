import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'data_provider.dart';

class FindRestaurantInfo extends StatefulWidget {
  @override
  _FindRestaurantInfoState createState() => _FindRestaurantInfoState();
}

class _FindRestaurantInfoState extends State<FindRestaurantInfo> {
  List<Map<String, dynamic>> restaurants = [];
  List<String> userAllergens = ["milk"];
  final String googleApiKey = "AIzaSyBKapRibYm4aGKiQcpoN2qXDgoHRr7ruzg";
  final String spoonacularApiKey = "db9ded054e0d4745a6636108c3987351";
  double? latitude;
  double? longitude;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permissions are permanently denied.");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
    });
    _fetchNearbyRestaurants();
  }

  Future<void> _fetchNearbyRestaurants() async {
    if (latitude == null || longitude == null) return;

    String googlePlacesUrl =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&rankby=distance&type=restaurant&key=$googleApiKey";

    var response = await http.get(Uri.parse(googlePlacesUrl));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data["results"].isNotEmpty) {
        List<Map<String, dynamic>> fetchedRestaurants = [];

        for (int i = 0; i < data["results"].length && i < 2; i++) {
          var restaurant = data["results"][i];
          fetchedRestaurants.add({
            "name": restaurant["name"],
            "placeId": restaurant["place_id"],
            "menuItems": []
          });
        }

        setState(() {
          restaurants = fetchedRestaurants;
        });

        for (var restaurant in restaurants) {
          _fetchMenuItems(restaurant);
        }
      }
    } else {
      print("Error fetching restaurant data: ${response.statusCode}");
    }
  }

  Future<void> _fetchMenuItems(Map<String, dynamic> restaurant) async {
    String spoonacularUrl =
        "https://api.spoonacular.com/food/menuItems/search?query=${restaurant["name"]}&number=10&apiKey=$spoonacularApiKey";

    var response = await http.get(Uri.parse(spoonacularUrl));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        restaurant["menuItems"] = data["menuItems"];
      });
    } else {
      print("Error fetching menu data: ${response.statusCode}");
    }
  }

  List<dynamic> getSafeMenuItems(
      List<dynamic> menuItems, List<String> userAllergens) {
    return menuItems.where((item) {
      List<String> allergens = List<String>.from(item["allergens"] ?? []);
      return !allergens.any((allergen) => userAllergens.contains(allergen));
    }).toList();
  }

  Widget build(BuildContext context) {
    final userAllergens = Provider.of<DataProvider>(context)
        .allergens
        .keys
        .map((key) => key.toLowerCase())
        .toList();

    return Scaffold(
      backgroundColor: Color(0xFF1D1E33),
      appBar: AppBar(
        title: Text(
          "Nearby Restaurants",
          style: TextStyle(
              color: Colors.white,
              fontFamily: "Poppins",
              fontWeight: FontWeight.w700),
        ),
        backgroundColor: Color(0xFF282A45),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              "Here are your safe menu items at these restaurants",
              style: TextStyle(
                  color: Colors.white70, fontSize: 16, fontFamily: "Poppins"),
            ),
          ),
          Expanded(
            child: restaurants.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: restaurants.length,
                    itemBuilder: (context, index) {
                      var restaurant = restaurants[index];
                      var safeMenuItems = getSafeMenuItems(
                          restaurant["menuItems"], userAllergens);

                      return Card(
                        margin: EdgeInsets.all(10),
                        color: Color(0xFF282A45),
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(restaurant["name"],
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              Divider(color: Colors.grey),
                              safeMenuItems.isEmpty
                                  ? Text("No safe menu items found.",
                                      style: TextStyle(color: Colors.white70))
                                  : Column(
                                      children: safeMenuItems
                                          .map((item) => ListTile(
                                                title: Text(item["title"],
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                              ))
                                          .toList(),
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
  }
}
