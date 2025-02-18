import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/Coordinator/view_student_report.dart';
import 'package:flutter_application_1/Supervisor/details_students.dart';
import 'package:flutter_application_1/Supervisor/progress.dart';

class ViewStudent extends StatelessWidget {
  final String studentName;
  final String Function(Timestamp?) formatTimestamp;

  const ViewStudent({
    super.key,
    required this.studentName,
    required this.formatTimestamp,
    required List<Map<String, dynamic>> weeks,
  });

  Future<String> _getStudentUid() async {
    try {
      QuerySnapshot registrationSnapshot = await FirebaseFirestore.instance
          .collection('registration')
          .where('studentName', isEqualTo: studentName)
          .get();

      if (registrationSnapshot.docs.isEmpty) {
        throw Exception('Student not found');
      }

      return registrationSnapshot.docs.first.id;
    } catch (e) {
      throw Exception('Error fetching student UID: $e');
    }
  }

  Widget _buildWeekItem(
    BuildContext context,
    String note,
    String timestamp,
    Map<String, dynamic>? weekData,
    DocumentReference weekReference,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Timestamp: $timestamp',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 185, 205, 234),
      appBar: AppBar(
        title: Text('$studentName\'s Report'),
        backgroundColor: Color.fromARGB(255, 75, 69, 178),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<String>(
        future: _getStudentUid(),
        builder: (context, studentUidSnapshot) {
          if (studentUidSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (studentUidSnapshot.hasError) {
            return Center(child: Text('Error: ${studentUidSnapshot.error}'));
          }

          String studentUid = studentUidSnapshot.data!;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('weeks')
                .orderBy('timestamp', descending: false)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("No weeks available for this student."),
                );
              }

              final weeks = snapshot.data!.docs;

              return ListView.builder(
                itemCount: weeks.length,
                itemBuilder: (context, index) {
                  var weekData = weeks[index].data() as Map<String, dynamic>?;
                  final note = weekData?['weekNote'] ?? 'No note';
                  final timestamp = formatTimestamp(weekData?['timestamp']);

                  return GestureDetector(
                    onTap: () async {
                      try {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewStudentReport(
                              weekNumber: index + 1,
                              weekData: weekData ?? {},
                              studentName: studentName,
                              studentUid: studentUid,
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    child: _buildWeekItem(
                      context,
                      note,
                      timestamp,
                      weekData,
                      weeks[index].reference,
                      index,
                    ),
                  );
                },
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
                _getStudentUid().then((studentUid) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProgressView(
                        studentUid: studentUid,
                      ),
                    ),
                  );
                }).catchError((e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                });
              },
              icon: const Icon(Icons.ad_units, color: Colors.amber),
            ),
            IconButton(
              onPressed: () {
                _getStudentUid().then((studentUid) async {
                  try {
                    // Fetch the student data from Firestore
                    final studentDoc = await FirebaseFirestore.instance
                        .collection('registration')
                        .doc(studentUid)
                        .get();

                    if (studentDoc.exists) {
                      // Extract student data from Firestore document
                      final studentData = studentDoc.data()!;

                      // Navigate to StudentDetailsPage with fetched student data
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => StudentDetailsPage(
                            studentData: {
                              'studentName':
                                  studentData['studentName'] ?? 'N/A',
                              'studentUid': studentUid,
                              'studentEmail':
                                  studentData['studentEmail'] ?? 'N/A',
                              'studentId': studentData['studentId'] ?? 'N/A',
                              'projectTitle': studentData['projectTitle'] ??
                                  'N/A', // Project title
                              'phone': studentData['phone'] ?? 'N/A',
                              'imageUrl': studentData[
                                  'imageUrl'], // Null if not present
                            },
                          ),
                        ),
                      );
                    } else {
                      throw Exception('Student data not found.');
                    }
                  } catch (e) {
                    // Handle any errors that occur while fetching data
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }).catchError((e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                });
              },
              icon: const Icon(Icons.settings, color: Colors.amber),
            ),
          ],
        ),
      ),
    );
  }
}
