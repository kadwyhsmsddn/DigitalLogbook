import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';

class View extends StatefulWidget {
  final Map? data;
  final commentData;
  final DocumentReference ref;
  final Function(double) updateProgress;
  final int selectedWeekIndex;

  const View({
    super.key,
    required this.updateProgress,
    this.data,
    required this.ref,
    required this.commentData,
    required this.selectedWeekIndex,
  });

  @override
  _ViewState createState() => _ViewState();
}

class _ViewState extends State<View> {
  late TextEditingController descriptionController;
  List<Map<String, dynamic>> weeksData = [];
  Map<String, dynamic>? commentData;
  bool isChecked = false;
  List<Uint8List> pickedImagesInBytes = [];
  List<String> imageUrls = [];
  int imageCounts = 0;
  bool isItemSaved = false;
  bool isUploading = false;
  bool isDescriptionEditable = true; // New flag to control editability

  @override
  void initState() {
    super.initState();
    descriptionController = TextEditingController();
    _fetchCommentData();
    _loadUserData();
  }

  Future<void> _fetchCommentData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userUid = user.uid;
      final docSnapshot = await FirebaseFirestore.instance
          .collection('comment')
          .doc(userUid)
          .get();

      if (docSnapshot.exists) {
        final commentSnapshot = docSnapshot.data() as Map<String, dynamic>?;
        setState(() {
          commentData =
              commentSnapshot?['weeks'] as Map<String, dynamic>? ?? {};
          // Check if a comment exists for the current week
          String weekKey = 'week_${widget.selectedWeekIndex + 1}';
          isDescriptionEditable = commentData?[weekKey] == null;
        });
      } else {
        setState(() {
          commentData = {};
          isDescriptionEditable =
              true; // No comments, so description is editable
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String userId = currentUser.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user_progress') // Changed to user_progress
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          weeksData = List<Map<String, dynamic>>.from(userData['weeks'] ?? []);
          _loadWeekData(widget.selectedWeekIndex);
        });
      }
    }
  }

  void _loadWeekData(int selectedWeekIndex) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      String userId = currentUser.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user_progress') // Changed to user_progress
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        List<dynamic>? weeks = userData['weeks'];

        if (weeks != null && selectedWeekIndex < weeks.length) {
          Map<String, dynamic> weekData = weeks[selectedWeekIndex];
          descriptionController.text = weekData['description'] ?? '';
          setState(() {
            isChecked = weekData['isChecked'] ?? false;
            imageUrls = List<String>.from(weekData['imageUrls'] ?? []);
          });
        }
      }
    }
  }

  void _onCheckboxChanged(bool? value) async {
    setState(() {
      isChecked = value ?? false;
    });

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String userId = currentUser.uid;

      if (widget.selectedWeekIndex < weeksData.length) {
        weeksData[widget.selectedWeekIndex]['isChecked'] = isChecked;
      } else {
        weeksData.add({'isChecked': isChecked});
      }

      await FirebaseFirestore.instance
          .collection('user_progress') // Changed to user_progress
          .doc(userId)
          .update({'weeks': weeksData});

      double progressValue = isChecked ? 1.0 : 0.0;
      widget.updateProgress(progressValue);
    }
  }

  Future<void> _pickFiles() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final ImagePicker picker = ImagePicker();
      final List<XFile>? images = await picker.pickMultiImage();

      if (images != null) {
        setState(() {
          pickedImagesInBytes.clear();
          imageCounts = 0;
        });

        for (var image in images) {
          final Uint8List bytes = await image.readAsBytes();
          setState(() {
            pickedImagesInBytes.add(bytes);
            imageCounts += 1;
          });
        }
      }
    } else {
      FilePickerResult? fileResult =
          await FilePicker.platform.pickFiles(allowMultiple: true);

      if (fileResult != null) {
        setState(() {
          pickedImagesInBytes.clear();
          imageCounts = 0;
        });

        for (var element in fileResult.files) {
          if (element.bytes != null) {
            setState(() {
              pickedImagesInBytes.add(element.bytes!);
              imageCounts += 1;
            });
          }
        }
      }
    }
  }

  Future<List<String>> _uploadMultipleFiles() async {
    List<String> imageUrls = [];
    try {
      for (var i = 0; i < imageCounts; i++) {
        firebase_storage.UploadTask uploadTask;
        firebase_storage.Reference ref = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('uploads')
            .child('week_${widget.selectedWeekIndex}_image_${i.toString()}');

        final metadata =
            firebase_storage.SettableMetadata(contentType: 'image/jpeg');
        uploadTask = ref.putData(pickedImagesInBytes[i], metadata);

        uploadTask.snapshotEvents
            .listen((firebase_storage.TaskSnapshot snapshot) {
          double progress = snapshot.bytesTransferred / snapshot.totalBytes;
          setState(() {
            // Handle the progress, for example, updating the UI
            print('Uploading: ${progress * 100}%');
          });
        });

        await uploadTask.whenComplete(() => null);
        String imageUrl = await ref.getDownloadURL();
        setState(() {
          imageUrls.add(imageUrl);
        });
      }
    } catch (e) {
      print("Error uploading files: $e");
      // Handle the error, e.g., show an error message to the user
    }
    return imageUrls;
  }

  Future<void> save() async {
    setState(() {
      isUploading = true;
    });

    String newDescription = descriptionController.text;
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      String userId = currentUser.uid;

      List<String> uploadedImageUrls = [];
      if (pickedImagesInBytes.isNotEmpty) {
        uploadedImageUrls = await _uploadMultipleFiles();
      }

      Map<String, dynamic> updatedWeekData = {
        'description': newDescription,
        'isChecked': isChecked,
        'imageUrls': uploadedImageUrls,
      };

      if (widget.selectedWeekIndex < weeksData.length) {
        weeksData[widget.selectedWeekIndex] = updatedWeekData;
      } else {
        weeksData.add(updatedWeekData);
      }

      await FirebaseFirestore.instance
          .collection('user_progress') // Changed to user_progress
          .doc(userId)
          .set({
        'weeks': weeksData,
      }, SetOptions(merge: true));

      setState(() {
        _loadWeekData(widget.selectedWeekIndex);
        isUploading = false;
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 185, 205, 234),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 75, 69, 178),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          "Your Report",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        actions: [
          ElevatedButton(
            onPressed: isDescriptionEditable
                ? save
                : null, // Disable save button if description is not editable
            style: ElevatedButton.styleFrom(
              elevation: 1,
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Save"),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: descriptionController,
              style: const TextStyle(fontSize: 18, color: Colors.black),
              decoration: InputDecoration(
                hintText: "What's your progress?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              enabled:
                  isDescriptionEditable, // Disable if supervisor has commented
              readOnly:
                  !isDescriptionEditable, // Make it read-only if supervisor has commented
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Upload Images:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: isDescriptionEditable
                      ? _pickFiles
                      : null, // Disable file picker if description is not editable
                  child: const Text("Choose Files"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            isUploading
                ? const CircularProgressIndicator()
                : imageCounts > 0
                    ? Column(
                        children: List.generate(imageCounts, (index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Image.memory(pickedImagesInBytes[index]),
                          );
                        }),
                      )
                    : imageUrls.isNotEmpty
                        ? Column(
                            children: imageUrls.map((url) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Image.network(url),
                              );
                            }).toList(),
                          )
                        : const Text("No images selected"),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text(
                'Have you met the supervisor this week?',
                style: TextStyle(
                    color: Color.fromARGB(255, 70, 27, 110),
                    fontWeight: FontWeight.bold),
              ),
              value: isChecked,
              onChanged: isDescriptionEditable
                  ? _onCheckboxChanged
                  : null, // Disable checkbox if description is not editable
              activeColor: Colors.amber,
            ),
            const SizedBox(height: 20),
            _buildCommentForWeek(widget.selectedWeekIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentForWeek(int index) {
    if (commentData != null && commentData!.isNotEmpty) {
      String weekKey = 'week_${index + 1}';
      String comment = commentData?[weekKey] ?? "No comment available";

      return Container(
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
              "Supervisor's Comment",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: comment),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'No comment available',
              ),
              maxLines: null,
              readOnly: true,
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
