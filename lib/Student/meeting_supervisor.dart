import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Student/account.dart';
import 'package:flutter_application_1/Student/login.dart';
import 'package:flutter_application_1/Student/news.dart';
import 'package:flutter_application_1/Student/Student_page.dart';
import 'package:percent_indicator/percent_indicator.dart';

class MeetingSupervisor extends StatefulWidget {
  const MeetingSupervisor({super.key});

  @override
  _MeetingSupervisorState createState() => _MeetingSupervisorState();
}

class _MeetingSupervisorState extends State<MeetingSupervisor> {
  double progress = 0.0; // Progress value to update indicator
  int completedMeetings = 0; // To track the number of successful meetings
  bool isCompleted = false; // To track if the target is met
  bool isLoading = true; // To show loading state

  @override
  void initState() {
    super.initState();
    _loadProgressFromUserProgress(); // Fetch data from user_progress
  }

  // Fetch progress data from user_progress collection
  Future<void> _loadProgressFromUserProgress() async {
    setState(() {
      isLoading = true; // Show loading indicator
    });

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      String userId = currentUser.uid;

      try {
        // Fetch the user document from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('user_progress') // Fetch from user_progress
            .doc(userId)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          // Retrieve weeks list and count completed meetings
          List<dynamic> weeks = userData['weeks'] ?? [];
          if (weeks.isNotEmpty) {
            completedMeetings =
                weeks.where((week) => week['isChecked'] == true).length;
            setState(() {
              progress = completedMeetings / 14; // Update progress
              isCompleted = completedMeetings >=
                  7; // Mark as completed if 7 or more meetings are done
              isLoading = false; // Hide loading indicator
            });
          }
        }
      } catch (e) {
        print("Error fetching data: $e");
        setState(() {
          isLoading = false; // Hide loading indicator in case of error
        });
      }
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
        automaticallyImplyLeading: false,
        title: const AutoSizeText(
          "Progress",
          style: TextStyle(color: Colors.white, fontSize: 25),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Help'),
                content: const Text(
                  'This is your total number of weeks and the number of times you have met with your supervisor',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(
          Icons.question_mark,
          color: Color.fromARGB(255, 70, 27, 110),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Color.fromARGB(255, 75, 69, 178),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const NoteScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.home, color: Colors.amber),
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => const EditAccountScreen()),
                );
              },
              icon: const Icon(Icons.settings, color: Colors.amber),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ListView(
                children: <Widget>[
                  const SizedBox(height: 20),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                      const Text(
                        "Total 14 weeks",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17.0,
                            color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                      CircularPercentIndicator(
                        radius: 120.0,
                        lineWidth: 13.0,
                        animation: true,
                        percent: progress, // Use the dynamic progress variable
                        center: Text(
                          "${(progress * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20.0,
                              color: Color.fromARGB(255, 70, 27, 110)),
                        ),
                        footer: const Text(
                          "Total you meet your supervisor so far",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17.0,
                              color: Colors.black),
                        ),
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: Color.fromARGB(255, 229, 143, 205),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          children: [
                            CircularPercentIndicator(
                              radius: 60.0,
                              lineWidth: 5.0,
                              percent: 1.0,
                              center: Text(
                                isCompleted
                                    ? "Completed"
                                    : "$completedMeetings/7",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.0,
                                    color: Color.fromARGB(255, 72, 97, 72)),
                              ),
                              progressColor: isCompleted
                                  ? const Color.fromARGB(255, 72, 97, 72)
                                  : Colors.red,
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              isCompleted
                                  ? "Great job! You have completed all meetings."
                                  : "Total Meeting",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17.0,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
