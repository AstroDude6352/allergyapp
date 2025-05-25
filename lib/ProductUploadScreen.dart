import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';

class ProductUploadScreen extends StatefulWidget {
  const ProductUploadScreen({super.key});

  @override
  State<ProductUploadScreen> createState() => _ProductUploadScreenState();
}

class _ProductUploadScreenState extends State<ProductUploadScreen> {
  File? _imageFile;
  bool _isLoading = false;
  List<Map<String, dynamic>> _recommendedProducts = [];

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadAndAnalyze() async {
    if (_imageFile == null) return;

    setState(() => _isLoading = true);

    try {
      final key = 'uploads/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final StorageUploadFileOperation<StorageUploadFileRequest,
              StorageUploadFileResult<StorageItem>> operation =
          Amplify.Storage.uploadFile(
        localFile: _imageFile!,
        key: key,
        options:
            const S3UploadFileOptions(accessLevel: StorageAccessLevel.private),
      );

      final StorageUploadFileResult<StorageItem> result =
          await operation.result;

      debugPrint('Image uploaded with key: ${result.key}');

      // Send key to your backend function (e.g., using REST API or GraphQL)
      // Dummy example:
      final recommendations = await _mockBackendCall(result.key);

      setState(() {
        _recommendedProducts = recommendations;
      });
    } catch (e) {
      debugPrint('Upload failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🔧 Replace this with your actual API call
  Future<List<Map<String, dynamic>>> _mockBackendCall(String imageKey) async {
    await Future.delayed(const Duration(seconds: 2)); // simulate backend delay
    return [
      {
        'name': 'Almond Milk',
        'image': 'https://via.placeholder.com/150',
        'safe': false,
      },
      {
        'name': 'Soy Milk',
        'image': 'https://via.placeholder.com/150',
        'safe': true,
      },
    ];
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
                ? Image.file(_imageFile!, height: 200)
                : const Placeholder(fallbackHeight: 200),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                ),
                ElevatedButton.icon(
                  onPressed: _uploadAndAnalyze,
                  icon: const Icon(Icons.upload),
                  label: const Text('Analyze'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _recommendedProducts.length,
                      itemBuilder: (context, index) {
                        final product = _recommendedProducts[index];
                        return Card(
                          child: ListTile(
                            leading: Image.network(product['image']),
                            title: Text(product['name']),
                            subtitle: Text(product['safe']
                                ? 'Safe for your allergies ✅'
                                : '⚠️ Contains allergens'),
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
