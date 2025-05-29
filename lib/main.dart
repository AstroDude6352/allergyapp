import 'package:allergy_app/home_screen.dart';
import 'package:allergy_app/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_provider.dart';
import 'quiz_screen.dart';

const globalApiKey = 'AIzaSyCzPlrOqftEAJSIkNFjzyKUr3pGKWPKl5o';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final user = FirebaseAuth.instance.currentUser;
  final quizCompleted = prefs.getBool('quizCompleted') ?? false;

  Widget initialScreen;

  if (user != null && quizCompleted) {
    initialScreen = HomeScreen();
  } else {
    initialScreen = LoginScreen();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DataProvider()),
      ],
      child: MyApp(initialScreen: initialScreen),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: initialScreen,
    );
  }
}
