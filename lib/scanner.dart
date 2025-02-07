import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:allergy_app/ingredients.dart';
import 'package:allergy_app/recipe_screen.dart';
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
  String barcode = 'Tap to scan';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(' Scanner'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              child: const Text('Scan Barcode'),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AiBarcodeScanner(
                      onDispose: () {
                        /// This is called when the barcode scanner is disposed.
                        /// You can write your own logic here.
                        debugPrint("Barcode scanner disposed!");
                      },
                      hideGalleryButton: false,
                      controller: MobileScannerController(
                        detectionSpeed: DetectionSpeed.noDuplicates,
                      ),
                      onDetect: (BarcodeCapture capture) async {
                        /// The row string scanned barcode value
                        final String? scannedValue =
                            capture.barcodes.first.rawValue;
                        debugPrint("Barcode scanned: $scannedValue");

                        getProduct(scannedValue, context);

                        /// The `Uint8List` image is only available if `returnImage` is set to `true`.
                        final Uint8List? image = capture.image;
                        debugPrint("Barcode image: $image");

                        /// row data of the barcode
                        final Object? raw = capture.raw;
                        debugPrint("Barcode raw: $raw");

                        /// List of scanned barcodes if any
                        final List<Barcode> barcodes = capture.barcodes;
                        debugPrint("Barcode list: $barcodes");
                      },
                      validator: (value) {
                        if (value.barcodes.isEmpty) {
                          return false;
                        }
                        if (!(value.barcodes.first.rawValue
                                ?.contains('flutter.dev') ??
                            false)) {
                          return false;
                        }
                        return true;
                      },
                    ),
                  ),
                );
              },
            ),
            Text(barcode),
          ],
        ),
      ),
    );
  }
}

Future<Product?> getProduct(var barcode, BuildContext context) async {
  OpenFoodAPIConfiguration.userAgent = UserAgent(
    name: 'allergy_app',
  );
 // barcode = '0048151623426';

  final ProductQueryConfiguration configuration = ProductQueryConfiguration(
    barcode,
    language: OpenFoodFactsLanguage.ENGLISH,
    fields: [ProductField.ALL],
    version: ProductQueryVersion.v3,
  );
  final ProductResultV3 result =
      await OpenFoodAPIClient.getProductV3(configuration);


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
    throw Exception('product not found for $barcode');
  }


}
