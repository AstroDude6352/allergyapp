import 'package:flutter/material.dart';
import 'package:openfoodfacts/src/model/ingredient.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart';

class Ingredients extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final List<String>? allergens;
  final List<Ingredient>? ingredients;

  const Ingredients(this.imageUrl, this.name, this.allergens, this.ingredients, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userAllergens = Provider.of<DataProvider>(context).selectedAllergens;
    bool isSafeForUser = allergens == null || allergens!.isEmpty || !allergens!.any((allergen) => userAllergens.contains(allergen));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          name ?? "Unknown Product",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1D1E33),
      ),
      backgroundColor: const Color(0xFF1D1E33),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl!,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100, color: Colors.white),
                  ),
                ),
              ),
            const SizedBox(height: 15),
            if (isSafeForUser)
              Card(
                color: const Color(0xFF282A45),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: const ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text(
                    'This product is safe based on your allergen preferences.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              )
            else ...[
              const Text(
                'Contains',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 5),
              ...allergens!.map((allergen) => Card(
                color: const Color(0xFF282A45),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: Icon(
                    userAllergens.contains(allergen) ? Icons.warning : Icons.info,
                    color: userAllergens.contains(allergen) ? Colors.redAccent : Colors.yellowAccent,
                  ),
                  title: Text(
                    allergen,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              )),
            ],
            const SizedBox(height: 15),
            const Text(
              'Ingredients',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 5),
            Card(
              color: const Color(0xFF282A45),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: ingredients != null && ingredients!.isNotEmpty
                      ? ingredients!.map((ingredient) => ListTile(
                    title: Text(
                      ingredient.text?.toLowerCase() ?? "unknown ingredient",
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  )).toList()
                      : [
                    const Text(
                      'Ingredients Not Found.',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
