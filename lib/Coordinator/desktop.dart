import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Coordinator/information.dart';
import 'package:flutter_application_1/Coordinator/registration.dart';
import 'package:flutter_application_1/Coordinator/supervisor_details.dart';
import 'package:flutter_application_1/Student/login.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_application_1/Coordinator/eligble_student.dart';

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
            'D E S K T O P',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color.fromARGB(255, 70, 27, 110),
            ),
          ),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DesktopScaffold()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.app_registration, color: Colors.orange),
          title: const Text(
            'R E G I S T R A T I O N',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color.fromARGB(255, 70, 27, 110),
            ),
          ),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const FYPRegistration()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.info, color: Colors.orange),
          title: const Text(
            'I N F O R M A T I O N',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color.fromARGB(255, 70, 27, 110),
            ),
          ),
          onTap: () {
            if (ModalRoute.of(context)?.settings.name != '/information') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AnnouncementsScreen()),
              );
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.orange),
          title: const Text(
            'L O G O U T',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color.fromARGB(255, 70, 27, 110),
            ),
          ),
          onTap: () async {
            // Show confirmation dialog
            bool confirmLogout = await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("Confirm Logout"),
                  content: const Text("Are you sure you want to logout?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text("Logout"),
                    ),
                  ],
                );
              },
            );

            // If user confirms, logout
            if (confirmLogout == true) {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Login()),
              );
            }
          },
        ),
      ],
    ),
  );
}

class DesktopScaffold extends StatefulWidget {
  const DesktopScaffold({super.key});

  @override
  State<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends State<DesktopScaffold> {
  final User? user = FirebaseAuth.instance.currentUser;
  final CollectionReference weeksRef =
      FirebaseFirestore.instance.collection("weeks");
  final CollectionReference datesRef =
      FirebaseFirestore.instance.collection("dates");

  Timer? _dateChecker;
  List<DateTime> _markedDates = [];
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final List<String> boxNames = [
    'Weeks',
    'Programme',
    'Supervisors',
    'Students'
  ];

  int selectedIndex = 0;

  final Color defaultBackgroundColor = Colors.grey[300]!;
  final List<String> courseNames = [
    'Bachelor of Computer Engineering Technology (Computer Systems) with Honours',
    'Bachelor of Computer Engineering Technology (Networking Systems) with Honours',
    'Bachelor of Information Technology (Hons.) in Software Engineering',
    'Bachelor of Information Technology (Hons.) in Computer System Security',
  ];

  @override
  void initState() {
    super.initState();
    _loadMarkedDates();
    _startDateChecker();
  }

  @override
  void dispose() {
    _dateChecker?.cancel();
    super.dispose();
  }

  Future<void> _loadMarkedDates() async {
    try {
      final snapshot = await datesRef.get();
      setState(() {
        _markedDates = snapshot.docs.map((doc) {
          final dateField = (doc.data() as Map<String, dynamic>)['date'];
          return (dateField as Timestamp).toDate();
        }).toList();
        _markedDates.sort(); // Ensure dates are in order
      });
    } catch (e) {
      _showSnackBar('Error loading dates: $e');
    }
  }

  void _startDateChecker() {
    _dateChecker = Timer.periodic(const Duration(minutes: 1), (timer) async {
      final now = DateTime.now();

      for (int i = 0; i < _markedDates.length; i++) {
        final date = _markedDates[i];
        final weekIndex = i + 1;

        // Adjust this check to match the exact weekly occurrence
        if (date.isBefore(now) || isSameDay(date, now)) {
          await markWeeklyDates(date, weekIndex);
        }
      }
    });
  }

  Future<void> markWeeklyDates(DateTime date, int weekIndex) async {
    try {
      final weekName = "Week $weekIndex";

      // Check if the week already exists in Firestore
      final snapshot =
          await weeksRef.where('weekNote', isEqualTo: weekName).get();
      if (snapshot.docs.isNotEmpty) return; // Skip if already published

      // Add the week to Firestore
      await weeksRef.add({
        'weekNote': weekName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _showSnackBar('$weekName successfully added!');
    } catch (e) {
      _showSnackBar("Error publishing week: $e");
    }
  }

// Handle the date marking for weekly recurrence
  Future<void> _onEventDateChanged(DateTime day, bool isAdded) async {
    try {
      if (isAdded) {
        // Add the selected day and generate weekly recurrence
        final markedDates = <DateTime>[];
        DateTime currentDate = day;

        // Mark the selected date and the next 12 weeks (you can adjust this)
        for (int i = 0; i < 14; i++) {
          markedDates.add(currentDate);
          currentDate = currentDate
              .add(Duration(days: 7)); // Add 7 days for the next week
        }

        // Add the dates to Firestore
        for (DateTime markedDate in markedDates) {
          await datesRef.add({'date': markedDate});
        }
      } else {
        // Remove the date if it's unmarked
        await datesRef.where('date', isEqualTo: day).get().then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.delete();
          }
        });
      }

      await _loadMarkedDates(); // Reload marked dates without changing the current view
    } catch (e) {
      _showSnackBar("Error updating event dates: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromARGB(255, 185, 205, 234),
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 75, 69, 178),
          title: const Text(
            "D E S K T O P",
            style: TextStyle(color: Colors.white, fontSize: 25),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        drawer: myDrawer(context),
        body: Row(children: [
          // Left Pane
          Expanded(
              flex: 2,
              child: Column(children: [
                // Toggle Box
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(boxNames.length, (index) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedIndex = index),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selectedIndex == index
                                ? const Color.fromARGB(255, 70, 27, 110)
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              boxNames[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                selectedIndex == 0
                    ? Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: weeksRef.orderBy('timestamp').snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            final weeks = snapshot.data!.docs;
                            return ListView.builder(
                              itemCount: weeks.length,
                              itemBuilder: (context, index) {
                                final data =
                                    weeks[index].data() as Map<String, dynamic>;
                                return Container(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 5,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      title: Text(data['weekNote']),
                                      subtitle: Text(
                                        data['timestamp'] != null
                                            ? (data['timestamp'] as Timestamp)
                                                .toDate()
                                                .toString()
                                            : 'No date available',
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () async {
                                          // Show confirmation dialog
                                          bool confirmDelete = await showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: const Text(
                                                    "Confirm Delete"),
                                                content: const Text(
                                                    "Are you sure you want to delete this week?"),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(false),
                                                    child: const Text("Cancel"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(true),
                                                    child: const Text("Delete"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          // If user confirms, delete the week
                                          if (confirmDelete == true) {
                                            try {
                                              await weeksRef
                                                  .doc(weeks[index].id)
                                                  .delete();
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content:
                                                        Text('Week deleted')),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        'Error deleting week: $e')),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ));
                              },
                            );
                          },
                        ),
                      )
                    : selectedIndex == 1
                        ? Expanded(
                            child: ListView.builder(
                              itemCount: courseNames.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 5,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      courseNames[index],
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : selectedIndex == 2
                            ? Expanded(
                                child: StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection(
                                            'supervisors') // This is the supervisors collection
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      }
                                      final supervisors = snapshot.data!.docs;

                                      if (supervisors.isEmpty) {
                                        return const Center(
                                          child: Text(
                                            "No Supervisors Registered",
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white),
                                          ),
                                        );
                                      }

                                      // Sort the supervisors alphabetically by name
                                      supervisors.sort((a, b) {
                                        final nameA = (a.data() as Map<String,
                                                dynamic>)['supervisorName'] ??
                                            '';
                                        final nameB = (b.data() as Map<String,
                                                dynamic>)['supervisorName'] ??
                                            '';
                                        return nameA
                                            .toLowerCase()
                                            .compareTo(nameB.toLowerCase());
                                      });

                                      return ListView.builder(
                                          itemCount: supervisors.length,
                                          itemBuilder: (context, index) {
                                            final supervisor =
                                                supervisors[index].data()
                                                    as Map<String, dynamic>;
                                            final name =
                                                supervisor['supervisorName'] ??
                                                    'Unknown Name';
                                            final email =
                                                supervisor['supervisorEmail'] ??
                                                    'Unknown Email';

                                            return GestureDetector(
                                              onTap: () {
                                                final supervisorId = supervisors[
                                                        index]
                                                    .id; // This ID should be non-null and correct
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        SupervisorDetailsPage(
                                                      supervisorId:
                                                          supervisorId, // Pass the correct supervisor ID
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                        horizontal: 16),
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Colors.black12,
                                                      blurRadius: 5,
                                                      offset: Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            name,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 8),
                                                          Text(
                                                            email,
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        14),
                                                          ),
                                                        ],
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.delete,
                                                            color: Colors.red),
                                                        onPressed: () async {
                                                          // Show confirmation dialog
                                                          bool confirmDelete =
                                                              await showDialog(
                                                            context: context,
                                                            builder: (context) {
                                                              return AlertDialog(
                                                                title: const Text(
                                                                    "Confirm Delete"),
                                                                content: const Text(
                                                                    "Are you sure you want to delete this supervisor?"),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.of(context)
                                                                            .pop(false),
                                                                    child: const Text(
                                                                        "Cancel"),
                                                                  ),
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.of(context)
                                                                            .pop(true),
                                                                    child: const Text(
                                                                        "Delete"),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );

                                                          // If user confirms, delete the supervisor
                                                          if (confirmDelete ==
                                                              true) {
                                                            FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                    'supervisors')
                                                                .doc(supervisors[
                                                                        index]
                                                                    .id)
                                                                .delete();
                                                          }
                                                        },
                                                      ),
                                                    ]),
                                              ),
                                            );
                                          });
                                    }))
                            : selectedIndex == 3
                                ? Expanded(
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('registration')
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }

                                        final students = snapshot.data!.docs;

                                        if (students.isEmpty) {
                                          return const Center(
                                            child: Text(
                                              "No Students Registered",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.black),
                                            ),
                                          );
                                        }

                                        // Group students by semester
                                        Map<String, List<Map<String, dynamic>>>
                                            studentsBySemester = {};
                                        for (var student in students) {
                                          final studentData = student.data()
                                              as Map<String, dynamic>;
                                          final semester =
                                              studentData['semester'] ??
                                                  'Unknown Semester';

                                          if (!studentsBySemester
                                              .containsKey(semester)) {
                                            studentsBySemester[semester] = [];
                                          }
                                          studentsBySemester[semester]!
                                              .add(studentData);
                                        }

                                        // Use the order in which semesters were added to the map
                                        final semesters =
                                            studentsBySemester.keys.toList();

                                        return ListView.builder(
                                          itemCount: semesters.length,
                                          itemBuilder: (context, index) {
                                            final semester = semesters[index];
                                            final studentsInSemester =
                                                studentsBySemester[semester]!;

                                            return Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 16),
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: Colors.black12,
                                                    blurRadius: 5,
                                                    offset: Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: ExpansionTile(
                                                title: Text(
                                                  semester,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                children: studentsInSemester
                                                    .map((student) {
                                                  final name =
                                                      student['studentName'] ??
                                                          'Unknown Name';
                                                  final email =
                                                      student['studentEmail'] ??
                                                          'Unknown Email';

                                                  return Container(
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 4,
                                                        horizontal: 12),
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      border: Border.all(
                                                          color: Colors
                                                              .grey.shade300),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              name,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 8),
                                                            Text(
                                                              email,
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          14),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  )
                                : Container(),
              ])),
          // Right Pane (Calendar)
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Color.fromARGB(255, 229, 143, 205),
              ),
              child: TableCalendar(
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });

                  // Assuming you need a week index or some other context here
                  int weekIndex =
                      1; // You may calculate or retrieve this value dynamically
                  markWeeklyDates(selectedDay,
                      weekIndex); // Pass both selectedDay and weekIndex
                },
                onDayLongPressed: (day, focusedDay) async {
                  final isMarked = _markedDates.any((d) => isSameDay(d, day));
                  await _onEventDateChanged(day, !isMarked);
                  setState(() {
                    _focusedDay =
                        focusedDay; // Maintain focus on the current view
                  });
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    // Highlight marked dates
                    if (_markedDates.any((d) => isSameDay(d, day))) {
                      return Center(
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                calendarFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
              ),
            ),
          )
        ]));
  }
}
