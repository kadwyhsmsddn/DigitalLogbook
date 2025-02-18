import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/Student/login.dart';
import 'package:flutter_application_1/Student/Student_page.dart'; // Example import for Registration screen

class StudentAnnouncements extends StatelessWidget {
  const StudentAnnouncements({super.key, required Map<String, dynamic> data});

  Drawer myDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Color.fromARGB(255, 185, 205, 234),
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const SizedBox(height: 40),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.orange),
            title: const Text(
              'L O G B O O K',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color.fromARGB(255, 70, 27, 110),
              ),
            ),
            onTap: () {
              print("Drawer tapped");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => NoteScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.orange),
            title: const Text(
              'L O G O U T',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color.fromARGB(255, 70, 27, 110),
              ),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const Login()), // Login Page
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 185, 205, 234),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 75, 69, 178),
        title: const Text(
          'Announcements',
          style: TextStyle(color: Colors.white, fontSize: 25),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('news')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No Announcements Available',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final announcements = snapshot.data!.docs;

          return ListView.builder(
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              final announcementData =
                  announcement.data() as Map<String, dynamic>;
              final title = announcementData['title'] ?? 'No Title';
              final content =
                  announcementData['content'] ?? 'No Content Available';
              final timestamp =
                  (announcementData['timestamp'] as Timestamp?)?.toDate();

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(content),
                      if (timestamp != null)
                        Text(
                          'Published on: ${timestamp.toLocal()}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
