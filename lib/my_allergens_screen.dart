import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart';

class MyAllergensScreen extends StatelessWidget {
  final Map<String, IconData> allergenIcons = {
    'Milk': Icons.local_drink,
    'Eggs': Icons.egg,
    'Fish': Icons.set_meal,
    'Crustacean Shellfish': Icons.restaurant_menu,
    'Tree Nuts': Icons.nature,
    'Peanuts': Icons.spa,
    'Wheat': Icons.grain,
    'Soybeans': Icons.eco,
    'Sesame': Icons.bakery_dining,
  };

  MyAllergensScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Allergens'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/allergy_icon.png'),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Diet:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Allergens:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            dataProvider.allergens.isNotEmpty
                ? Column(
                    children: dataProvider.allergens.keys.map((allergen) {
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: Icon(
                            allergenIcons[allergen] ?? Icons.error,
                            color: Colors.red,
                          ),
                          title: Text(
                            allergen,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : const Text(
                    'No allergens selected',
                    style: TextStyle(fontSize: 16),
                  ),
          ],
        ),
      ),
    );
  }
}
