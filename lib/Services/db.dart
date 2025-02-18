import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

User? user = FirebaseAuth.instance.currentUser;
CollectionReference users = FirebaseFirestore.instance.collection("users");

Future<bool> signin(BuildContext context) async {
  var userData = {
    "name": user!.displayName,
    // "provider": user!.providerData,
    // "photourl": user!.photoURL
  };
  users.doc(user!.uid).get().then((doc) {
    if (doc.exists) {
      doc.reference.update(userData);
    } else {
      users.doc(user!.uid).set(userData);
    }
  });
  return true;
}
