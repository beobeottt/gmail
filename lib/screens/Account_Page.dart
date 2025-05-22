import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khoates/screens/Setting_Page.dart';
import 'package:khoates/widgets/Update_Profile.dart';
import 'Home_Page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  File? _profileImage;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage:
                      _profileImage != null
                          ? FileImage(_profileImage!)
                          : const NetworkImage(
                                "https://randomuser.me/api/portraits/men/1.jpg",
                              )
                              as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.camera_alt, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
          _buildProfileInfo(title: "Full Name", value: "John Doe"),
          _buildProfileInfo(title: "Email", value: "johndoe@example.com"),
          _buildProfileInfo(title: "Phone", value: "+1 123 456 789"),
          _buildProfileInfo(title: "Birthday", value: "1995-05-20"),

          const SizedBox(height: 210),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Setting page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Update Profile"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // change page to change password
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UpdateProfile()),
              );
            },
          ),
          // Log Out button, this will ask you want to out this screen
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomePage(),
                              ),
                              (route) => false,
                            );
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text("$title:", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
