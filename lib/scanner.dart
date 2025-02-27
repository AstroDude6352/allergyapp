import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:allergy_app/ingredients.dart';
import 'package:allergy_app/profile_screen.dart';
import 'package:allergy_app/restaurant_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:provider/provider.dart';

import 'data_provider.dart';
import 'home_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  String barcode = 'Tap to scan';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1E33), // Dark theme background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF282A45),
        elevation: 4,
        title: const Text(
          'Scan Your Food',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
            color: Colors.tealAccent, // Accent color
          ),
        ),
        toolbarHeight: 100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Scan a Barcode',
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
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        backgroundColor: const Color(0xFF1D1E33), // Match theme
                        body: Column(
                          children: [
                            Expanded(
                              child: AiBarcodeScanner(
                                onDispose: () {
                                  debugPrint("Barcode scanner disposed!");
                                },
                                hideGalleryButton: false,
                                controller: MobileScannerController(
                                  detectionSpeed: DetectionSpeed.noDuplicates,
                                ),
                                onDetect: (BarcodeCapture capture) async {
                                  final String? scannedValue = capture.barcodes.isNotEmpty
                                      ? capture.barcodes.first.rawValue
                                      : null;

                                  if (scannedValue != null) {
                                    debugPrint("Barcode scanned: $scannedValue");
                                    getProduct(scannedValue, context);
                                  }
                                },
                                validator: (value) {
                                  return value.barcodes.isNotEmpty;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Scan Now',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                barcode,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF282A45), // Dark footer for consistency
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _buildNavBarItem(Icons.home, 'Home', Colors.blueGrey, context, const HomeScreen()),
              _buildNavBarItem(Icons.local_dining, 'Scan', Colors.tealAccent, context, const ScannerScreen()),
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

Future<void> getProduct(String barcode, BuildContext context) async {
  OpenFoodAPIConfiguration.userAgent = UserAgent(name: 'allergy_app');

  final ProductQueryConfiguration configuration = ProductQueryConfiguration(
    barcode,
    language: OpenFoodFactsLanguage.ENGLISH,
    fields: [
      ProductField.ALL,
      ProductField.ALLERGENS,
      ProductField.ALLERGENS_TAGS_IN_LANGUAGES,
      ProductField.INGREDIENTS,
    ],
    version: ProductQueryVersion.v3,
  );

  final ProductResultV3 result = await OpenFoodAPIClient.getProductV3(configuration);

  if (result.status == ProductResultV3.statusSuccess && result.product != null) {
    final product = result.product;

    // Get user's allergens
    final userAllergens = Provider.of<DataProvider>(context, listen: false).selectedAllergens;

    // Extract allergens from OpenFoodFacts
    List<String> productAllergens = [];
    if (product?.allergensTagsInLanguages != null) {
      productAllergens = product!.allergensTagsInLanguages!.values.expand((list) => list).toList();
    }

    if (productAllergens.isEmpty && product?.ingredients != null) {
      debugPrint("No allergens found. Checking ingredients instead...");

      productAllergens = product!.ingredients!
          .map((ingredient) => ingredient.text)
          .whereType<String>() // Remove null values
          .toList();

      debugPrint("Extracted Ingredients as Allergens: ${productAllergens.join(", ")}");
    }

// Debugging: Print all relevant data
    debugPrint("User Allergens: ${userAllergens.join(", ")}");
    debugPrint("Product Allergens: ${productAllergens.join(", ")}");

// Check if the product is safe
    bool isSafe = !productAllergens.any((allergen) => userAllergens.contains(allergen));




    if (!isSafe) {
      // Show an alert if the product contains allergens
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Warning: Allergen Detected!"),
          content: Text("This product is NOT safe! It contains: ${productAllergens.join(", ")}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return; // Stop navigation to the next screen
    }

    // Navigate to ingredient screen only if it's safe
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Ingredients(
          product?.imageFrontUrl ?? '',
          product?.productName ?? 'Unknown Product',
          productAllergens, // Pass detected allergens
          product?.ingredients, // Pass ingredient list
        ),
      ),
    );
  } else {
    // Show a dialog instead of throwing an exception
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Product Not Found"),
        content: Text("No information available for barcode: $barcode"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}


