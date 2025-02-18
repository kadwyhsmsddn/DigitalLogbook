import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Coordinator/desktop.dart';
import 'package:flutter_application_1/Student/login.dart';
import 'package:flutter_application_1/Student/Student_page.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions
          .currentPlatform, // Handles web, Android, iOS, etc.
    );

    // For platforms other than web, activate Firebase App Check
    if (!kIsWeb) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      );
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weekly Report',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // If the user is logged in, navigate to the home page
        if (snapshot.hasData && FirebaseAuth.instance.currentUser != null) {
          return DesktopScaffold();
        }

        // If the user is not logged in, show the Login page
        return const Login();
      },
    );
  }
}

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 185, 205, 234),
      body: Center(
        child: Container(
          height: 120.0,
          width: 120.0,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(''), // Add your splash logo here
              fit: BoxFit.contain,
            ),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
