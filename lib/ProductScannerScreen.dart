import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';

class ProductScannerScreen extends StatefulWidget {
  const ProductScannerScreen({Key? key}) : super(key: key);

  @override
  State<ProductScannerScreen> createState() => _ProductScannerScreenState();
}

class _ProductScannerScreenState extends State<ProductScannerScreen> {
  File? _imageFile;
  bool _isUploading = false;
  List<Map<String, dynamic>> _similarProducts = [];

  final ImagePicker _picker = ImagePicker();

  // Put your Nutritionix keys here
  static const String nutritionixAppId = 'b5740d31';
  static const String nutritionixAppKey = '62cb25ccaa05e9531b6424f7c4d69d9c';

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadImageAndFetchResults();
    }
  }

  Future<List<Map<String, dynamic>>> _filterRelevantProducts(
      List<Map<String, dynamic>> products, Set<String> searchTerms) async {
    // Filter products based on relevance to search terms
    print('search terms: $searchTerms');
    return products.where((product) {
      final name = product['name'].toString().toLowerCase();
      final brand = product['brand'].toString().toLowerCase();
      final allergens =
          product['allergens']?.map((e) => e.toString().toLowerCase()) ?? [];
      final combinedText = '$name $brand ${allergens.join(' ')}';

      // Check if any search term is present in the product details
      return searchTerms.any((term) => combinedText.contains(term));
    }).toList();
  }

  Future<void> _uploadImageAndFetchResults() async {
    if (_imageFile == null) return;

    setState(() {
      _isUploading = true;
      _similarProducts = [];
    });

    try {
      final String key = 'uploads/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to S3
      final uploadOperation = Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(_imageFile!.path),
        path: StoragePath.fromString(key),
      );
      await uploadOperation.result;

      final rekognitionResponse = await Amplify.API.get(
        '/detect',
        queryParameters: {
          'bucket': 'allergyapp294ebac9fefc4b969f6611d650b44a59ca60f-dev',
          'key': key,
        },
      ).response;

      final rekognitionData = jsonDecode(rekognitionResponse.decodeBody());
      final List<dynamic> labels = rekognitionData['labels'] ?? [];
      final List<dynamic> texts = rekognitionData['text'] ?? [];

      // Debug prints
      print('Detected labels: $labels');
      print('Detected texts: $texts');

      // Combine labels and texts into unique lowercase terms
      final Set<String> searchTerms = {
        ...labels.map((e) => e.toString().toLowerCase()),
        ...texts.map((e) => e.toString().toLowerCase()),
      };

      if (searchTerms.isEmpty) {
        setState(() {
          _similarProducts = [];
        });
        return;
      }

      List<Map<String, dynamic>> nutritionixResults = [];
      final Set<String> seenProducts = {}; // To avoid duplicates

      for (final query in searchTerms) {
        final response = await http.get(
          Uri.parse(
              'https://trackapi.nutritionix.com/v2/search/instant?query=$query'),
          headers: {
            'x-app-id': nutritionixAppId,
            'x-app-key': nutritionixAppKey,
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // Focus only on branded foods
          final branded = data['branded'] as List<dynamic>?;

          if (branded != null && branded.isNotEmpty) {
            for (var product in branded) {
              final name =
                  (product['food_name'] ?? '').toString().toLowerCase();
              final brand =
                  (product['brand_name'] ?? '').toString().toLowerCase();
              final productKey = '$name|$brand';

              if (!seenProducts.contains(productKey)) {
                seenProducts.add(productKey);
                nutritionixResults.add({
                  'name': product['food_name'] ?? '',
                  'brand': product['brand_name'] ?? '',
                  'imageUrl': product['photo']?['thumb'] ?? '',
                  'allergens': product['allergen_contains'] ?? [],
                  'nf_calories': product['nf_calories'] ?? 0,
                  'serving_qty': product['serving_qty'] ?? 0,
                });
              }
            }
          }
        }
      }

      // Filter the results to find the most relevant products
      final filteredResults =
          await _filterRelevantProducts(nutritionixResults, searchTerms);

      setState(() {
        _similarProducts = filteredResults;
      });
    } on StorageException catch (e) {
      print('Upload failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.message}')),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _imageFile != null
                ? Image.file(_imageFile!, height: 250, fit: BoxFit.cover)
                : Container(
                    height: 250,
                    color: Colors.grey[300],
                    child: const Center(child: Text('No image selected')),
                  ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Picture'),
              onPressed: _isUploading ? null : _pickImage,
            ),
            const SizedBox(height: 20),
            if (_isUploading) const CircularProgressIndicator(),
            Expanded(
              child: _similarProducts.isEmpty
                  ? const Center(child: Text('No similar products to show'))
                  : ListView.builder(
                      itemCount: _similarProducts.length,
                      itemBuilder: (context, index) {
                        final product = _similarProducts[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: product['imageUrl'] != ''
                                ? Image.network(
                                    product['imageUrl'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.fastfood),
                            title: Text(
                                '${product['name']} (${product['brand']})'),
                            subtitle: Text(
                              (product['allergens'] != null &&
                                      product['allergens'].isNotEmpty)
                                  ? 'Allergens: ${product['allergens'].join(', ')}'
                                  : 'No allergen info',
                            ),
                            trailing: Text('${product['nf_calories']} cal'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
