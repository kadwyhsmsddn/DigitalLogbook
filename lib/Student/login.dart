import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/Coordinator/desktop.dart';
import 'package:flutter_application_1/Student/Student_page.dart';
import 'package:flutter_application_1/Models/shared.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/Supervisor/Supervisor_page.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;
FirebaseAuth auth = FirebaseAuth.instance;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool loading = false;

  final auth = FirebaseAuth.instance;
  late UserCredential user;
  late String email, password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromARGB(255, 185, 205, 234),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
            child: Form(
              key: formKey,
              child: Center(
                child: Column(
                  children: [
                    const Spacer(
                      flex: 1,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Text(
                      " Digital Logbook\nFinal Year Project",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 242, 144, 17),
                      ),
                    ),
                    const Spacer(flex: 1),
                    TextFormField(
                      style: const TextStyle(color: Colors.black),
                      validator: (val) => val!.isEmpty ||
                              !(val.contains('@') || !(val.contains('.com')))
                          ? 'Enter a valid email address'
                          : null,
                      decoration: textInputDecoration.copyWith(
                        labelText: 'Enter Email',
                        labelStyle: const TextStyle(
                            color: Colors.black), // White label text
                        filled: true,
                        fillColor:
                            Colors.white, // White background for the text field
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 70, 27, 110)),
                        ),
                      ),
                      onChanged: (value) {
                        email = value;
                      },
                    ),
                    const SizedBox(height: 20.0),
                    TextFormField(
                      style: const TextStyle(color: Colors.black),
                      obscureText: true,
                      validator: (val) => val!.isEmpty || val.length < 6
                          ? 'Enter a password greater than 6 characters'
                          : null,
                      decoration: textInputDecoration.copyWith(
                        labelText: 'Enter Password',
                        labelStyle: const TextStyle(
                            color: Colors.black), // White label text
                        filled: true,
                        fillColor:
                            Colors.white, // White background for the text field
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 70, 27, 110)),
                        ),
                      ),
                      onChanged: (value) {
                        password = value;
                      },
                    ),
                    const SizedBox(height: 40.0),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 242, 144, 17),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                      ),
                      icon: const Icon(
                        Icons.login,
                        color: Color.fromARGB(255, 10, 10, 10),
                        size: 25,
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          setState(() {});
                          try {
                            user = await auth.signInWithEmailAndPassword(
                                email: email, password: password);

                            navigateBasedOnEmail(context, email);
                          } on FirebaseAuthException catch (e) {
                            String error = e.message.toString();
                            final loginerror = SnackBar(content: Text(error));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(loginerror);
                          }
                        }
                      },
                      label: const Text(
                        "Login",
                        style: TextStyle(
                            color: Color.fromARGB(255, 13, 13, 13),
                            fontSize: 15),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextButton(
                      onPressed: () async {
                        await showResetPasswordDialog(context);
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const Spacer(
                      flex: 1,
                    )
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Future<void> showResetPasswordDialog(BuildContext context) async {
    String? email;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Reset Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Enter Email'),
                onChanged: (value) {
                  email = value;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Reset"),
              onPressed: () async {
                if (email != null) {
                  try {
                    await auth.sendPasswordResetEmail(email: email!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Password reset email sent. Please check your email.'),
                      ),
                    );
                    Navigator.of(context).pop();
                  } on FirebaseAuthException catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message!)),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your email.'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void navigateBasedOnEmail(BuildContext context, String email) {
    if (email.endsWith('@s.yahoo.com')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => StudentList()),
      );
    } else if (email.endsWith('@yahoo.com')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NoteScreen()),
      );
    } else if (email.endsWith('@c.yahoo.com')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DesktopScaffold()),
      );
    } else {
      final loginerror =
          const SnackBar(content: Text('Email domain not recognized.'));
      ScaffoldMessenger.of(context).showSnackBar(loginerror);
    }
  }
}
