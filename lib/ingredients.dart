import 'package:flutter/material.dart';
import 'package:openfoodfacts/src/model/ingredient.dart';

class Ingredients extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final List<String>? names;
  final List<Ingredient>? ingredients;

  const Ingredients(this.imageUrl, this.name, this.names, this.ingredients,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var ingredientList = '';

    for (final ingredient in ingredients!) {
      ingredientList = '$ingredientList${ingredient.text ?? ""}, ';
    }
    ingredientList =
        ingredientList.substring(0, ingredientList.length - 2) + '.';

    print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ $imageUrl");
    var containsTitle = '\nContains';
    if (names!.isEmpty) containsTitle = '';
    if (ingredients!.isEmpty) ingredientList = 'Ingredients Not Found.';

    return Scaffold(
        appBar: AppBar(
          title: Text(
            name!,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        body: Container(
          height: 500,
          width: double.infinity,
          margin: const EdgeInsets.all(15.0),
          padding: const EdgeInsets.all(13.0),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Image.network(
                  imageUrl!,
                  width: double.infinity,
                  height: 150,
                ),
              ]),
              Text(
                'Ingredients',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                ingredientList,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
              ),
              Text(
                containsTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                names!.join(', '),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ));
  }
}
