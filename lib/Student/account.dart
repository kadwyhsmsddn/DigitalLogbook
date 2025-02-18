import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final TextEditingController projectTitleController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? imageUrl; // To store the uploaded image URL
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print("Fetching user data...");
      final querySnapshot = await FirebaseFirestore.instance
          .collection('registration')
          .where('uid', isEqualTo: user.uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print("Data fetched successfully.");
        final doc = querySnapshot.docs.first;
        setState(() {
          nameController.text = doc['studentName'] ?? '';
          emailController.text = doc['studentEmail'] ?? '';
          studentIdController.text = doc['studentId'] ?? '';
          projectTitleController.text = doc['projectTitle'] ?? '';
          phoneController.text = doc['phone'] ?? '';
          imageUrl = doc['imageUrl']; // Load profile image URL if available
        });
      } else {
        print("No data found.");
      }
    }
  }

  Future<void> updatePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newPassword = passwordController.text;
    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password cannot be empty.")),
      );
      return;
    }

    try {
      await user.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully!")),
      );
      passwordController.clear(); // Clear the password field
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update password: $e")),
      );
    }
  }

  Future<void> uploadImage() async {
    if (_imageFile == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${user.uid}.jpg');

      await storageRef.putFile(_imageFile!);

      // Get the download URL
      final newImageUrl = await storageRef.getDownloadURL();

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('registration')
          .doc(user.uid)
          .update({'imageUrl': newImageUrl});

      setState(() {
        imageUrl = newImageUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image uploaded successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: $e")),
      );
    }
  }

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await uploadImage();
    }
  }

  Future<void> saveUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('registration')
          .doc(user.uid)
          .update({
        'studentName': nameController.text,
        'studentEmail': emailController.text,
        'studentId': studentIdController.text,
        'projectTitle': projectTitleController.text,
        'phone': phoneController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromARGB(255, 185, 205, 234),
        appBar: AppBar(
            backgroundColor: Color.fromARGB(255, 75, 69, 178),
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
            title: const Text(
              "Profile",
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  await saveUserData(); // Save user data
                  if (passwordController.text.isNotEmpty) {
                    await updatePassword(); // Update password if provided
                  }
                },
                style: ElevatedButton.styleFrom(
                  elevation: 1,
                  backgroundColor: const Color.fromARGB(255, 242, 144, 17),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Save"),
              ),
              const SizedBox(width: 10),
            ]),
        body: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            EditItem(
                title: "Photo",
                widget: Center(
                  child: Column(
                    children: [
                      imageUrl != null
                          ? CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(imageUrl!),
                            )
                          : const CircleAvatar(
                              radius: 50,
                              backgroundImage:
                                  AssetImage("assets/avatar_placeholder.png"),
                            ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: pickImage,
                        style: TextButton.styleFrom(
                          foregroundColor: Color.fromARGB(255, 70, 27, 110),
                        ),
                        child: const Text("Change Image"),
                      ),
                    ],
                  ),
                )),
            EditItem(
              title: "Name",
              widget: TextField(
                style: const TextStyle(
                  color: Color.fromARGB(255, 70, 27, 110),
                ),
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: "Enter your name",
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            EditItem(
              title: "Email",
              widget: TextField(
                style: const TextStyle(
                  color: Color.fromARGB(255, 70, 27, 110),
                ),
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: "Enter your email",
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            EditItem(
              title: "Student ID",
              widget: TextField(
                style: const TextStyle(
                  color: Color.fromARGB(255, 70, 27, 110),
                ),
                controller: studentIdController,
                decoration: const InputDecoration(
                  hintText: "Enter your student ID",
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            EditItem(
              title: "Project Title",
              widget: TextField(
                style: const TextStyle(
                  color: Color.fromARGB(255, 70, 27, 110),
                ),
                controller: projectTitleController,
                decoration: const InputDecoration(
                  hintText: "Enter project title",
                  hintStyle: TextStyle(color: Color.fromARGB(255, 70, 27, 110)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            EditItem(
              title: "Phone Number",
              widget: TextField(
                style: const TextStyle(
                  color: Color.fromARGB(255, 70, 27, 110),
                ),
                controller: phoneController,
                decoration: const InputDecoration(
                  hintText: "Enter phone number",
                  hintStyle: TextStyle(color: Color.fromARGB(255, 70, 27, 110)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            EditItem(
              title: "Change Password",
              widget: TextField(
                style: const TextStyle(
                  color: Color.fromARGB(255, 70, 27, 110),
                ),
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "Enter new password",
                  hintStyle: TextStyle(color: Color.fromARGB(255, 70, 27, 110)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        )));
  }
}

class EditItem extends StatelessWidget {
  final String title;
  final Widget widget;

  const EditItem({required this.title, required this.widget, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        widget,
      ],
    );
  }
}
