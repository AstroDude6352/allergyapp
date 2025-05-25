import 'package:allergy_app/amplifyconfiguration.dart';
import 'package:allergy_app/recipe_screen.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'data_provider.dart';
import 'quiz_screen.dart';

const globalApiKey = 'AIzaSyCzPlrOqftEAJSIkNFjzyKUr3pGKWPKl5o';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureAmplify();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DataProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> configureAmplify() async {
  try {
    if (!Amplify.isConfigured) {
      await Amplify.addPlugin(AmplifyStorageS3());
      await Amplify.configure(amplifyconfig);
    }
  } catch (e) {
    print('Error configuring Amplify: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QuizScreen(),
    );
  }
}
