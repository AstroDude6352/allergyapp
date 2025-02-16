
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:openfoodfacts/openfoodfacts.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1E33),
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
            color: Colors.tealAccent,
          ),
        ),
        toolbarHeight: 100,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AiBarcodeScanner(
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

                          if (scannedValue != null) {
                            getProduct(scannedValue, context);
                          }
                        },
                        validator: (value) {
                          return value.barcodes.isNotEmpty;
                        },
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Scan Now',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> getProduct(String barcode, BuildContext context) async {
  OpenFoodAPIConfiguration.userAgent = UserAgent(name: 'allergy_app');

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
        builder: (context) => FoodDetailsScreen(
          imageUrl: result.product?.imageFrontUrl,
          productName: result.product?.productName ?? 'Unknown',
          allergens: result.product?.allergens?.names ?? ['No allergens listed'],
          ingredients: result.product?.ingredientsText ?? 'No ingredients available',
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product not found')),
    );
  }
}

class FoodDetailsScreen extends StatelessWidget {
  final String? imageUrl;
  final String productName;
  final List<String> allergens;
  final String ingredients;

  const FoodDetailsScreen({
    super.key,
    required this.imageUrl,
    required this.productName,
    required this.allergens,
    required this.ingredients,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1E33),
      appBar: AppBar(
        backgroundColor: const Color(0xFF282A45),
        title: const Text(
          'Food Details',
          style: TextStyle(color: Colors.tealAccent),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              Center(
                child: Image.network(
                  imageUrl!,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              productName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Allergens:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
            Text(
              allergens.join(', '),
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ingredients:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.tealAccent),
            ),
            Text(
              ingredients,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
