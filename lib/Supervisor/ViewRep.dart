import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/Supervisor/details_students.dart';
import 'package:flutter_application_1/Supervisor/progress.dart';
import 'details_report.dart';

class StudentWeeksView extends StatefulWidget {
  final String studentName;

  const StudentWeeksView({
    super.key,
    required this.studentName,
  });

  @override
  _StudentWeeksViewState createState() => _StudentWeeksViewState();
}

class _StudentWeeksViewState extends State<StudentWeeksView> {
  List<Map<String, dynamic>> weeks = [];
  bool isLoading = true;
  String? studentUid;

  @override
  void initState() {
    super.initState();
    _fetchStudentUidAndWeeks();
  }

  // Fetch the student's UID and their weeks from Firestore
  Future<void> _fetchStudentUidAndWeeks() async {
    try {
      // Fetch the student's UID from the registration collection
      QuerySnapshot registrationSnapshot = await FirebaseFirestore.instance
          .collection('registration')
          .where('studentName', isEqualTo: widget.studentName)
          .get();

      if (registrationSnapshot.docs.isEmpty) {
        throw Exception('Student not found');
      }

      studentUid = registrationSnapshot.docs.first.id;

      // Fetch the student's weeks from the weeks collection
      QuerySnapshot weeksSnapshot = await FirebaseFirestore.instance
          .collection('weeks')
          .where('studentUid', isEqualTo: studentUid)
          .get();

      List<Map<String, dynamic>> fetchedWeeks = [];
      for (var doc in weeksSnapshot.docs) {
        fetchedWeeks.add(doc.data() as Map<String, dynamic>);
      }

      setState(() {
        weeks = fetchedWeeks;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Check if a comment exists for a specific week
  Future<bool> _hasComment(String weekKey) async {
    try {
      final DocumentSnapshot commentSnapshot = await FirebaseFirestore.instance
          .collection('comment')
          .doc(studentUid)
          .get();

      if (commentSnapshot.exists) {
        final Map<String, dynamic>? commentData =
            commentSnapshot.data() as Map<String, dynamic>?;
        return commentData?['weeks']?[weekKey] != null;
      }
      return false;
    } catch (e) {
      throw Exception('Error checking comment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 185, 205, 234),
      appBar: AppBar(
        title: Text('${widget.studentName}\'s Report'),
        backgroundColor: Color.fromARGB(255, 75, 69, 178),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : weeks.isEmpty
              ? const Center(
                  child: Text("No weeks available for this student."),
                )
              : ListView.builder(
                  itemCount: weeks.length,
                  itemBuilder: (context, index) {
                    var week = weeks[index];
                    var weekNote = week['weekNote'] ?? 'No note';
                    final String weekKey = 'week_${index + 1}';

                    return FutureBuilder<bool>(
                      future: _hasComment(weekKey),
                      builder: (context, commentSnapshot) {
                        if (commentSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (commentSnapshot.hasError) {
                          return Center(
                              child: Text('Error: ${commentSnapshot.error}'));
                        }

                        final bool hasComment = commentSnapshot.data ?? false;

                        return GestureDetector(
                          onTap: () async {
                            try {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ListReport(
                                    weekNumber: index + 1,
                                    weekData: week,
                                    studentName: widget.studentName,
                                    studentUid: studentUid!,
                                    studentId: '',
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: hasComment ? Colors.green : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Week ${index + 1}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: hasComment
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    weekNote,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: hasComment
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      bottomNavigationBar: BottomAppBar(
        color: Color.fromARGB(255, 75, 69, 178),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {
                if (studentUid != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProgressView(
                        studentUid: studentUid!,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Student UID not found.')),
                  );
                }
              },
              icon: const Icon(Icons.ad_units, color: Colors.amber),
            ),
            IconButton(
              onPressed: () {
                if (studentUid != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => StudentDetailsPage(
                        studentData: {
                          'studentName': widget.studentName,
                          'studentUid': studentUid!,
                          'studentEmail':
                              'N/A', // Fetch from Firestore if needed
                          'studentId': 'N/A', // Fetch from Firestore if needed
                          'projectTitle':
                              'N/A', // Fetch from Firestore if needed
                          'phone': 'N/A', // Fetch from Firestore if needed
                          'imageUrl': null, // Fetch from Firestore if needed
                        },
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Student UID not found.')),
                  );
                }
              },
              icon: const Icon(Icons.settings, color: Colors.amber),
            ),
          ],
        ),
      ),
    );
  }
}
