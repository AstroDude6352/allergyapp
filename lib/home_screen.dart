import 'package:allergy_app/data_provider.dart';
import 'package:allergy_app/mealplanner.dart';
import 'package:allergy_app/reaction_log.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int? _pendingIndex;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      Provider.of<DataProvider>(context, listen: false).loadUserPreferences();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _processPendingNavigation();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _processPendingNavigation();
  }

  void _processPendingNavigation() {
    if (_pendingIndex != null) {
      final indexToNavigate = _pendingIndex!;
      _pendingIndex = null;

      Widget destination;
      switch (indexToNavigate) {
        case 0:
          destination = const HomeScreen();
          break;
        case 1:
          destination = const ReactionLogScreen();
          break;
        case 2:
          final allergens = Provider.of<DataProvider>(context, listen: false)
              .allergens
              .keys
              .toList();
          destination = MealPlannerScreen(allergens: allergens);
          break;
        case 3:
          destination = const ProfileScreen();
          break;
        default:
          destination = const HomeScreen();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => destination),
        );
      });
    }
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _pendingIndex = index; // mark navigation for later
      _currentIndex = index;
      didChangeDependencies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1E33),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF282A45),
        elevation: 4,
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Welcome!',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.medical_services,
                size: 40,
                color: Colors.tealAccent,
              ),
            ],
          ),
        ),
        toolbarHeight: 120,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Card(
                color: Colors.tealAccent.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Text(
                    'Stay safe! Your allergies are manageable with the right info.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Card(
                color: Colors.tealAccent.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Text(
                    'This app is an MVP. New features are currently in development.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2E2F45),
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white70,
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: 'Reactions'),
          BottomNavigationBarItem(
              icon: Icon(Icons.insights), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
