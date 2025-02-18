import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/Services/db.dart';
import 'package:flutter_application_1/Student/login.dart';
import 'package:flutter_application_1/Student/meeting_supervisor.dart';
import 'package:flutter_application_1/Student/viewdesc.dart' as ViewDesc;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class NoteScreen extends StatefulWidget {
  const NoteScreen({super.key});

  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final CollectionReference ref =
      FirebaseFirestore.instance.collection("weeks");
  String? _userName;
  String? imageUrl; // To store the uploaded image URL
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    fetchUserName();
    loadImageUrl(); // Load the profile image URL
  }

  // Format the timestamp for display
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'No timestamp';
    final DateTime date = timestamp.toDate();
    final DateFormat formatter = DateFormat('dd MMM yyyy');
    return formatter.format(date);
  }

  int _currentIndex = 0;

  Future<void> fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('registration')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userName =
              userDoc['studentName'] ?? 'User'; // Fallback if name is null
        });
      }
    }
  }

  Future<void> loadImageUrl() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('registration')
        .doc(user.uid)
        .get();

    if (userDoc.exists && userDoc.data()!.containsKey('imageUrl')) {
      setState(() {
        imageUrl = userDoc['imageUrl'];
      });
    }
  }

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await uploadImage();
    }
  }

  Future<void> uploadImage() async {
    if (_imageFile == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${user.uid}.jpg');

      await storageRef.putFile(_imageFile!);

      // Get the download URL
      final newImageUrl = await storageRef.getDownloadURL();

      // Update Firestore (registration collection)
      await FirebaseFirestore.instance
          .collection('registration')
          .doc(user.uid)
          .update({'imageUrl': newImageUrl});

      setState(() {
        imageUrl = newImageUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image uploaded successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: $e")),
      );
    }
  }

  Future<String> fetchProjectTitle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('registration')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final projectTitle = userDoc['projectTitle'] as String?;
          return projectTitle ??
              "Let's find your best project!"; // Fallback if project title is null
        }
      } catch (e) {
        print("Error fetching project title: $e");
        return "Student didn't enter their project title yet"; // Fallback if there's an error
      }
    }
    return "Let's find your best project!"; // Fallback if user is not logged in or data is missing
  }

  @override
  Widget build(BuildContext context) {
    // Initialize _pages here to avoid referencing widgets before they are defined
    final List<Widget> _pages = [
      HomePage(),
      TasksPage(formatTimestamp: formatTimestamp),
      ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 205, 224, 252),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 75, 69, 178),
        elevation: 0,
        toolbarHeight: 150,
        automaticallyImplyLeading: false,
        flexibleSpace: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      // Add Flexible to prevent overflow
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Hey!",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                              height: 5), // Spacing between "Hey!" and username
                          Text(
                            _userName ?? "User", // Fallback if username is null
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: imageUrl != null
                            ? NetworkImage(imageUrl!)
                            : AssetImage('assets/avatar.jpg') as ImageProvider,
                        child: _imageFile == null && imageUrl == null
                            ? Icon(Icons.camera_alt,
                                size: 20, color: Colors.white)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                FutureBuilder<String>(
                  future: fetchProjectTitle(), // Fetch the project title
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator(
                          color: Colors.white); // Show a loader while fetching
                    } else if (snapshot.hasError) {
                      return const Text(
                        "Error loading project title",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text(
                        "Let's find your best project!",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      );
                    } else {
                      return Text(
                        snapshot.data!, // Display the fetched project title
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      );
                    }
                  },
                ),
              ]),
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: "Tasks",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

// HomePage widget
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Project",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to the Meeting Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MeetingSupervisor()),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 233, 153, 67),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.meeting_room, color: Colors.white),
                          SizedBox(height: 10),
                          Text(
                            "Meeting",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "See progress with your supervisor so far",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child:
                                Icon(Icons.arrow_forward, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      // Navigate to the NotesPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotesPage()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.note, color: Colors.black),
                          SizedBox(height: 10),
                          Text(
                            "Notes",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Write your note here",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // News section
            SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(238, 210, 209, 209),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "News",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // StreamBuilder to get the data from Firestore
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('news')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No News Available',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          );
                        }

                        final newsList = snapshot.data!.docs;

                        return ListView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(), // Disable scrolling
                          itemCount: newsList.length,
                          itemBuilder: (context, index) {
                            final newsItem = newsList[index];
                            final newsData =
                                newsItem.data() as Map<String, dynamic>;
                            final title = newsData['title'] ?? 'No Title';
                            final content =
                                newsData['content'] ?? 'No Content Available';

                            // Add a gap between each news item
                            return Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 16.0), // Gap between items
                              child: Container(
                                color:
                                    Colors.grey[200], // Grey background color
                                child: ListTile(
                                  title: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    content,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//notes page
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _noteController = TextEditingController();
  String? _editingNoteId;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Add or update a note
  Future<void> _saveNote() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final noteContent = _noteController.text.trim();
    if (noteContent.isEmpty) return;

    final studentUid = user.uid; // Use student UID as the document ID

    if (_editingNoteId != null) {
      // Update existing note
      await _firestore
          .collection('notes')
          .doc(studentUid)
          .collection('studentNotes')
          .doc(_editingNoteId)
          .update({
        'content': noteContent,
        'timestamp': DateTime.now(),
      });
    } else {
      // Add new note
      await _firestore
          .collection('notes')
          .doc(studentUid)
          .collection('studentNotes')
          .add({
        'content': noteContent,
        'timestamp': DateTime.now(),
      });
    }

    // Clear the input field and reset editing state
    _noteController.clear();
    setState(() {
      _editingNoteId = null;
    });
  }

  // Delete a note
  Future<void> _deleteNote(String noteId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('notes')
        .doc(user.uid)
        .collection('studentNotes')
        .doc(noteId)
        .delete();
  }

  // Edit a note
  void _editNote(String noteId, String content) {
    _noteController.text = content;
    setState(() {
      _editingNoteId = noteId;
    });
  }

  // Show delete confirmation dialog
  Future<void> _showDeleteConfirmationDialog(String noteId) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Note"),
          content: const Text("Are you sure you want to delete this note?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _deleteNote(noteId);
                Navigator.pop(context);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Show edit confirmation dialog
  Future<void> _showEditConfirmationDialog(
      String noteId, String content) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Note"),
          content: const Text("Are you sure you want to edit this note?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _editNote(noteId, content);
                Navigator.pop(context);
              },
              child: const Text("Edit", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 185, 205, 234),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 75, 69, 178),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          "Notes",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Note Input Field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText: "Write your note here...",
                  border: InputBorder.none,
                ),
                maxLines: 5,
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              onPressed: _saveNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: Text(
                _editingNoteId != null ? "Update Note" : "Save Note",
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),

            // Display Notes
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('notes')
                  .doc(user.uid)
                  .collection('studentNotes')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No notes found."));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final note = snapshot.data!.docs[index];
                    final noteId = note.id;
                    final content = note['content'];
                    final timestamp = note['timestamp'] as Timestamp?;

                    // Format the timestamp
                    final formattedTime = timestamp != null
                        ? DateFormat('dd MMM yyyy, hh:mm a')
                            .format(timestamp.toDate())
                        : 'No timestamp';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(content),
                        subtitle: Text(
                          formattedTime,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Edit Button
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  _showEditConfirmationDialog(noteId, content),
                            ),
                            // Delete Button
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _showDeleteConfirmationDialog(noteId),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// TasksPage widget
class TasksPage extends StatelessWidget {
  final String Function(Timestamp?) formatTimestamp;

  const TasksPage({super.key, required this.formatTimestamp});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 205, 224, 252),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('weeks')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No weeks available."));
                }

                final weeks = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: weeks.length,
                  itemBuilder: (context, index) {
                    var weekData = weeks[index].data() as Map<String, dynamic>?;
                    final note = weekData?['weekNote'] ?? 'No note';
                    final timestamp = formatTimestamp(weekData?['timestamp']);
                    return _buildWeekItem(
                      context,
                      note,
                      timestamp,
                      weekData,
                      weeks[index].reference,
                      index,
                    );
                  },
                );
              },
            ),
          ),
        ],
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
                  'You have 14 weeks overall. The week will turn green when supervisor has already commented.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
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
    );
  }

  Widget _buildWeekItem(
    BuildContext context,
    String note,
    String timestamp,
    Map<String, dynamic>? noteData,
    DocumentReference reference,
    int index,
  ) {
    final user = FirebaseAuth.instance.currentUser;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ViewDesc.View(
              data: noteData,
              ref: reference,
              updateProgress: (double progress) {},
              selectedWeekIndex: index,
              commentData: {},
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('comment')
              .doc(user!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
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
                      note,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timestamp,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // Check if the 'weeks' field exists and if the specific week has a comment
            final bool hasComment =
                snapshot.data!.exists && snapshot.data!['weeks'] != null
                    ? snapshot.data?['weeks']?['week_${index + 1}'] != null
                    : false;

            return Container(
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
                    note,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: hasComment ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timestamp,
                    style: TextStyle(
                      color: hasComment ? Colors.white : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ProfilePage widget
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController projectTitleController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData(); // Fetch user data when the page is loaded
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print("Fetching user data...");
      final querySnapshot = await FirebaseFirestore.instance
          .collection('registration')
          .where('uid', isEqualTo: user.uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print("Data fetched successfully.");
        final doc = querySnapshot.docs.first;
        setState(() {
          nameController.text = doc['supervisorName'] ?? '';
          emailController.text = doc['studentEmail'] ?? '';
          studentIdController.text = doc['studentId'] ?? '';
          projectTitleController.text = doc['projectTitle'] ?? '';
          phoneController.text = doc['phone'] ?? '';
          // Load profile image URL if available
        });
      } else {
        print("No data found.");
      }
    }
  }

  Future<void> updatePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newPassword = passwordController.text;

    // Only update the password if the new password is not empty
    if (newPassword.isNotEmpty) {
      try {
        await user.updatePassword(newPassword);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password updated successfully!")),
        );
        passwordController.clear(); // Clear the password field
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update password: $e")),
        );
      }
    }
  }

  Future<void> saveUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('registration')
          .doc(user.uid)
          .update({
        'superviaorName': nameController.text,
        'studentEmail': emailController.text,
        'studentId': studentIdController.text,
        'projectTitle': projectTitleController.text,
        'phone': phoneController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile: $e")),
      );
    }
  }

  // Show logout confirmation dialog
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut(); // Log out the user

                  // Navigate to the login page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                } catch (e) {
                  // Handle any errors
                  print("Error during logout: $e");
                }
              },
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 205, 224, 252),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              EditItem(
                title: "Supervisor Name",
                widget: TextField(
                  style: const TextStyle(
                    color: Color.fromARGB(255, 70, 27, 110),
                  ),
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: "Enter your name",
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              EditItem(
                title: "Email",
                widget: TextField(
                  style: const TextStyle(
                    color: Color.fromARGB(255, 70, 27, 110),
                  ),
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: "Enter your email",
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              EditItem(
                title: "Student ID",
                widget: TextField(
                  style: const TextStyle(
                    color: Color.fromARGB(255, 70, 27, 110),
                  ),
                  controller: studentIdController,
                  decoration: const InputDecoration(
                    hintText: "Enter your student ID",
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              EditItem(
                title: "Project Title",
                widget: TextField(
                  style: const TextStyle(
                    color: Color.fromARGB(255, 70, 27, 110),
                  ),
                  controller: projectTitleController,
                  decoration: const InputDecoration(
                    hintText: "Enter project title",
                    hintStyle:
                        TextStyle(color: Color.fromARGB(255, 70, 27, 110)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              EditItem(
                title: "Phone Number",
                widget: TextField(
                  style: const TextStyle(
                    color: Color.fromARGB(255, 70, 27, 110),
                  ),
                  controller: phoneController,
                  decoration: const InputDecoration(
                    hintText: "Enter phone number",
                    hintStyle:
                        TextStyle(color: Color.fromARGB(255, 70, 27, 110)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              EditItem(
                title: "Change Password",
                widget: TextField(
                  style: const TextStyle(
                    color: Color.fromARGB(255, 70, 27, 110),
                  ),
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: "Enter new password",
                    hintStyle:
                        TextStyle(color: Color.fromARGB(255, 70, 27, 110)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await saveUserData();
                    await updatePassword();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 233, 153, 67),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                  ),
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () => _showLogoutConfirmationDialog(
                      context), // Show confirmation dialog
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Red color for logout button
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                  ),
                  child: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditItem extends StatelessWidget {
  final String title;
  final Widget widget;

  const EditItem({required this.title, required this.widget, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        widget,
      ],
    );
  }
}
