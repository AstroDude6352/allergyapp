import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RestaurantScreen extends StatefulWidget {
  @override
  _RestaurantScreenState createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  List places = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchPlaces();
  }

  Future<void> fetchPlaces() async {
    const String apiUrl = "https://api.foursquare.com/v3/places/search";
    const String apiKey = "fsq3xu7eAswy6mt5RH42v+uV38fTVbYKutl+2V4NWlMsE4U="; // Replace with your API key

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse("$apiUrl?categories=13065&near=New York&limit=10"),
        headers: {
          "Authorization": apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          places = data['results'];
        });
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Foursquare Places"),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : places.isEmpty
          ? const Center(
        child: Text(
          "No places found.",
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: places.length,
        itemBuilder: (context, index) {
          final place = places[index];
          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text(place['name'] ?? 'Unknown'),
              subtitle: Text(place['location']['formatted_address'] ??
                  'Address not available'),
              trailing: const Icon(Icons.restaurant),
            ),
          );
        },
      ),
    );
  }
}
