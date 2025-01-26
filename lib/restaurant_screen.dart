import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Google Maps Flutter package
import 'package:google_generative_ai/google_generative_ai.dart'; // Assuming you're using Gemini
import 'dart:convert';

const globalApiKey =
    'AIzaSyAG2bIKdSrr8JFB3bCkEIjnnvx8FRH7Np8'; // Use your actual API key for Gemini
const List<String> allergenList = [
  'peanuts',
  'gluten',
  'dairy'
]; // Example allergens

String allergenString = allergenList.join(', ');

class RestaurantScreen extends StatefulWidget {
  @override
  _RestaurantScreenState createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  List<Map<String, dynamic>> restaurants = []; // Store a list of restaurants
  double? latitude = 33.580597; // Set a default latitude (e.g., San Francisco)
  double? longitude = -112.237381; // Set a default longitude (e.g., San Francisco)
  GoogleMapController? mapController;
  Set<Marker> markers = Set(); // To store restaurant markers on the map
  Map<String, dynamic>? selectedRestaurant; // Store selected restaurant details
  final places = GoogleMapsPlaces(apiKey: 'AIzaSyBKapRibYm4aGKiQcpoN2qXDgoHRr7ruzg');

  @override
  void initState() {
    super.initState();
    fetchRestaurants();
  }

  void fetchRestaurants() async {
    if (latitude == null || longitude == null) {
      print('Location is not available');
      return;
    }

    final schema = Schema.array(
      description: 'List of restaurants with allergen-free options near the user',
      items: Schema.object(properties: {
        'name': Schema.string(
            description: 'Name of the restaurant.', nullable: false),
        'latitude': Schema.number(
            description: 'Latitude of the restaurant.', nullable: false),
        'longitude': Schema.number(
            description: 'Longitude of the restaurant.', nullable: false),
      }, requiredProperties: [
        'name',
        'latitude',
        'longitude'
      ]),
    );

    final model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: globalApiKey,
      generationConfig: GenerationConfig(
          responseMimeType: 'application/json', responseSchema: schema),
    );

    final prompt =
        'Use Google Maps to provide a list of at least 10 restaurants within 20 miles of latitude $latitude and longitude $longitude that offer food options without $allergenString. Include the restaurant name, latitude, and longitude.';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      print('API Response: ${response.text}'); // Log the raw response for debugging
      final responseDisplay = response.text;

      if (responseDisplay != null) {
        try {
          final restaurantData = jsonDecode(responseDisplay) as List<dynamic>;
          print('Parsed Data: $restaurantData'); // Log the parsed data
          setState(() {
            restaurants = restaurantData
                .map((restaurant) => {
              'name': restaurant['name'],
              'latitude': restaurant['latitude'],
              'longitude': restaurant['longitude'],
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
                    Scaffold.of(context).openEndDrawer();
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                restaurant['name'],
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins', // Add your custom font
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to view more details',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontFamily: 'Nunito', // Add your custom font
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              );

            }).toSet();
          });
        } catch (e) {
          print('Error parsing restaurants: $e');
        }
      }
    } catch (e) {
      print('Error fetching restaurants: $e');
    }
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
          final photoReference = detailsResponse.result.photos![0].photoReference;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Allergen-Free Restaurants')),
      body: latitude == null || longitude == null
          ? const Center(child: CircularProgressIndicator()) // Show loading while fetching data
          : Stack(
        children: [
          // Google Map
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
          // Details View Overlay
          if (selectedRestaurant != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Card(
                elevation: 8,
                color: Colors.deepPurple[50],
                margin: const EdgeInsets.all(5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Placeholder for restaurant image
                      FutureBuilder<String?>(
                        future: getRestaurantImageUrl(selectedRestaurant!['name']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return const Icon(Icons.error);
                          } else if (snapshot.hasData && snapshot.data != null) {
                            return Container(
                              height: 250,
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
                      // Restaurant name
                      Text(
                        selectedRestaurant!['name'],
                        style: const TextStyle(
                          fontSize: 30,
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // More Details Button
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text(selectedRestaurant!['name']),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                        'Latitude: ${selectedRestaurant!['latitude']}'),
                                    Text(
                                        'Longitude: ${selectedRestaurant!['longitude']}'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text('More Details'),
                      ),
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
