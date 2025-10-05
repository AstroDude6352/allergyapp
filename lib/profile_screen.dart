import 'dart:io';
import 'package:allergy_app/allergy_insights.dart';
import 'package:allergy_app/login_screen.dart';
import 'package:allergy_app/reaction_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void initState() {
    super.initState();
    Provider.of<DataProvider>(context, listen: false).loadUserPreferences();
  }

  Future<void> _selectImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
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
      backgroundColor: const Color(0xFF1D1E33), // Consistent dark theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF282A45),
        title: const Center(
          child: Text(
            'Profile',
            style: TextStyle(
                letterSpacing: 0.75,
                fontSize: 26,
                fontFamily: "Poppins",
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 20),
                  Icon(
                    Icons.medical_services,
                    size: 60,
                    color: Colors.tealAccent, // Allergy-related icon
                  ),
                  SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [],
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
                      const Text('Selected Taste Preference:',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Poppins')),
                      const SizedBox(height: 4),
                      Text(
                        dataProvider.selectedTaste ?? 'No preference selected',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.tealAccent,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Allergens:',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 8),
              dataProvider.allergens.isNotEmpty
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        showAllergensQuickView(
                            context, dataProvider.allergens, allergenIcons);
                      },
                      child: const Text(
                        'View Allergens',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    )
                  : const Text('No allergens selected',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => signOut(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2E2F45),
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white70,
        currentIndex: 3, // Profile is index 3
        onTap: (index) {
          if (index == 3) return; // Already on Profile

          Widget destination;
          switch (index) {
            case 0:
              destination = const HomeScreen();
              break;
            case 1:
              destination = const ReactionLogScreen();
              break;
            case 2:
              destination = const AllergyInsightsScreen();
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
        },
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: 'Reactions'),
          BottomNavigationBarItem(
              icon: Icon(Icons.insights), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

void showAllergensQuickView(BuildContext context, Map<String, String> allergens,
    Map<String, IconData> allergenIcons) {
  final allergenList = allergens.keys.toList();

  Color severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1D1E33),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: allergenList.isEmpty
            ? const Center(
                child: Text(
                  'No allergens selected',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    'Your Allergens',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.tealAccent[400],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: allergenList.length,
                      itemBuilder: (context, index) {
                        final allergen = allergenList[index];
                        final severity = allergens[allergen] ?? 'Unknown';
                        return Card(
                          elevation: 2,
                          color: const Color(0xFF282A45),
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
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontFamily: 'Nunito',
                              ),
                            ),
                            trailing: Text(
                              severity,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: severityColor(severity),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      );
    },
  );
}

Future<void> signOut(BuildContext context) async {
  try {
    // Sign out from Firebase
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  } catch (e) {
    print('Error signing out: $e');
  }
}
