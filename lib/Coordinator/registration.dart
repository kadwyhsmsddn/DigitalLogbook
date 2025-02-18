import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Coordinator/desktop.dart';
import 'package:flutter_application_1/Coordinator/information.dart';
import 'package:flutter_application_1/Student/login.dart';

// List of course options
final List<String> courses = [
  'Bachelor of Computer Engineering Technology (Computer Systems) with Honours',
  'Bachelor of Computer Engineering Technology (Networking Systems) with Honours',
  'Bachelor of Information Technology (Hons.) in Software Engineering',
  'Bachelor of Information Technology (Hons.) in Computer System Security',
];

// Drawer widget
Drawer myDrawer(BuildContext context) {
  return Drawer(
    backgroundColor: const Color.fromARGB(255, 185, 205, 234),
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
            if (ModalRoute.of(context)?.settings.name != '/desktop') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const DesktopScaffold()),
              );
            }
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
            if (ModalRoute.of(context)?.settings.name != '/registration') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const FYPRegistration()),
              );
            }
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
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          },
        ),
      ],
    ),
  );
}

// FYPRegistration Screen
class FYPRegistration extends StatefulWidget {
  const FYPRegistration({super.key});

  @override
  State<FYPRegistration> createState() => _FYPRegistrationState();
}

class _FYPRegistrationState extends State<FYPRegistration> {
  final CollectionReference ref =
      FirebaseFirestore.instance.collection("registration");
  final _studentFormKey = GlobalKey<FormState>();
  final _supervisorFormKey = GlobalKey<FormState>();

  int selectedIndex = 0;
  String studentName = '';
  String studentId = '';
  String studentEmail = '';
  String semester = '';
  String supervisorName = '';
  String supervisorDepartment = '';
  String supervisorEmail = '';

  List<Map<String, dynamic>> supervisorsList = [];
  String? selectedSupervisorUid;

  @override
  void initState() {
    super.initState();
    _fetchSupervisors();
  }

  Future<void> _fetchSupervisors() async {
    try {
      QuerySnapshot supervisorsSnapshot =
          await FirebaseFirestore.instance.collection("supervisors").get();
      setState(() {
        supervisorsList = supervisorsSnapshot.docs.map((doc) {
          return {
            "name": doc['supervisorName'] ?? 'Unknown',
            "uid": doc['uid'] ?? 'Unknown',
          };
        }).toList();
      });
    } catch (e) {
      _showFeedback('Failed to fetch supervisors: $e');
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    }
    String pattern = r'^[^@]+@[^@]+\.[^@]+';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _registerStudent() async {
    if (_studentFormKey.currentState!.validate()) {
      _studentFormKey.currentState!.save();
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: studentEmail,
          password:
              '123456', // Default password (not recommended for production)
        );

        // Find the selected supervisor
        var selectedSupervisor = supervisorsList.firstWhere(
          (supervisor) => supervisor["uid"] == selectedSupervisorUid,
          orElse: () => {"name": "Unknown", "uid": "Unknown"},
        );

        await ref.doc(userCredential.user?.uid).set({
          'studentName': studentName,
          'studentId': studentId,
          'studentEmail': studentEmail,
          'semester': semester,
          'supervisorName': selectedSupervisor["name"],
          'supervisorUid': selectedSupervisor["uid"],
          'uid': userCredential.user?.uid,
          'projectTitle': '',
          'phone': '', // Add an empty projectTitle field
        });

        _showFeedback('Student registered successfully');
        _studentFormKey.currentState!.reset();
      } on FirebaseAuthException catch (e) {
        _showFeedback(e.message ?? 'An error occurred. Please try again.');
      } catch (e) {
        _showFeedback('Failed to register student: $e');
      }
    }
  }

  Future<void> _registerSupervisor() async {
    if (_supervisorFormKey.currentState!.validate()) {
      _supervisorFormKey.currentState!.save();
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: supervisorEmail,
          password:
              '123456', // Default password (not recommended for production)
        );

        await FirebaseFirestore.instance
            .collection("supervisors")
            .doc(userCredential.user?.uid)
            .set({
          'supervisorName': supervisorName,
          'supervisorDepartment': supervisorDepartment,
          'supervisorEmail': supervisorEmail,
          'uid': userCredential.user?.uid,
        });

        _showFeedback('Supervisor registered successfully');
        _supervisorFormKey.currentState!.reset();
      } on FirebaseAuthException catch (e) {
        _showFeedback(e.message ?? 'An error occurred. Please try again.');
      } catch (e) {
        _showFeedback('Failed to register supervisor: $e');
      }
    }
  }

  final List<String> semesters = [
    'February 2024',
    'October 2024',
    'March 2025',
    'October 2025',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 205, 224, 252),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 75, 69, 178),
        title: const Text(
          "R E G I S T R A T I O N",
          style: TextStyle(color: Colors.white, fontSize: 25),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: myDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRegisterButton('Register Student', 0),
                _buildRegisterButton('Register Supervisor', 1),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: selectedIndex == 0
                  ? _buildStudentForm()
                  : _buildSupervisorForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton(String text, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: selectedIndex == index
                ? const Color.fromARGB(255, 70, 27, 110)
                : const Color.fromARGB(255, 233, 153, 67),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentForm() {
    return Form(
      key: _studentFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildTextFormField('Student Name', (value) => studentName = value!,
                validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter student name';
              }
              return null;
            }),
            const SizedBox(height: 16),
            _buildTextFormField('Student ID', (value) => studentId = value!,
                validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter student ID';
              } else if (value.length != 11 ||
                  !RegExp(r'^\d{11}$').hasMatch(value)) {
                return 'Student ID must be exactly 11 digits';
              }
              return null;
            }),
            const SizedBox(height: 16),
            _buildTextFormField(
                'Student Email', (value) => studentEmail = value!,
                validator: _validateEmail),
            const SizedBox(height: 16),
            _buildDropdownFormField(
              'Select Semester',
              semesters,
              (value) {
                if (value != null) {
                  semester = value;
                } else {
                  semester = ''; // Handle null case
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a semester';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildDropdownFormField(
              'Assign Supervisor',
              supervisorsList
                  .map((supervisor) => supervisor["name"] as String)
                  .toList(),
              (value) {
                if (value != null) {
                  selectedSupervisorUid = supervisorsList.firstWhere(
                          (supervisor) => supervisor["name"] == value)["uid"]
                      as String;
                } else {
                  selectedSupervisorUid = null; // Handle null case
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a supervisor';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _registerStudent,
              child: const Text('Register Student'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupervisorForm() {
    return Form(
      key: _supervisorFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildTextFormField(
                'Supervisor Name', (value) => supervisorName = value!,
                validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter supervisor name';
              }
              return null;
            }),
            const SizedBox(height: 16),
            _buildTextFormField(
                'Supervisor Email', (value) => supervisorEmail = value!,
                validator: _validateEmail),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _registerSupervisor,
              child: const Text('Register Supervisor'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField(String labelText, Function(String) onSaved,
      {String? Function(String?)? validator}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: labelText,
        hintStyle: const TextStyle(color: Color.fromARGB(255, 70, 27, 110)),
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
      onSaved: (value) => onSaved(value!),
    );
  }

  Widget _buildDropdownFormField(
      String labelText, List<String> items, Function(String?) onChanged,
      {String? Function(String?)? validator}) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: labelText,
        hintStyle: const TextStyle(color: Color.fromARGB(255, 70, 27, 110)),
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide.none,
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
