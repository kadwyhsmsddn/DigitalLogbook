import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewStudentReport extends StatefulWidget {
  final int weekNumber;
  final Map<String, dynamic> weekData;
  final String studentName;
  final String studentUid; // Add studentUid as a field

  const ViewStudentReport({
    super.key,
    required this.weekNumber,
    required this.weekData,
    required this.studentName,
    required this.studentUid, // Initialize studentUid
  });

  @override
  _ViewStudentReportState createState() => _ViewStudentReportState();
}

class _ViewStudentReportState extends State<ViewStudentReport> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String description =
      'No description available'; // Define description variable
  bool _isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    _loadDescription(); // Call _loadDescription
    _loadComment();
  }

  Future<void> _loadDescription() async {
    try {
      // Fetch the student's progress document from the user_progress collection
      DocumentSnapshot userProgressSnapshot = await _firestore
          .collection('user_progress')
          .doc(widget.studentUid)
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
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false
      });
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
        setState(() {
          _commentController.text =
              commentData['weeks']['week_${widget.weekNumber}'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading comment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 185, 205, 234),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 75, 69, 178),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          'Week ${widget.weekNumber} Report',
          style: const TextStyle(color: Colors.white, fontSize: 25),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: TextEditingController(
                            text: description, // Use description variable
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

                  // Container for Viewing a Comment
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
                          'Comment:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'No comments available',
                          ),
                          maxLines: null,
                          readOnly: true, // Makes the comment field read-only
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
