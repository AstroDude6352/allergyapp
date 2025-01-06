import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? selectedSetting;
  int? selectedSettingIndex;
  File? _imageFile; // Variable to store the selected image file
  String userName = "John Doe"; // Example user name
  String userEmail = "john.doe@example.com"; // Example user email

  final List<String> settings = [
    'Theme',
    'Allergy Settings',
    'Dietary Preferences',
    // Add other settings as needed
  ];

  final List<IconData> settingIcons = [
    Icons.color_lens,
    Icons.local_dining,
    Icons.food_bank,
    // Add other icons for settings
  ];

  // Method to handle image selection
  Future<void> _selectImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = File(pickedFile!.path);
    });
  }

  Widget _getSettingInfoWidget(int index) {
    switch (index) {
      case 0:
        return Container(
          padding: const EdgeInsets.all(15),
          margin: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.deepPurple[50],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Appearance',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              Switch(
                value: false, // Replace with actual setting state
                onChanged: (value) {
                  // Add logic for toggling appearance setting
                },
              ),
            ],
          ),
        );
      case 1:
        return Container(
          padding: const EdgeInsets.all(15),
          margin: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.deepPurple[50],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Allergy Settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Enable Allergy Alerts'),
                  Switch(
                    value: true, // Replace with actual setting state
                    onChanged: (bool value) {
                      // Add logic for toggling allergy alert setting
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      case 2:
        return Container(
          padding: const EdgeInsets.all(15),
          margin: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.deepPurple[50],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dietary Preferences',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              // Add widgets for dietary preferences (e.g., vegetarian, vegan, etc.)
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.only(top: 15, bottom: 15),
          margin: const EdgeInsets.all(10.0),
          child: Center(
            child: const Text(
              'Profile',
              style: TextStyle(
                letterSpacing: 0.75,
                fontSize: 26,
                fontFamily: "Poppins",
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        toolbarHeight: 50,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: GestureDetector(
                      onTap: _selectImage,
                      child: CircleAvatar(
                        radius: 65,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : const AssetImage('assets/default_profile.jpg'),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 25, bottom: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: const TextStyle(
                            fontFamily: "Montserrat",
                            fontSize: 24,
                            fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        Text(userEmail, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {

                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple[500],
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Settings',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Montserrat"),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: settings.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedSetting = settings[index];
                          selectedSettingIndex = index;
                        });
                      },
                      child: Container(
                        width: 150,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: selectedSetting == settings[index]
                                ? Colors.deepPurple[500]
                                : Colors.deepPurple[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.transparent, width: 10)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              settingIcons[index],
                              size: 30,
                              color: selectedSetting == settings[index]
                                  ? Colors.white
                                  : Colors.grey[850],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              settings[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: selectedSetting == settings[index]
                                      ? Colors.white
                                      : null),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (selectedSettingIndex != null) ...[
                const SizedBox(height: 20),
                _getSettingInfoWidget(selectedSettingIndex!),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                icon: const Icon(Icons.home),
                color: Colors.deepPurple),
            IconButton(
                onPressed: () {
                  // Navigate to Allergy Screen
                },
                icon: const Icon(Icons.local_dining),
                color: Colors.deepPurple),
            IconButton(
                onPressed: () {
                  // Navigate to Dietary Preferences Screen
                },
                icon: const Icon(Icons.food_bank),
                color: Colors.deepPurple),
            IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
                icon: const Icon(Icons.person),
                color: Colors.deepPurple),
          ],
        ),
      ),
    );
  }
}
