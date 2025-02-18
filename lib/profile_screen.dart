import 'dart:io';
import 'package:allergy_app/restaurant_screen.dart';
import 'package:allergy_app/scanner.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _imageFile;
  String userName = "Aditya Y";
  String userEmail = "example.com";

  Future<void> _selectImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  final Map<String, IconData> allergenIcons = {
    'Milk': Icons.local_drink,
    'Eggs': Icons.egg,
    'Fish': Icons.set_meal,
    'Crustacean Shellfish': Icons.restaurant_menu,
    'Tree Nuts': Icons.nature,
    'Peanuts': Icons.spa,
    'Wheat': Icons.grain,
    'Soybeans': Icons.eco,
    'Sesame': Icons.bakery_dining,
  };

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      backgroundColor: Color(0xFF1D1E33), // Consistent dark theme
      appBar: AppBar(
        backgroundColor: Color(0xFF282A45),

        title: const Center(
          child: Text(
            'Profile',
            style: TextStyle(
              letterSpacing: 0.75,
              fontSize: 26,
              fontFamily: "Poppins",
              fontWeight: FontWeight.w700,
              color: Colors.white
            ),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 20),
                  const Icon(
                    Icons.medical_services,
                    size: 60,
                    color: Colors.tealAccent, // Allergy-related icon
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),

                      Text(userEmail, style: const TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Nunito')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [

                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Selected Diet:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins')),
                      const SizedBox(height: 4),
                      Text(dataProvider.selectedDiet ?? 'No diet selected', style: const TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Nunito')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Allergens:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins')),
              const SizedBox(height: 8),
              dataProvider.selectedAllergens.isNotEmpty
                  ? Column(
                children: dataProvider.selectedAllergens.map((allergen) {
                  return Card(
                    elevation: 2,
                    color: Color(0xFF282A45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: Icon(
                        allergenIcons[allergen] ?? Icons.error,
                        color: Colors.red,
                      ),
                      title: Text(
                        allergen,
                        style: const TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Nunito'),
                      ),
                    ),
                  );
                }).toList(),
              )
                  : const Text('No allergens selected', style: TextStyle(fontSize: 16)),
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
              _buildNavBarItem(Icons.home, 'Home', Colors.blueGrey, context, const HomeScreen()),
              _buildNavBarItem(Icons.local_dining, 'Scan', Colors.blueGrey, context, const ScannerScreen()),
              _buildNavBarItem(Icons.food_bank, 'Restaurants', Colors.blueGrey, context, RestaurantScreen()),
              _buildNavBarItem(Icons.person, 'Profile', Colors.tealAccent, context, const ProfileScreen()),
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
