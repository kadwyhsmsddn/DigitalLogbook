import 'package:flutter/material.dart';
import 'package:flutter_application_1/Student/login.dart';

var drawerTextColor = TextStyle(
  color: Colors.grey[600]!,
);
var tilePadding = const EdgeInsets.only(left: 8.0, right: 8, top: 8);

Drawer myDrawer(BuildContext context) {
  return Drawer(
    backgroundColor: Colors.grey[300],
    elevation: 0,
    child: Column(
      children: [
        const DrawerHeader(
          child: Icon(
            Icons.home,
            size: 64,
          ),
        ),
        Padding(
          padding: tilePadding,
          child: ListTile(
            leading: const Icon(Icons.home),
            title: Text(
              'D A S H B O A R D',
              style: drawerTextColor,
            ),
          ),
        ),
        Padding(
          padding: tilePadding,
          child: ListTile(
            leading: const Icon(Icons.settings),
            title: Text(
              'S E T T I N G S',
              style: drawerTextColor,
            ),
          ),
        ),
        Padding(
          padding: tilePadding,
          child: ListTile(
            leading: const Icon(Icons.info),
            title: Text(
              'A B O U T',
              style: drawerTextColor,
            ),
          ),
        ),
        Padding(
          padding: tilePadding,
          child: ListTile(
            leading: const Icon(Icons.logout),
            title: Text(
              'L O G O U T',
              style: drawerTextColor,
            ),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Login()),
              );
            },
          ),
        )
      ],
    ),
  );
}
