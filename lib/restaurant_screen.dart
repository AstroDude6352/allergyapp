import 'package:allergy_app/quiz_screen.dart' as dataProvider;
import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Google Maps Flutter package
import 'package:google_generative_ai/google_generative_ai.dart'; // Assuming you're using Gemini
import 'dart:convert';

const globalApiKey =
    'AIzaSyAG2bIKdSrr8JFB3bCkEIjnnvx8FRH7Np8'; // Use your actual API key for Gemini

final List<String> allergenList = dataProvider.selectedAllergens;

String allergenString = allergenList.isNotEmpty
    ? allergenList.join(', ')
    : 'No allergens specified';


String userPreferences = 'Avoids: $allergenString';


class RestaurantScreen extends StatefulWidget {
  @override
  _RestaurantScreenState createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  List<Map<String, dynamic>> restaurants = []; // Store a list of restaurants
  double? latitude = 33.580597; // Set a default latitude (e.g., San Francisco)
  double? longitude =
      -112.237381; // Set a default longitude (e.g., San Francisco)
  GoogleMapController? mapController;
  Set<Marker> markers = Set(); // To store restaurant markers on the map
  Map<String, dynamic>? selectedRestaurant; // Store selected restaurant details
  final places =
      GoogleMapsPlaces(apiKey: 'AIzaSyBKapRibYm4aGKiQcpoN2qXDgoHRr7ruzg');

  @override
  void initState() {
    super.initState();
    fetchRestaurantsFromDataProvider();
  }

  Future<String?> getRestaurantImageUrl(String restaurantName) async {
    try {
      final response = await places.searchByText(restaurantName);
      if (response.status == "OK" && response.results.isNotEmpty) {
        final placeId = response.results[0].placeId;
        final detailsResponse = await places.getDetailsByPlaceId(placeId);
        if (detailsResponse.status == "OK" &&
            detailsResponse.result.photos != null &&
            detailsResponse.result.photos!.isNotEmpty) {
          final photoReference =
              detailsResponse.result.photos![0].photoReference;
          final photoUrl =
              'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=AIzaSyBKapRibYm4aGKiQcpoN2qXDgoHRr7ruzg';
          return photoUrl;
        }
      }
    } catch (e) {
      print('Error getting restaurant image: $e');
    }
    return null; // Return null if image URL couldn't be fetched
  }

  void fetchRestaurantsFromDataProvider() async {
    final location = "$latitude,$longitude";
    final radius = 80467; // 50 miles in meters
    final type = "restaurant";

    final response = await places.searchNearbyWithRadius(
      Location(lat: latitude!, lng: longitude!),
      radius,
      type: type,
      keyword: "allergy-friendly", // Searches for allergy-friendly restaurants
    );

    if (response.status == "OK") {
      setState(() {
        restaurants = response.results
            .take(15)
            .map((place) => {
                  'name': place.name,
                  'latitude': place.geometry!.location.lat,
                  'longitude': place.geometry!.location.lng,
                  'image': place.photos != null && place.photos!.isNotEmpty
                      ? getRestaurantImageUrl(
                          place.photos!.first.photoReference)
                      : null,
                })
            .toList();

        markers = restaurants.map((restaurant) {
          return Marker(
            markerId: MarkerId(restaurant['name']),
            position: LatLng(restaurant['latitude'], restaurant['longitude']),
            infoWindow: InfoWindow(
              title: restaurant['name'],
              onTap: () {
                setState(() {
                  selectedRestaurant = restaurant;
                });
              },
            ),
          );
        }).toSet();
      });
    } else {
      print("Error fetching restaurants: ${response.errorMessage}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1D1E33), // Consistent dark theme
      appBar: AppBar(
        title: const Text('Restaurants',
            style: TextStyle(color: Colors.white, fontFamily: "Poppins", fontWeight: FontWeight.w700,)),
        backgroundColor: Color(0xFF282A45), // Dark modern app bar
        elevation: 4,
      ),
      body: latitude == null || longitude == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(latitude!, longitude!),
              zoom: 12,
            ),
            markers: markers.map((marker) {
              return marker.copyWith(
                onTapParam: () {
                  setState(() {
                    selectedRestaurant = restaurants.firstWhere(
                            (restaurant) =>
                        restaurant['name'] == marker.markerId.value);
                  });
                },
              );
            }).toSet(),
          ),
          if (selectedRestaurant != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Card(
                elevation: 8,
                color: Color(0xFF282A45),
                margin: const EdgeInsets.all(5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FutureBuilder<String?>(
                        future:
                        getRestaurantImageUrl(selectedRestaurant!['name']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return const Icon(Icons.error, color: Colors.red);
                          } else if (snapshot.hasData && snapshot.data != null) {
                            return Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: DecorationImage(
                                  image: NetworkImage(snapshot.data!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          } else {
                            return const SizedBox(height: 150);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        selectedRestaurant!['name'],
                        style: const TextStyle(
                          fontSize: 30,
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent,
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
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                backgroundColor: Color(0xFF1D1E33),
                                title: Text(
                                  selectedRestaurant!['name'],
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Does not contain:",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...allergenList.isNotEmpty
                                        ? allergenList
                                        .map((allergen) => Card(
                                      color: Color(0xFF282A45),
                                      elevation: 2,
                                      shape:
                                      RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(
                                            10),
                                      ),
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                        title: Text(
                                          allergen,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                            FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ))
                                        .toList()
                                        : [
                                      const Text(
                                        'No allergens listed',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white),
                                      )
                                    ],
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close',
                                        style:
                                        TextStyle(color: Colors.tealAccent)),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text('More Details', style: TextStyle(fontFamily: 'Nunito'),),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

  }
}
