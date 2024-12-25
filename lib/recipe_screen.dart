import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'main.dart';

class RecipeScreen extends StatefulWidget {
  final String diet;
  final List<String> allergens;

  const RecipeScreen({Key? key, required this.diet, required this.allergens})
      : super(key: key);

  @override
  _RecipeScreenState createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  List<SwipeItem> swipeItems = [];
  MatchEngine? matchEngine;
  bool isFetching = false;
  int fetchBatchSize = 10;

  @override
  void initState() {
    super.initState();
    fetchAndPrepareRecipes(); // Start fetching recipes in the background
  }

  Future<bool> validateUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, String>>> validateRecipes(List<Map<String, String>> rawRecipes) async {
    final validated = await Future.wait(rawRecipes.map((recipe) async {
      final isLinkValid = await validateUrl(recipe['link']!);
      final isImageValid = await validateUrl(recipe['image']!);

      return isLinkValid && isImageValid ? recipe : null;
    }));

    return validated.whereType<Map<String, String>>().toList();
  }

  void fetchAndPrepareRecipes() async {
    if (isFetching) return;

    setState(() {
      isFetching = true;
    });

    String allergenString = widget.allergens.join(', ');

    final prompt = '''
Find $fetchBatchSize valid recipes suitable for the diet: ${widget.diet}, excluding these allergens: $allergenString.
Provide the following details for each recipe: name, image URL, and recipe URL. Return them in a structured JSON array format like this:
[{"name": "Recipe 1", "image": "https://example.com/image1.jpg", "link": "https://example.com/recipe1"}].
''';

    final schema = Schema.array(
      description: 'List of recipe details',
      items: Schema.object(properties: {
        'name': Schema.string(description: 'Name of the recipe.', nullable: false),
        'image': Schema.string(description: 'URL of the recipe image.', nullable: false),
        'link': Schema.string(description: 'URL of the recipe link.', nullable: false),
      }, requiredProperties: ['name', 'image', 'link']),
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
        final rawRecipes = (jsonDecode(responseDisplay) as List<dynamic>)
            .map((recipeData) => {
          'name': recipeData['name'] as String,
          'image': recipeData['image'] as String,
          'link': recipeData['link'] as String,
        }).toList();

        final validRecipes = await validateRecipes(rawRecipes);

        if (validRecipes.isNotEmpty) {
          setState(() {
            swipeItems.addAll(validRecipes.map((recipe) {
              return SwipeItem(
                content: recipe,
                likeAction: () => print('Liked: ${recipe['link']}'),
                nopeAction: () => print('Disliked: ${recipe['link']}'),
              );
            }));
            matchEngine?.notifyListeners();
          });

          // Fetch next batch after 3 seconds in the background to avoid UI blockage
          Future.delayed(Duration(seconds: 3), fetchAndPrepareRecipes);
        }
      }
    } catch (e) {
      print('Error fetching recipes: $e');
    } finally {
      setState(() {
        isFetching = false;
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
          child: swipeItems.isEmpty
              ? const Center(child: CircularProgressIndicator()) // Show loading if no recipes yet
              : SwipeCards(
            matchEngine: matchEngine ??= MatchEngine(swipeItems: swipeItems),
            onStackFinished: () {
              fetchAndPrepareRecipes(); // Fetch more recipes once the stack is finished
            },
            itemBuilder: (context, index) {
              final recipe = swipeItems[index].content as Map<String, String>;
              return Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CachedNetworkImage(
                      imageUrl: recipe['image']!,
                      placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        recipe['name']!,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WebViewScreen(url: recipe['link']!),
                          ),
                        );
                      },
                      child: const Text('View Recipe'),
                    ),
                  ],
                ),
              );
            },
            upSwipeAllowed: false,
            leftSwipeAllowed: true,
            rightSwipeAllowed: true,
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
