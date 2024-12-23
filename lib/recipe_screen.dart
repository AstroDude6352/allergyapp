import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

import 'main.dart';
class RecipeScreen extends StatefulWidget {
  final String diet;
  final List<String> allergens;

  const RecipeScreen({Key? key, required this.diet, required this.allergens}) : super(key: key);

  @override
  _RecipeScreenState createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  List<String> recipeLinks = []; // Store the recipe links
  bool isLoading = true; // Flag to show loading indicator

  @override
  void initState() {
    super.initState();
    fetchRecipeLinks();
  }

  void fetchRecipeLinks() async {
    // Create allergen string from selected allergens
    String allergenString = widget.allergens.join(', ');

    // Create the Gemini prompt dynamically based on the user's selected diet and allergens
    final prompt =
        'Find recipes that are suitable for the diet: ${widget.diet}, and do not contain any of the following allergens: $allergenString. Provide a list of recipe links.';

    final schema = Schema.array(
      description: 'List of recipe links',
      items: Schema.object(properties: {
        'link': Schema.string(description: 'URL of the recipe link.', nullable: false),
      }, requiredProperties: ['link']),
    );

    final model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: globalApiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
      ),
    );

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final responseDisplay = response.text;

      if (responseDisplay != null) {
        try {
          final linksData = jsonDecode(responseDisplay) as List<dynamic>;
          setState(() {
            // Extract the recipe links from the response
            recipeLinks = linksData.map((linkData) => linkData['link'] as String).toList();
            isLoading = false; // Set loading to false once links are loaded
          });
        } catch (e) {
          print('Error parsing response: $e');
        }
      }
    } catch (e) {
      print('Error fetching recipes: $e');
      setState(() {
        isLoading = false; // Set loading to false if there was an error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipe Links')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator()) // Show loading spinner while fetching
              : recipeLinks.isEmpty
              ? const Center(child: Text('No recipes found based on your preferences'))
              : ListView.builder(
            itemCount: recipeLinks.length,
            itemBuilder: (context, index) {
              final link = recipeLinks[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text('Recipe ${index + 1}'),
                  subtitle: Text(link),
                  onTap: () {
                    // Navigate to the WebView screen with the recipe link
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WebViewScreen(url: link),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class WebViewScreen extends StatelessWidget {
  final String url;

  const WebViewScreen({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recipe WebView')),
      body: WebViewWidget(controller: WebViewController()..loadRequest(Uri.parse(url))),
    );
  }
}


