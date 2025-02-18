import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentDetailsPage extends StatelessWidget {
  final Map<String, dynamic> studentData;

  const StudentDetailsPage({Key? key, required this.studentData})
      : super(key: key);

  Future<List<Map<String, dynamic>>> fetchAssignedStudents() async {
    final supervisor = FirebaseAuth.instance.currentUser;

    if (supervisor == null) {
      throw Exception("No supervisor logged in.");
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('registration')
        .where('supervisorUid', isEqualTo: supervisor.uid)
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Accessing individual parameters from studentData
    final studentName = studentData['studentName'] ?? 'N/A';
    final studentEmail = studentData['studentEmail'] ?? 'N/A';
    final studentId = studentData['studentId'] ?? 'N/A';
    final projectTitle = studentData['projectTitle'] ?? 'N/A';
    final phone = studentData['phone'] ?? 'N/A';
    final imageUrl = studentData['imageUrl'];

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
          "Student Details",
          style: TextStyle(color: Colors.white, fontSize: 25),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: ListView(
          children: [
            if (imageUrl != null)
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(imageUrl),
                ),
              ),
            const SizedBox(height: 10), // Add some spacing after the image
            EditItem(
              title: "Name",
              widget: Text(
                studentName,
                style: const TextStyle(
                  color: Color.fromARGB(255, 70, 27, 110),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            EditItem(
              title: "Email",
              widget: Text(
                studentEmail,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 70, 27, 110),
                ),
              ),
            ),
            const SizedBox(height: 10),
            EditItem(
              title: "Student ID",
              widget: Text(
                studentId,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 70, 27, 110),
                ),
              ),
            ),
            const SizedBox(height: 10),
            EditItem(
              title: "Project Title",
              widget: Text(
                projectTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 70, 27, 110),
                ),
              ),
            ),
            const SizedBox(height: 10),
            EditItem(
              title: "Phone",
              widget: Text(
                phone,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 70, 27, 110),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        Container(
          width: double.infinity, // Make the container take full width
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white, // Solid white background
            borderRadius: BorderRadius.circular(8), // Rounded corners
            border: Border.all(
              color: Colors.white, // White border
              width: 1, // Border width
            ),
          ),
          child: widget,
        ),
      ],
    );
  }
}
