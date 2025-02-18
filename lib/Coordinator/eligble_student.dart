import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EligibleStudent extends StatelessWidget {
  final String courseName;

  const EligibleStudent({super.key, required this.courseName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 185, 205, 234),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 75, 69, 178),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Eligible Students for $courseName',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("registration")
                      .where('course', isEqualTo: courseName)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text('No eligible students found.'));
                    }

                    final students = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final studentData =
                            students[index].data() as Map<String, dynamic>;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(studentData['studentName']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Align text to the start
                              children: [
                                Text('Student ID: ${studentData['studentId']}'),
                                Text(
                                    'Project Title: ${studentData['projectTitle']}'),
                              ],
                            ),
                            // Disable onTap by removing it or leaving it null
                            onTap: null,
                          ),
                        );
                      },
                    );
                  }),
            )
          ],
        ),
      ),
    );
  }
}
