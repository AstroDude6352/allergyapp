import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class RecipeFromImageScreen extends StatefulWidget {
  const RecipeFromImageScreen({super.key});

  @override
  State<RecipeFromImageScreen> createState() => _RecipeFromImageScreenState();
}

class _RecipeFromImageScreenState extends State<RecipeFromImageScreen> {
  File? _imageFile;
  bool _isLoading = false;
  String _generatedRecipe = '';

  final ImagePicker _picker = ImagePicker();
  final String _apiKey = 'YOUR_GEMINI_API_KEY'; // Replace this securely

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _generatedRecipe = '';
      });
      await _generateRecipe(_imageFile!);
    }
  }

  Future<void> _generateRecipe(File imageFile) async {
    setState(() => _isLoading = true);

    try {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=$_apiKey');

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "inlineData": {
                  "mimeType": "image/jpeg",
                  "data": base64Image,
                }
              },
              {
                "text":
                    "Create a detailed, allergy-friendly recipe using the ingredients in this image. Avoid common allergens like nuts, dairy, and gluten."
              }
            ]
          }
        ]
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final recipe = data['candidates'][0]['content']['parts'][0]['text'] ??
            'No recipe found.';
        setState(() => _generatedRecipe = recipe);
      } else {
        setState(() => _generatedRecipe = 'Error: ${response.body}');
      }
    } catch (e) {
      setState(() => _generatedRecipe = 'Failed to generate recipe: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipe From Image')),
      backgroundColor: const Color(0xFF1D1E33),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              onPressed: _isLoading ? null : _pickImage,
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(
                  child: CircularProgressIndicator(color: Colors.tealAccent)),
            if (_generatedRecipe.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                "Generated Recipe:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.tealAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _generatedRecipe,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
