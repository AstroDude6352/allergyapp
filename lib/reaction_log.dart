import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import your other screens here:
import 'home_screen.dart';
import 'allergy_insights.dart';
import 'profile_screen.dart';

class ReactionLogScreen extends StatefulWidget {
  const ReactionLogScreen({super.key});

  @override
  State<ReactionLogScreen> createState() => _ReactionLogScreenState();
}

class _ReactionLogScreenState extends State<ReactionLogScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _foodController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedSeverity = 'Mild';

  final List<String> _severityOptions = ['Mild', 'Moderate', 'Severe'];
  final List<String> _availableSymptoms = [
    'Hives',
    'Swelling',
    'Nausea',
    'Vomiting',
    'Trouble Breathing'
  ];
  final List<String> _selectedSymptoms = [];

  List<Map<String, dynamic>> _loggedReactions = [];

  final int _currentIndex = 1; // Reaction Log is index 1 in navbar

  @override
  void initState() {
    super.initState();
    _loadReactions();
  }

  void _loadReactions() async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('reaction_logs');
    if (storedData != null) {
      setState(() {
        _loggedReactions =
            List<Map<String, dynamic>>.from(json.decode(storedData));
      });
    }
  }

  void _saveReactions() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('reaction_logs', json.encode(_loggedReactions));
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedSymptoms.isNotEmpty) {
      final newEntry = {
        'food': _foodController.text.trim(),
        'severity': _selectedSeverity,
        'symptoms': List<String>.from(_selectedSymptoms),
        'notes': _notesController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      setState(() {
        _loggedReactions.insert(0, newEntry);
        _selectedSymptoms.clear();
        _foodController.clear();
        _notesController.clear();
        _selectedSeverity = 'Mild';
      });

      _saveReactions();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allergic reaction logged')),
      );
    } else if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one symptom')),
      );
    }
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;

    Widget destination;
    switch (index) {
      case 0:
        destination = const HomeScreen();
        break;
      case 1:
        destination = const ReactionLogScreen();
        break;
      case 2:
        destination = const AllergyInsightsScreen();
        break;
      case 3:
        destination = const ProfileScreen();
        break;
      default:
        destination = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  void dispose() {
    _foodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1E33),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Log Reactions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.greenAccent,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E2F45),
        elevation: 4,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Food input
                  TextFormField(
                    controller: _foodController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Food',
                      labelStyle: const TextStyle(color: Colors.blueAccent),
                      filled: true,
                      fillColor: const Color(0xFF2E2F45),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(
                            color: Colors.blueAccent, width: 2),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter the food'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Severity dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedSeverity,
                    dropdownColor: const Color(0xFF2E2F45),
                    decoration: InputDecoration(
                      labelText: 'Severity',
                      labelStyle: const TextStyle(color: Colors.blueAccent),
                      filled: true,
                      fillColor: const Color(0xFF2E2F45),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(
                            color: Colors.blueAccent, width: 2),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    items: _severityOptions.map((level) {
                      return DropdownMenuItem<String>(
                        value: level,
                        child: Text(level),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSeverity = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Symptoms checkbox list
                  const Text(
                    'Symptoms:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueAccent,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._availableSymptoms.map((symptom) {
                    final isChecked = _selectedSymptoms.contains(symptom);
                    return Card(
                      color: const Color(0xFF2E2F45),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: CheckboxListTile(
                        title: Text(
                          symptom,
                          style: const TextStyle(color: Colors.white),
                        ),
                        value: isChecked,
                        activeColor: Colors.blueAccent,
                        checkColor: Colors.white,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedSymptoms.add(symptom);
                            } else {
                              _selectedSymptoms.remove(symptom);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // Notes input
                  TextFormField(
                    controller: _notesController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Additional Notes',
                      labelStyle: const TextStyle(color: Colors.blueAccent),
                      filled: true,
                      fillColor: const Color(0xFF2E2F45),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(
                            color: Colors.blueAccent, width: 2),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 30),

                  // Save button
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    child: const Text('Save Reaction'),
                  ),

                  const SizedBox(height: 40),
                  const Divider(color: Colors.greenAccent),

                  // Logged reactions list
                  const Text(
                    'Logged Reactions:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._loggedReactions.map((entry) {
                    return Card(
                      color: const Color(0xFF2E2F45),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: ListTile(
                        title: Text(
                          entry['food'],
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Severity: ${entry['severity']}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Symptoms: ${entry['symptoms'].join(', ')}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            if (entry['notes'] != null &&
                                entry['notes'].isNotEmpty)
                              Text(
                                'Notes: ${entry['notes']}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            Text(
                              'Logged on: ${DateTime.parse(entry['timestamp']).toLocal().toString().split('.').first}',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Reactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
