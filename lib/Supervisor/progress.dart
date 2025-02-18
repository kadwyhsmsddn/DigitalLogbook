import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ProgressView extends StatefulWidget {
  final String studentUid; // Use studentUid instead of studentName

  const ProgressView({Key? key, required this.studentUid}) : super(key: key);

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  double progress = 0.0; // Progress value to be updated
  int completedMeetings = 0; // Number of completed meetings
  bool isCompleted = false; // To track if all meetings are completed
  bool isLoading = true; // To show loading state

  @override
  void initState() {
    super.initState();
    _loadProgressFromRegistration();
  }

  Future<void> _loadProgressFromRegistration() async {
    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user_progress')
          .doc(widget.studentUid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        List<dynamic> weeks = userData['weeks'] ?? [];
        print('Weeks data: $weeks'); // Debugging line to log weeks data

        if (weeks.isNotEmpty) {
          completedMeetings =
              weeks.where((week) => week['isChecked'] == true).length;
          setState(() {
            progress = completedMeetings / weeks.length; // Calculate progress
            isCompleted = completedMeetings >=
                7; // Mark as completed if 7 or more meetings are done
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student not found in registration.')),
        );
      }
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() {
        isLoading = false; // Hide loading spinner after fetching data
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 185, 205, 234),
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.white,
        backgroundColor: Color.fromARGB(255, 75, 69, 178),
        title: const Text(
          "View Progress",
          style: TextStyle(fontSize: 25, color: Colors.white),
        ),
      ),
      body: Center(
        child: ListView(children: <Widget>[
          const SizedBox(height: 20),
          CircularPercentIndicator(
            radius: 130.0,
            animation: true,
            animationDuration: 1200,
            lineWidth: 15.0,
            percent: 0.7,
            center: const Text(
              "14 weeks",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                  color: Color.fromARGB(255, 70, 27, 110)),
            ),
            circularStrokeCap: CircularStrokeCap.butt,
            backgroundColor: Colors.yellow,
            progressColor: Color.fromARGB(255, 181, 10, 249),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              isCompleted
                  ? "The Student have completed all meetings!"
                  : "The Student have completed $completedMeetings/7 meetings",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
                color: Colors.black,
              ),
              textAlign: TextAlign
                  .center, // Optional: Center-align the text within the Text widget
            ),
          ),
        ]),
      ),
    );
  }
}
