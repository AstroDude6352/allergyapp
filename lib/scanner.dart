import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:allergy_app/ingredients.dart';
import 'package:allergy_app/profile_screen.dart';
import 'package:allergy_app/restaurant_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

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
}Future<void> getProduct(String barcode, BuildContext context) async {
  OpenFoodAPIConfiguration.userAgent = UserAgent(name: 'allergy_app');

  final ProductQueryConfiguration configuration = ProductQueryConfiguration(
    barcode,
    language: OpenFoodFactsLanguage.ENGLISH,
    fields: [ProductField.ALL],
    version: ProductQueryVersion.v3,
  );

  final ProductResultV3 result = await OpenFoodAPIClient.getProductV3(configuration);

  if (result.status == ProductResultV3.statusSuccess && result.product != null) {
    final product = result.product;
    final List<Ingredient>? ingredientList = product?.ingredients; // Keep it as List<Ingredient>?

    // Navigate to the ingredient screen with actual ingredient objects
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Ingredients(
          product?.imageFrontUrl ?? '',
          product?.productName ?? 'Unknown Product',
          product?.allergens?.names ?? [],
          ingredientList,  // Pass it directly as List<Ingredient>?
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
