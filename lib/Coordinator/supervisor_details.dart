import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/Coordinator/view_student.dart';
import 'package:intl/intl.dart';

class SupervisorDetailsPage extends StatefulWidget {
  final String supervisorId;

  const SupervisorDetailsPage({super.key, required this.supervisorId});

  @override
  _SupervisorDetailsPageState createState() => _SupervisorDetailsPageState();
}

class _SupervisorDetailsPageState extends State<SupervisorDetailsPage> {
  Map<String, List<DocumentSnapshot>> studentsBySemester = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudentsUnderSupervisor();
  }

  Future<void> fetchStudentsUnderSupervisor() async {
    try {
      final studentQuerySnapshot = await FirebaseFirestore.instance
          .collection('registration')
          .where('supervisorUid', isEqualTo: widget.supervisorId.trim())
          .get();

      // Group students by semester
      final Map<String, List<DocumentSnapshot>> groupedStudents = {};
      for (var student in studentQuerySnapshot.docs) {
        final semester = student.get('semester') ?? 'No Semester';
        if (!groupedStudents.containsKey(semester)) {
          groupedStudents[semester] = [];
        }
        groupedStudents[semester]!.add(student);
      }

      setState(() {
        studentsBySemester = groupedStudents;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching students: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 205, 224, 252),
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Color.fromARGB(255, 205, 224, 252),
        backgroundColor: Color.fromARGB(255, 75, 69, 178),
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const AutoSizeText(
          "Semester List",
          style: TextStyle(color: Colors.white, fontSize: 25),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : studentsBySemester.isEmpty
              ? const Center(
                  child: Text(
                    'No students assigned to this supervisor',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8.0), // Reduced padding
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // Increase the number of columns
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 0.8, // Make grid items narrower
                  ),
                  itemCount: studentsBySemester.keys.length,
                  itemBuilder: (context, index) {
                    final semester = studentsBySemester.keys.elementAt(index);
                    final students = studentsBySemester[semester]!;

                    return InkWell(
                      onTap: () {
                        // Navigate to the student list page for this semester
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => StudentListPage(
                              semester: semester,
                              students: students,
                              formatTimestamp: formatTimestamp,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                              8.0), // Smaller border radius
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(4.0), // Reduced padding
                            child: Text(
                              'Semester $semester',
                              style: const TextStyle(
                                fontSize: 14, // Smaller font size
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'No date';
    return DateFormat('yyyy-MM-dd – HH:mm').format(timestamp.toDate());
  }
}

class StudentListPage extends StatelessWidget {
  final String semester;
  final List<DocumentSnapshot> students;
  final String Function(Timestamp?) formatTimestamp;

  const StudentListPage({
    super.key,
    required this.semester,
    required this.students,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 205, 224, 252),
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Color.fromARGB(255, 205, 224, 252),
        backgroundColor: Color.fromARGB(255, 75, 69, 178),
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: AutoSizeText(
          "Students - Semester $semester",
          style: const TextStyle(color: Colors.white, fontSize: 25),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0), // Reduced padding
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          final studentName = student.get('studentName') ?? 'No Name';
          final studentEmail = student.get('studentEmail') ?? 'No Email';
          final projectTitle =
              student.get('projectTitle')?.toString().trim() ?? '';

          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 4.0), // Reduced padding
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(8.0), // Smaller border radius
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                title: Text(
                  studentName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(studentEmail),
                    Text(
                      'Project: ${projectTitle.isEmpty ? 'No Project Title' : projectTitle}',
                    ),
                  ],
                ),
                leading: const Icon(Icons.person, color: Colors.orange),
                onTap: () async {
                  // Fetch the weeks data for the selected student
                  final studentId = student.id;
                  try {
                    final weeksSnapshot = await FirebaseFirestore.instance
                        .collection('registration')
                        .doc(studentId)
                        .get();

                    final studentWeeks = weeksSnapshot.data()?['weeks'] ?? [];

                    // Navigate to StudentWeeksView with fetched weeks data
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ViewStudent(
                          weeks: List<Map<String, dynamic>>.from(studentWeeks),
                          studentName: studentName,
                          formatTimestamp: formatTimestamp,
                        ),
                      ),
                    );
                  } catch (e) {
                    print("Error fetching weeks data: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error fetching weeks data: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
