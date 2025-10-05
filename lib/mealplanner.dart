import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

// Main Meal Planner Screen
class MealPlannerScreen extends StatefulWidget {
  final List<String> allergens;

  const MealPlannerScreen({super.key, required this.allergens});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final SpeechToText _speechToText = SpeechToText();

  File? _selectedImage;
  String _transcribedText = '';
  bool _isListening = false;
  bool _isProcessing = false;

  List<Recipe> _generatedRecipes = [];
  Map<String, dynamic>? _nutritionAnalysis;
  List<String> _detectedIngredients = [];
  final Map<String, IngredientDetail> _ingredientDetails =
      {}; // New: Store ingredient specifics
  String _selectedCuisine = 'Any';
  String _mealType = 'Any';
  int _servings = 2;
  final String _skillLevel = 'intermediate';
  List<String> _dietaryPreferences =
      []; // New: vegan, vegetarian, dairy-free, etc.

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    await _speechToText.initialize();
    await _loadDietaryPreferences();
  }

  Future<void> _loadDietaryPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dietaryPreferences = prefs.getStringList('dietary_preferences') ?? [];
    });
  }

  // Capture image from camera or gallery
  Future<void> _captureImage(ImageSource source) async {
    final status = source == ImageSource.camera
        ? await Permission.camera.request()
        : await Permission.photos.request();

    if (status.isGranted) {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _transcribedText = '';
        });
      }
    }
  }

  // Start voice recording
  Future<void> _startListening() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      setState(() => _isListening = true);
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _transcribedText = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 30),
      );
    }
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  // Process image with Firebase ML Kit Image Labeling
  Future<List<String>> _analyzeImageForIngredients(File image) async {
    try {
      final inputImage = InputImage.fromFile(image);
      final imageLabeler = ImageLabeler(
          options: ImageLabelerOptions(
        confidenceThreshold: 0.5, // Only include labels with 50%+ confidence
      ));

      final labels = await imageLabeler.processImage(inputImage);

      // Filter for food-related labels
      final foodKeywords = [
        'food',
        'ingredient',
        'vegetable',
        'fruit',
        'meat',
        'protein',
        'dairy',
        'grain',
        'spice',
        'herb',
        'produce',
        'seafood',
        'chicken',
        'beef',
        'pork',
        'fish',
        'egg',
        'cheese',
        'milk',
        'tomato',
        'potato',
        'onion',
        'garlic',
        'carrot',
        'broccoli',
        'lettuce',
        'spinach',
        'pepper',
        'mushroom',
        'cucumber',
        'apple',
        'banana',
        'orange',
        'lemon',
        'berry',
        'pasta',
        'rice',
        'bread',
        'noodle',
        'bean',
        'nut',
        'oil',
        'butter'
      ];

      final ingredients = <String>[];

      for (var label in labels) {
        final labelText = label.label.toLowerCase();

        // Check if label is food-related
        if (foodKeywords.any((keyword) => labelText.contains(keyword))) {
          ingredients.add(label.label);
          print(
              'Detected: ${label.label} (${(label.confidence * 100).toStringAsFixed(1)}%)');
        }
      }

      await imageLabeler.close();

      // If we found ingredients, return them
      if (ingredients.isNotEmpty) {
        return ingredients;
      }

      // Fallback: return all high-confidence labels if no food detected
      return labels
          .where((label) => label.confidence > 0.7)
          .map((label) => label.label)
          .toList();
    } catch (e) {
      print('Error analyzing image with ML Kit: $e');
      _showError('Failed to analyze image. Please try again.');
      return [];
    }
  }

  // Parse voice/text input for ingredients
  List<String> _extractIngredientsFromText(String text) {
    // Simple extraction - can be enhanced with NLP
    final commonIngredients = [
      'chicken',
      'beef',
      'pork',
      'fish',
      'shrimp',
      'tofu',
      'rice',
      'pasta',
      'noodles',
      'bread',
      'tomato',
      'onion',
      'garlic',
      'potato',
      'carrot',
      'broccoli',
      'milk',
      'cheese',
      'butter',
      'egg',
      'cream',
      'salt',
      'pepper',
      'oil',
      'soy sauce',
      'vinegar',
    ];

    final words = text.toLowerCase().split(RegExp(r'[\s,]+'));
    return words
        .where((word) => commonIngredients.any((ing) => word.contains(ing)))
        .toList();
  }

  // Generate personalized recipes with AI
  Future<void> _generateRecipes() async {
    setState(() => _isProcessing = true);

    try {
      // Get ingredients from image or voice
      if (_selectedImage != null) {
        _detectedIngredients =
            await _analyzeImageForIngredients(_selectedImage!);
        // Auto-apply dietary preferences to detected ingredients
        _applyDietaryPreferencesToIngredients();
      } else if (_transcribedText.isNotEmpty) {
        _detectedIngredients = _extractIngredientsFromText(_transcribedText);
        _applyDietaryPreferencesToIngredients();
      }

      // Create personalized prompt with user context
      final userProfile = await _getUserProfile();
      final prompt = _buildPersonalizedPrompt(
        ingredients: _detectedIngredients,
        allergens: widget.allergens,
        userProfile: userProfile,
      );

      // Call AI API (OpenAI, Claude, etc.)
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_KEY',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo-preview',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a creative chef and nutritionist specializing in personalized meal planning.'
            },
            {'role': 'user', 'content': prompt}
          ],
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = jsonDecode(data['choices'][0]['message']['content']);

        setState(() {
          _generatedRecipes = (content['recipes'] as List)
              .map((r) => Recipe.fromJson(r))
              .toList();
          _nutritionAnalysis = content['nutrition_analysis'];
        });

        // Save to user's meal history
        await _saveMealPlanToHistory();
      }
    } catch (e) {
      _showError('Failed to generate recipes: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // Build personalized prompt with unique features
  String _buildPersonalizedPrompt({
    required List<String> ingredients,
    required List<String> allergens,
    required Map<String, dynamic> userProfile,
  }) {
    // Build detailed ingredient list with specifications
    final detailedIngredients = ingredients.map((ing) {
      final detail = _ingredientDetails[ing];
      if (detail == null) return ing;

      final specs = <String>[];
      if (detail.isVegan) specs.add('vegan');
      if (detail.isDairyFree) specs.add('dairy-free');
      if (detail.isGlutenFree) specs.add('gluten-free');
      if (detail.isOrganic) specs.add('organic');
      if (detail.note != null) specs.add(detail.note!);

      return specs.isEmpty ? ing : '$ing (${specs.join(', ')})';
    }).join(',');

    return '''
Create 3 unique, personalized recipes using these ingredients: $detailedIngredients

CRITICAL REQUIREMENTS:
- Exclude ALL allergens: ${allergens.join(', ')}
- Dietary preferences: ${_dietaryPreferences.join(', ')}
- Cuisine preference: $_selectedCuisine
- Meal type: $_mealType
- Servings: $_servings
- Skill level: $_skillLevel

IMPORTANT INGREDIENT SPECIFICATIONS:
${_ingredientDetails.entries.map((e) {
      final d = e.value;
      final specs = <String>[];
      if (d.isVegan) specs.add('MUST BE VEGAN');
      if (d.isDairyFree) specs.add('MUST BE DAIRY-FREE');
      if (d.isGlutenFree) specs.add('MUST BE GLUTEN-FREE');
      return '- ${e.key}: ${specs.join(', ')}${d.note != null ? ' (${d.note})' : ''}';
    }).join('\n')}

USER CONTEXT:
- Favorite cuisines: ${userProfile['favoriteCuisines']}
- Dietary preferences: ${userProfile['dietaryPreferences']}
- Cooking frequency: ${userProfile['cookingFrequency']}
- Past liked recipes: ${userProfile['likedFlavors']}
- Disliked ingredients: ${userProfile['dislikedIngredients']}
- Available cooking time: ${userProfile['typicalCookingTime']} minutes
- Kitchen equipment: ${userProfile['availableEquipment']}

UNIQUE FEATURES TO INCLUDE:
1. Suggest ingredient substitutions based on user's allergens
2. Provide meal prep tips for advance preparation
3. Include estimated costs per serving
4. Add flavor pairing suggestions
5. Suggest wine/beverage pairings
6. Include seasonal variations of the recipe
7. Provide storage and reheating instructions
8. Add nutritional breakdown per serving
9. Include difficulty-adjusted cooking techniques
10. Suggest complementary side dishes

Return JSON format:
{
  "recipes": [
    {
      "name": "Recipe Name",
      "description": "Brief description",
      "cookTime": 30,
      "prepTime": 15,
      "difficulty": "easy|medium|hard",
      "ingredients": [{"item": "ingredient", "amount": "1 cup", "substitutions": ["alt1", "alt2"]}],
      "instructions": ["step 1", "step 2"],
      "nutrition": {"calories": 450, "protein": "25g", "carbs": "40g", "fat": "15g"},
      "cost": {"total": 12.50, "perServing": 6.25},
      "tags": ["quick", "healthy"],
      "mealPrepTips": ["tip1", "tip2"],
      "pairings": {"beverage": "suggestion", "sides": ["side1", "side2"]},
      "seasonalVariations": "description",
      "storage": "storage instructions"
    }
  ],
  "nutrition_analysis": {
    "balanceScore": 85,
    "allergenWarnings": [],
    "healthInsights": ["insight1", "insight2"]
  }
}
''';
  }

  // Get user profile for personalization
  Future<Map<String, dynamic>> _getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'favoriteCuisines':
          prefs.getStringList('favorite_cuisines') ?? ['Italian', 'Mexican'],
      'dietaryPreferences': prefs.getStringList('dietary_prefs') ?? [],
      'cookingFrequency': prefs.getString('cooking_frequency') ?? 'weekly',
      'likedFlavors': prefs.getStringList('liked_flavors') ?? [],
      'dislikedIngredients': prefs.getStringList('disliked_ingredients') ?? [],
      'typicalCookingTime': prefs.getInt('typical_cooking_time') ?? 45,
      'availableEquipment': prefs.getStringList('kitchen_equipment') ??
          ['oven', 'stove', 'microwave'],
    };
  }

  Future<void> _saveMealPlanToHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('meal_history') ?? [];
    history.add(jsonEncode({
      'date': DateTime.now().toIso8601String(),
      'ingredients': _detectedIngredients,
      'recipes': _generatedRecipes.map((r) => r.toJson()).toList(),
    }));
    await prefs.setStringList('meal_history', history);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Auto-apply dietary preferences to ingredients
  void _applyDietaryPreferencesToIngredients() {
    for (var ingredient in _detectedIngredients) {
      final lowerIng = ingredient.toLowerCase();

      // Initialize ingredient detail if not exists
      if (!_ingredientDetails.containsKey(ingredient)) {
        _ingredientDetails[ingredient] = IngredientDetail(
          name: ingredient,
          isVegan: _isVeganIngredient(lowerIng),
          isDairyFree: _isDairyFreeIngredient(lowerIng),
          isGlutenFree: _isGlutenFreeIngredient(lowerIng),
        );
      }

      // Apply dietary preferences
      if (_dietaryPreferences.contains('Vegan') &&
          !_ingredientDetails[ingredient]!.isVegan) {
        _ingredientDetails[ingredient] = _ingredientDetails[ingredient]!
            .copyWith(isVegan: true, note: 'Using vegan alternative');
      }

      if (_dietaryPreferences.contains('Dairy-Free') &&
          !_ingredientDetails[ingredient]!.isDairyFree) {
        _ingredientDetails[ingredient] = _ingredientDetails[ingredient]!
            .copyWith(isDairyFree: true, note: 'Using dairy-free alternative');
      }
    }
  }

  bool _isVeganIngredient(String ingredient) {
    final nonVegan = [
      'chicken',
      'beef',
      'pork',
      'fish',
      'meat',
      'egg',
      'milk',
      'cheese',
      'yogurt',
      'butter',
      'cream',
      'honey'
    ];
    return !nonVegan.any((nv) => ingredient.contains(nv));
  }

  bool _isDairyFreeIngredient(String ingredient) {
    final dairy = ['milk', 'cheese', 'yogurt', 'butter', 'cream', 'dairy'];
    return !dairy.any((d) => ingredient.contains(d));
  }

  bool _isGlutenFreeIngredient(String ingredient) {
    final gluten = ['bread', 'pasta', 'wheat', 'flour', 'noodle'];
    return !gluten.any((g) => ingredient.contains(g));
  }

  // Show dialog to edit ingredient details
  void _editIngredientDetails(String ingredient) {
    final detail =
        _ingredientDetails[ingredient] ?? IngredientDetail(name: ingredient);

    showDialog(
      context: context,
      builder: (context) => IngredientDetailDialog(
        ingredient: ingredient,
        detail: detail,
        onSave: (updatedDetail) {
          setState(() {
            _ingredientDetails[ingredient] = updatedDetail;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Meal Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to meal history
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Ingredients',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Image capture buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _captureImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _captureImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                          ),
                        ),
                      ],
                    ),

                    if (_selectedImage != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Voice input
                    ElevatedButton.icon(
                      onPressed:
                          _isListening ? _stopListening : _startListening,
                      icon: Icon(_isListening ? Icons.stop : Icons.mic),
                      label:
                          Text(_isListening ? 'Stop Recording' : 'Voice Input'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isListening ? Colors.red : null,
                      ),
                    ),

                    if (_transcribedText.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_transcribedText),
                      ),
                    ],

                    if (_detectedIngredients.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Detected Ingredients:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _detectedIngredients.map((ing) {
                          final detail = _ingredientDetails[ing];
                          final hasSpecs = detail != null &&
                              (detail.isVegan ||
                                  detail.isDairyFree ||
                                  detail.isGlutenFree);

                          return GestureDetector(
                            onTap: () => _editIngredientDetails(ing),
                            child: Chip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(ing),
                                  if (hasSpecs) ...[
                                    const SizedBox(width: 4),
                                    Icon(Icons.info_outline,
                                        size: 14, color: Colors.blue[700]),
                                  ],
                                ],
                              ),
                              backgroundColor: hasSpecs
                                  ? Colors.blue[100]
                                  : Colors.green[100],
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setState(() {
                                  _detectedIngredients.remove(ing);
                                  _ingredientDetails.remove(ing);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap ingredient to specify (e.g., vegan yogurt)',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Preferences Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customize Your Meal',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Dietary Preferences
                    const Text('Dietary Preferences:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        'Vegan',
                        'Vegetarian',
                        'Dairy-Free',
                        'Gluten-Free',
                        'Keto',
                        'Paleo'
                      ]
                          .map((pref) => FilterChip(
                                label: Text(pref),
                                selected: _dietaryPreferences.contains(pref),
                                onSelected: (selected) async {
                                  setState(() {
                                    if (selected) {
                                      _dietaryPreferences.add(pref);
                                    } else {
                                      _dietaryPreferences.remove(pref);
                                    }
                                  });
                                  // Save preferences
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setStringList(
                                      'dietary_preferences',
                                      _dietaryPreferences);
                                  // Reapply to ingredients
                                  _applyDietaryPreferencesToIngredients();
                                },
                              ))
                          .toList(),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedCuisine,
                      decoration: const InputDecoration(labelText: 'Cuisine'),
                      items: [
                        'Any',
                        'Italian',
                        'Mexican',
                        'Asian',
                        'Mediterranean',
                        'American'
                      ]
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCuisine = val!),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _mealType,
                      decoration: const InputDecoration(labelText: 'Meal Type'),
                      items: ['Any', 'Breakfast', 'Lunch', 'Dinner', 'Snack']
                          .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (val) => setState(() => _mealType = val!),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const Text('Servings:'),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () => setState(() =>
                              _servings = (_servings > 1) ? _servings - 1 : 1),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('$_servings',
                            style: const TextStyle(fontSize: 18)),
                        IconButton(
                          onPressed: () => setState(() => _servings++),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),

                    if (widget.allergens.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: widget.allergens
                            .map((allergen) => Chip(
                                  label: Text(allergen),
                                  backgroundColor: Colors.red[100],
                                  deleteIcon: const Icon(Icons.block, size: 18),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Generate button
            ElevatedButton(
              onPressed:
                  (_selectedImage != null || _transcribedText.isNotEmpty) &&
                          !_isProcessing
                      ? _generateRecipes
                      : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : const Text('Generate Personalized Recipes',
                      style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 24),

            // Results Section
            if (_generatedRecipes.isNotEmpty) ...[
              const Text(
                'Your Personalized Recipes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_nutritionAnalysis != null)
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nutrition Balance Score: ${_nutritionAnalysis!['balanceScore']}/100',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (_nutritionAnalysis!['healthInsights'] != null)
                          ...(_nutritionAnalysis!['healthInsights'] as List)
                              .map(
                            (insight) => Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.lightbulb, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(insight)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              ..._generatedRecipes.map((recipe) => RecipeCard(recipe: recipe)),
            ],
          ],
        ),
      ),
    );
  }
}

// Ingredient Detail Model
class IngredientDetail {
  final String name;
  final bool isVegan;
  final bool isDairyFree;
  final bool isGlutenFree;
  final bool isOrganic;
  final String? note;

  IngredientDetail({
    required this.name,
    this.isVegan = false,
    this.isDairyFree = false,
    this.isGlutenFree = false,
    this.isOrganic = false,
    this.note,
  });

  IngredientDetail copyWith({
    String? name,
    bool? isVegan,
    bool? isDairyFree,
    bool? isGlutenFree,
    bool? isOrganic,
    String? note,
  }) {
    return IngredientDetail(
      name: name ?? this.name,
      isVegan: isVegan ?? this.isVegan,
      isDairyFree: isDairyFree ?? this.isDairyFree,
      isGlutenFree: isGlutenFree ?? this.isGlutenFree,
      isOrganic: isOrganic ?? this.isOrganic,
      note: note ?? this.note,
    );
  }
}

// Ingredient Detail Dialog
class IngredientDetailDialog extends StatefulWidget {
  final String ingredient;
  final IngredientDetail detail;
  final Function(IngredientDetail) onSave;

  const IngredientDetailDialog({
    super.key,
    required this.ingredient,
    required this.detail,
    required this.onSave,
  });

  @override
  State<IngredientDetailDialog> createState() => _IngredientDetailDialogState();
}

class _IngredientDetailDialogState extends State<IngredientDetailDialog> {
  late bool _isVegan;
  late bool _isDairyFree;
  late bool _isGlutenFree;
  late bool _isOrganic;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _isVegan = widget.detail.isVegan;
    _isDairyFree = widget.detail.isDairyFree;
    _isGlutenFree = widget.detail.isGlutenFree;
    _isOrganic = widget.detail.isOrganic;
    _noteController = TextEditingController(text: widget.detail.note);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Specify: ${widget.ingredient}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose ingredient specifications:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Vegan'),
              subtitle: const Text('Plant-based, no animal products'),
              value: _isVegan,
              onChanged: (val) => setState(() => _isVegan = val!),
            ),
            CheckboxListTile(
              title: const Text('Dairy-Free'),
              subtitle: const Text('No milk, cheese, or dairy'),
              value: _isDairyFree,
              onChanged: (val) => setState(() => _isDairyFree = val!),
            ),
            CheckboxListTile(
              title: const Text('Gluten-Free'),
              subtitle: const Text('No wheat or gluten'),
              value: _isGlutenFree,
              onChanged: (val) => setState(() => _isGlutenFree = val!),
            ),
            CheckboxListTile(
              title: const Text('Organic'),
              subtitle: const Text('Certified organic'),
              value: _isOrganic,
              onChanged: (val) => setState(() => _isOrganic = val!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes (optional)',
                hintText: 'e.g., low-fat, unsweetened',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(
              IngredientDetail(
                name: widget.ingredient,
                isVegan: _isVegan,
                isDairyFree: _isDairyFree,
                isGlutenFree: _isGlutenFree,
                isOrganic: _isOrganic,
                note: _noteController.text.isNotEmpty
                    ? _noteController.text
                    : null,
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}

// Recipe Model
class Recipe {
  final String name;
  final String description;
  final int cookTime;
  final int prepTime;
  final String difficulty;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final Map<String, dynamic> nutrition;
  final Map<String, dynamic>? cost;
  final List<String> tags;
  final List<String>? mealPrepTips;
  final Map<String, dynamic>? pairings;
  final String? seasonalVariations;
  final String? storage;

  Recipe({
    required this.name,
    required this.description,
    required this.cookTime,
    required this.prepTime,
    required this.difficulty,
    required this.ingredients,
    required this.instructions,
    required this.nutrition,
    this.cost,
    required this.tags,
    this.mealPrepTips,
    this.pairings,
    this.seasonalVariations,
    this.storage,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      name: json['name'],
      description: json['description'],
      cookTime: json['cookTime'],
      prepTime: json['prepTime'],
      difficulty: json['difficulty'],
      ingredients: (json['ingredients'] as List)
          .map((i) => Ingredient.fromJson(i))
          .toList(),
      instructions: List<String>.from(json['instructions']),
      nutrition: json['nutrition'],
      cost: json['cost'],
      tags: List<String>.from(json['tags']),
      mealPrepTips: json['mealPrepTips'] != null
          ? List<String>.from(json['mealPrepTips'])
          : null,
      pairings: json['pairings'],
      seasonalVariations: json['seasonalVariations'],
      storage: json['storage'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'cookTime': cookTime,
        'prepTime': prepTime,
        'difficulty': difficulty,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'instructions': instructions,
        'nutrition': nutrition,
        'cost': cost,
        'tags': tags,
        'mealPrepTips': mealPrepTips,
        'pairings': pairings,
        'seasonalVariations': seasonalVariations,
        'storage': storage,
      };
}

class Ingredient {
  final String item;
  final String amount;
  final List<String>? substitutions;

  Ingredient({required this.item, required this.amount, this.substitutions});

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      item: json['item'],
      amount: json['amount'],
      substitutions: json['substitutions'] != null
          ? List<String>.from(json['substitutions'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'item': item,
        'amount': amount,
        'substitutions': substitutions,
      };
}

// Recipe Card Widget
class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          recipe.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recipe.description),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text('${recipe.prepTime + recipe.cookTime} min'),
                  avatar: const Icon(Icons.timer, size: 16),
                ),
                Chip(
                  label: Text(recipe.difficulty),
                  avatar: const Icon(Icons.bar_chart, size: 16),
                ),
                if (recipe.cost != null)
                  Chip(
                    label: Text(
                        '\$${recipe.cost!['perServing'].toStringAsFixed(2)}/serving'),
                    avatar: const Icon(Icons.attach_money, size: 16),
                  ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ingredients:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...recipe.ingredients.map((ing) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ${ing.amount} ${ing.item}'),
                          if (ing.substitutions != null &&
                              ing.substitutions!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Text(
                                'Substitutes: ${ing.substitutions!.join(', ')}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                const Text('Instructions:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...recipe.instructions.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Text('${entry.key + 1}. ${entry.value}'),
                    )),
                const SizedBox(height: 16),
                const Text('Nutrition (per serving):',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text('${recipe.nutrition['calories']} cal')),
                    Chip(
                        label: Text('Protein: ${recipe.nutrition['protein']}')),
                    Chip(label: Text('Carbs: ${recipe.nutrition['carbs']}')),
                    Chip(label: Text('Fat: ${recipe.nutrition['fat']}')),
                  ],
                ),
                if (recipe.mealPrepTips != null) ...[
                  const SizedBox(height: 16),
                  const Text('Meal Prep Tips:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...recipe.mealPrepTips!.map((tip) => Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Text('• $tip'),
                      )),
                ],
                if (recipe.pairings != null) ...[
                  const SizedBox(height: 16),
                  const Text('Perfect Pairings:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text('Beverage: ${recipe.pairings!['beverage']}'),
                  ),
                  if (recipe.pairings!['sides'] != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Text(
                          'Sides: ${(recipe.pairings!['sides'] as List).join(', ')}'),
                    ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Add to meal plan
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Add to Plan'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Share recipe
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
