import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart'; // Import the package

class ListReport extends StatefulWidget {
  final int weekNumber;
  final Map<String, dynamic> weekData;
  final String studentName;

  const ListReport({
    super.key,
    required this.weekNumber,
    required this.weekData,
    required this.studentName,
    required String studentId,
    required String studentUid,
  });

  @override
  _ListReportState createState() => _ListReportState();
}

class _ListReportState extends State<ListReport> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _loadComment() async {
    try {
      QuerySnapshot registrationSnapshot = await _firestore
          .collection('registration')
          .where('studentName', isEqualTo: widget.studentName)
          .get();

      if (registrationSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student not found in registration.')),
        );
        return;
      }

      String studentUid = registrationSnapshot.docs.first.id;

      DocumentSnapshot commentSnapshot =
          await _firestore.collection('comment').doc(studentUid).get();

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
      QuerySnapshot registrationSnapshot = await _firestore
          .collection('registration')
          .where('studentName', isEqualTo: widget.studentName)
          .get();

      if (registrationSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student not found in registration.')),
        );
        return;
      }

      String studentUid = registrationSnapshot.docs.first.id;

      await _firestore.collection('comment').doc(studentUid).set({
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
    _loadComment();
  }

  @override
  Widget build(BuildContext context) {
    // Extract image URLs from weekData
    List<String> imageUrls =
        List<String>.from(widget.weekData['imageUrls'] ?? []);

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
          style: const TextStyle(color: Colors.white, fontSize: 16),
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
                      text: widget.weekData['description'] ??
                          'No description available',
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
