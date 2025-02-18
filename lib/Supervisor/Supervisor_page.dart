import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/Student/login.dart';
import 'package:flutter_application_1/Supervisor/details_students.dart';
import 'package:flutter_application_1/Supervisor/progress.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class StudentList extends StatefulWidget {
  const StudentList({super.key});

  @override
  _StudentListState createState() => _StudentListState();
}

class _StudentListState extends State<StudentList> {
  String? supervisorId;
  List<DocumentSnapshot> students = [];
  List<DocumentSnapshot> filteredStudents = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSupervisorId();
    searchController
        .addListener(_filterStudents); // Listen to search input changes
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Fetch the logged-in supervisor's UID
  Future<void> fetchSupervisorId() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      setState(() {
        supervisorId = currentUser.uid; // Get supervisor's UID
      });
      await fetchStudents();
    } else {
      print('Current user not found');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Format the timestamp for display
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'No timestamp';
    final DateTime date = timestamp.toDate();
    final DateFormat formatter = DateFormat('dd MMM yyyy');
    return formatter.format(date);
  }

  // Fetch students assigned to the supervisor using supervisorUid
  Future<void> fetchStudents() async {
    if (supervisorId != null) {
      try {
        final studentQuerySnapshot = await FirebaseFirestore.instance
            .collection('registration')
            .where('supervisorUid', isEqualTo: supervisorId)
            .get();

        setState(() {
          students = studentQuerySnapshot.docs;
          filteredStudents = students; // Initialize filtered list
          isLoading = false;
        });
      } catch (e) {
        print('Error fetching students: $e');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      print('Supervisor ID is null');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Filter students based on search input
  void _filterStudents() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredStudents = students
          .where((student) => (student.get('studentName') as String)
              .toLowerCase()
              .contains(query))
          .toList();
    });
  }

  // Logout the user with confirmation dialog
  Future<void> _logout() async {
    // Show a confirmation dialog
    bool confirmLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Return false if the user cancels the logout
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Return true if the user confirms the logout
                Navigator.of(context).pop(true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    // If the user confirms the logout, proceed with the logout process
    if (confirmLogout == true) {
      try {
        await FirebaseAuth.instance.signOut();
        // Navigate to the login screen or any other screen after logout
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
      } catch (e) {
        print('Error logging out: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 205, 224, 252),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          const SizedBox(height: 16.0),
          _buildSearchBar(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : supervisorId == null
                    ? const Center(child: Text('Supervisor not found'))
                    : filteredStudents.isEmpty
                        ? const Center(child: Text('No students found'))
                        : _buildSemesterGrid(),
          ),
        ],
      ),
    );
  }

  // AppBar Widget with Logout Button
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 75, 69, 178),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Student List",
              style: TextStyle(
                fontSize: 25,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: _logout, // Call the _logout method here
        ),
      ],
    );
  }

  // Search Bar Widget
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "Search",
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // Semester Grid Widget
  Widget _buildSemesterGrid() {
    // Group students by semester
    final Map<String, List<DocumentSnapshot>> studentsBySemester = {};
    for (var student in filteredStudents) {
      final semester = student.get('semester') ?? 'Unknown Semester';
      if (!studentsBySemester.containsKey(semester)) {
        studentsBySemester[semester] = [];
      }
      studentsBySemester[semester]!.add(student);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 columns
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.5, // Adjust the aspect ratio
      ),
      itemCount: studentsBySemester.keys.length,
      itemBuilder: (context, index) {
        final semester = studentsBySemester.keys.toList()[index];

        return GestureDetector(
          onTap: () {
            // Navigate to the StudentListPage for the selected semester
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => StudentListPage(
                  semester: semester,
                  students: studentsBySemester[semester]!,
                ),
              ),
            );
          },
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            color:
                const Color.fromARGB(255, 242, 144, 17), // Set the grid color
            child: Center(
              child: Text(
                semester,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}

// StudentListPage
class StudentListPage extends StatefulWidget {
  final String semester;
  final List<DocumentSnapshot> students;

  const StudentListPage({
    Key? key,
    required this.semester,
    required this.students,
  }) : super(key: key);

  @override
  _StudentListPageState createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final TextEditingController searchController = TextEditingController();
  List<DocumentSnapshot> filteredStudents = [];

  @override
  void initState() {
    super.initState();
    // Initialize filteredStudents with all students
    filteredStudents = widget.students;
    // Listen to changes in the search bar
    searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Filter students based on search input
  void _filterStudents() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredStudents = widget.students
          .where((student) => (student.get('studentName') as String)
              .toLowerCase()
              .contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 205, 224, 252),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 75, 69, 178),
        title: Text(
          widget.semester,
          style: const TextStyle(
            fontSize: 25,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search by student name",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // List of Students
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                final name = student.get('studentName') ?? 'No Name Available';
                final projectTitle =
                    student.get('projectTitle') ?? 'No Project Title Available';
                final studentId =
                    student.get('studentId') ?? 'No Student ID Available';
                final studentEmail =
                    student.get('studentEmail') ?? 'No Email Available';
                final phone = student.get('phone') ?? 'No Phone Available';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          projectTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    leading: const Icon(
                      Icons.person,
                      color: Color.fromARGB(255, 233, 153, 67),
                    ),
                    onTap: () {
                      final studentUid = student.id; // Firestore document ID
                      final studentId = student.get('studentId') ??
                          'No Student ID Available'; // Profile ID
                      final studentName =
                          student.get('studentName') ?? 'No Name Available';
                      final studentEmail =
                          student.get('studentEmail') ?? 'No Email Available';
                      final projectTitle = student.get('projectTitle') ??
                          'No Project Title Available';
                      final phone =
                          student.get('phone') ?? 'No Phone Available';

                      // Navigate to the StudentWeeksView
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => StudentWeeksView(
                            studentUid:
                                studentUid, // Pass Firestore document ID
                            studentId: studentId, // Pass profile ID
                            studentName: studentName,
                            studentEmail: studentEmail,
                            projectTitle: projectTitle,
                            phone: phone,
                            weeks: [],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// StudentWeeksView
class StudentWeeksView extends StatefulWidget {
  final String studentUid; // Firestore document ID
  final String studentId; // Profile ID
  final String studentName;
  final String studentEmail;
  final String projectTitle;
  final String phone;
  final List weeks;

  const StudentWeeksView({
    Key? key,
    required this.studentUid,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.projectTitle,
    required this.phone,
    required this.weeks,
  }) : super(key: key);

  @override
  _StudentWeeksViewState createState() => _StudentWeeksViewState();
}

class _StudentWeeksViewState extends State<StudentWeeksView> {
  List<Map<String, dynamic>> weeks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeeks();
  }

  // Fetch all weeks from the weeks collection
  Future<void> _fetchWeeks() async {
    try {
      QuerySnapshot weeksSnapshot = await FirebaseFirestore.instance
          .collection('weeks')
          .orderBy('timestamp', descending: false)
          .get();

      List<Map<String, dynamic>> fetchedWeeks = [];
      for (var doc in weeksSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        fetchedWeeks.add(data);
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
        SnackBar(content: Text('Error fetching weeks: $e')),
      );
    }
  }

  // Helper function to check if a week has a description
  bool _hasDescription(Map<String, dynamic> weekData) {
    return weekData['description'] != null &&
        weekData['description'].toString().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 185, 205, 234),
      appBar: AppBar(
        title: Text('${widget.studentName} (ID: ${widget.studentId})'),
        backgroundColor: const Color.fromARGB(255, 75, 69, 178),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : weeks.isEmpty
              ? const Center(child: Text("No weeks available."))
              : ListView.builder(
                  itemCount: weeks.length,
                  itemBuilder: (context, index) {
                    var week = weeks[index];

                    var timestamp = formatTimestamp(week['timestamp']);

                    return GestureDetector(
                      onTap: () {
                        // Navigate to ListReport with week data
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ListReport(
                              weekNumber: index + 1,
                              weekData: week,
                              studentName: widget.studentName,
                              studentUid: widget.studentUid,
                              studentId: widget.studentId,
                              studentEmail: widget.studentEmail,
                              projectTitle: widget.projectTitle,
                              phone: widget.phone,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FutureBuilder<String>(
                          future: _loadDescriptionForWeek(
                              index + 1), // Load description for the week
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Container(
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
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      timestamp,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Container(
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
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      timestamp,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final String description =
                                snapshot.data ?? 'No description available';
                            final bool hasDescription =
                                description != 'No description available';

                            return Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: hasDescription
                                    ? Colors.green[100]
                                    : Colors.white,
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
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    timestamp,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: BottomAppBar(
        color: const Color.fromARGB(255, 75, 69, 178),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {
                if (widget.studentUid.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProgressView(
                        studentUid: widget.studentUid,
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
                if (widget.studentUid.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => StudentDetailsPage(
                        studentData: {
                          'studentName': widget.studentName,
                          'studentEmail': widget.studentEmail,
                          'studentId': widget.studentId,
                          'projectTitle': widget.projectTitle,
                          'phone': widget.phone,
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

  // Helper function to load description for a specific week
  Future<String> _loadDescriptionForWeek(int weekNumber) async {
    try {
      // Fetch the student's progress document from the user_progress collection
      DocumentSnapshot userProgressSnapshot = await FirebaseFirestore.instance
          .collection('user_progress')
          .doc(widget.studentUid) // Use studentUid (Firestore document ID)
          .get();

      if (userProgressSnapshot.exists) {
        final userProgressData =
            userProgressSnapshot.data() as Map<String, dynamic>?;
        final List<dynamic> weeks = userProgressData?['weeks'] ?? [];

        if (weeks.isNotEmpty && weekNumber <= weeks.length) {
          final weekData = weeks[weekNumber - 1];
          return weekData['description'] ?? 'No description available';
        }
      }
      return 'No description available';
    } catch (e) {
      return 'Error loading description: $e';
    }
  }

  // Helper function to format timestamp
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'No timestamp';
    final DateTime date = timestamp.toDate();
    final DateFormat formatter = DateFormat('dd MMM yyyy');
    return formatter.format(date);
  }
}

// ListReport
class ListReport extends StatefulWidget {
  final int weekNumber;
  final Map<String, dynamic> weekData;
  final String studentName;
  final String studentUid; // Firestore document ID
  final String studentId; // Profile ID
  final String studentEmail;
  final String projectTitle;
  final String phone;

  const ListReport({
    super.key,
    required this.weekNumber,
    required this.weekData,
    required this.studentName,
    required this.studentUid,
    required this.studentId,
    required this.studentEmail,
    required this.projectTitle,
    required this.phone,
  });

  @override
  _ListReportState createState() => _ListReportState();
}

class _ListReportState extends State<ListReport> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? description; // Store the fetched description

  Future<void> _loadDescription() async {
    try {
      // Fetch the student's progress document from the user_progress collection
      DocumentSnapshot userProgressSnapshot = await _firestore
          .collection('user_progress')
          .doc(widget.studentUid) // Use studentUid (Firestore document ID)
          .get();

      if (userProgressSnapshot.exists) {
        final userProgressData =
            userProgressSnapshot.data() as Map<String, dynamic>?;
        final List<dynamic> weeks = userProgressData?['weeks'] ?? [];

        if (weeks.isNotEmpty && widget.weekNumber <= weeks.length) {
          final weekData = weeks[widget.weekNumber - 1];
          setState(() {
            description = weekData['description'] ?? 'No description available';
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No progress data found for this student.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading description: $e')),
      );
    }
  }

  Future<void> _loadComment() async {
    try {
      DocumentSnapshot commentSnapshot =
          await _firestore.collection('comment').doc(widget.studentUid).get();

      Map<String, dynamic>? commentData =
          commentSnapshot.data() as Map<String, dynamic>?;

      if (commentData != null &&
          commentData['weeks'] != null &&
          commentData['weeks']['week_${widget.weekNumber}'] != null) {
        _commentController.text =
            commentData['weeks']['week_${widget.weekNumber}'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading comment: $e')),
      );
    }
  }

  Future<void> saveComment() async {
    if (widget.studentName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No student name available.')),
      );
      return;
    }

    try {
      await _firestore.collection('comment').doc(widget.studentUid).set({
        'weeks': {
          'week_${widget.weekNumber}': _commentController.text,
        },
      }, SetOptions(merge: true)); // Merge to preserve other data

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment saved successfully!')),
      );
      _loadComment();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving comment: $e')),
      );
    }
  }

  // Function to download an image
  Future<void> _downloadImage(String url, String fileName) async {
    // Request storage permission
    var status = await Permission.storage.request();
    if (status.isGranted) {
      // Define the download path
      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: '/storage/emulated/0/Download', // Save to Downloads folder
        fileName: fileName,
        showNotification: true, // Show download notification
        openFileFromNotification: true, // Open file after download
      );

      if (taskId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started!')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied!')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDescription(); // Fetch description from user_progress
    _loadComment();
  }

  @override
  Widget build(BuildContext context) {
    // Extract image URLs from weekData
    List<String> imageUrls =
        List<String>.from(widget.weekData['imageUrls'] ?? []);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 185, 205, 234),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 75, 69, 178),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          'Week ${widget.weekNumber} Report',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: saveComment,
            style: ElevatedButton.styleFrom(
              elevation: 1,
              backgroundColor: const Color.fromARGB(255, 233, 153, 67),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Save"),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Container for Week Description
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Week Description:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(
                      text: description ?? 'No description available',
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'No description available',
                    ),
                    maxLines: null,
                    readOnly: true, // Makes the field read-only
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16), // Add spacing between sections

            // Conditionally render the Uploaded Images section only if there are images
            if (imageUrls.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Uploaded Images:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(), // Disable scrolling
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Two images per row
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Image.network(
                              imageUrls[index],
                              fit: BoxFit.cover,
                              loadingBuilder: (BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (BuildContext context,
                                  Object exception, StackTrace? stackTrace) {
                                return const Center(
                                  child: Icon(Icons.error, color: Colors.red),
                                );
                              },
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.download,
                                    color: Colors.white),
                                onPressed: () {
                                  // Generate a unique file name
                                  String fileName =
                                      'week_${widget.weekNumber}_image_$index.jpg';
                                  _downloadImage(imageUrls[index], fileName);
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16), // Add spacing between sections

            // Container for Adding a Comment
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add a Comment:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Type your comment here...',
                    ),
                    maxLines: null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
