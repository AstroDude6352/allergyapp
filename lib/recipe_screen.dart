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
  bool isLoading = true;
  bool isFetching = false;
  int fetchBatchSize = 30;

  @override
  void initState() {
    super.initState();
    fetchAndPrepareRecipes(); // Initial fetch to load first batch of recipes
  }

  Future<bool> validateUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void fetchAndPrepareRecipes({bool isPrefetch = false}) async {
    if (isFetching) return; // Avoid overlapping fetches

    setState(() {
      isFetching = true;
    });

    String allergenString = widget.allergens.join(', ');

    final prompt = '''
Find $fetchBatchSize valid recipe URLs suitable for the diet: ${widget.diet}, excluding these allergens: $allergenString. 
The URLs must lead to live, accessible recipe pages. Return them in a structured JSON array format like this: 
[{"link": "https://example.com/recipe1"}, {"link": "https://example.com/recipe2"}].
''';

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
        final rawLinks = (jsonDecode(responseDisplay) as List<dynamic>)
            .map((linkData) => linkData['link'] as String)
            .toList();

        List<String> validLinks = [];
        for (String link in rawLinks) {
          if (await validateUrl(link)) {
            validLinks.add(link);
            if (validLinks.length >= fetchBatchSize) break;
          }
        }

        if (validLinks.isNotEmpty) {
          setState(() {
            swipeItems.addAll(validLinks.map((link) {
              return SwipeItem(
                content: link,
                likeAction: () => print('Liked: $link'),
                nopeAction: () => print('Disliked: $link'),
              );
            }));
            matchEngine?.notifyListeners();
            isLoading = false; // Mark as loaded only if initial load is done
          });

          // Prefetch the next batch immediately if needed
          if (!isPrefetch) {
            fetchAndPrepareRecipes(isPrefetch: true); // Fetch next batch in the background
          }
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
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : NotificationListener<ScrollNotification>(
            onNotification: (scrollNotification) {
              return false; // Don't trigger fetching during scrolls
            },
            child: SwipeCards(
              matchEngine: matchEngine ??= MatchEngine(swipeItems: swipeItems),
              onStackFinished: () {
                fetchAndPrepareRecipes(isPrefetch: true); // Fetch more recipes immediately when stack finishes
              },
              itemBuilder: (context, index) {
                final link = swipeItems[index].content;
                return Card(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Recipe ${index + 1}', style: const TextStyle(fontSize: 18)),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(link, textAlign: TextAlign.center),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WebViewScreen(url: link),
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
