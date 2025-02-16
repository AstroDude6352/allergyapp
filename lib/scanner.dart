import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:allergy_app/ingredients.dart';
import 'package:allergy_app/profile_screen.dart';
import 'package:allergy_app/restaurant_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:openfoodfacts/openfoodfacts.dart';

import 'home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ScannerScreen(),
    );
  }
}

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
      backgroundColor: Color(0xFF1D1E33), // Dark theme background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF282A45),
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
        centerTitle: true,
        toolbarHeight: 100,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                      backgroundColor: Color(0xFF1D1E33), // Match theme
                      body: SafeArea(
                        child: Column(
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
                                  final String? scannedValue = capture.barcodes.first.rawValue;
                                  debugPrint("Barcode scanned: $scannedValue");
                                  getProduct(scannedValue, context);
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
      bottomNavigationBar: BottomAppBar(
        color: Color(0xFF282A45), // Dark footer for consistency
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _buildNavBarItem(Icons.home, 'Home', Colors.tealAccent, context, const HomeScreen()),
              _buildNavBarItem(Icons.local_dining, 'Scan', Colors.blueGrey, context, const ScannerScreen()),
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

Future<Product?> getProduct(var barcode, BuildContext context) async {
  OpenFoodAPIConfiguration.userAgent = UserAgent(
    name: 'allergy_app',
  );

  final ProductQueryConfiguration configuration = ProductQueryConfiguration(
    barcode,
    language: OpenFoodFactsLanguage.ENGLISH,
    fields: [ProductField.ALL],
    version: ProductQueryVersion.v3,
  );
  final ProductResultV3 result = await OpenFoodAPIClient.getProductV3(configuration);

  if (result.status == ProductResultV3.statusSuccess) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Ingredients(
          result.product?.imageFrontUrl,
          result.product?.productName,
          result.product?.allergens?.names,
          result.product?.ingredients,
        ),
      ),
    );

    return result.product;
  } else {
    throw Exception('Product not found for $barcode');
  }
}
