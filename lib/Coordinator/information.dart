import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Coordinator/desktop.dart';
import 'package:flutter_application_1/Coordinator/registration.dart';
import 'package:flutter_application_1/Student/login.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  // Custom Drawer
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const DesktopScaffold()),
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
                MaterialPageRoute(
                    builder: (context) => const FYPRegistration()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.orange),
            title: const Text(
              'A N N O U N C E M E N T S',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color.fromARGB(255, 70, 27, 110),
              ),
            ),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const AnnouncementsScreen()),
              );
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

  Future<void> _addNewsArticle(BuildContext context) async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add News Article'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  contentController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('news').add({
                  'title': titleController.text,
                  'content': contentController.text,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Update News Article with Confirmation
  Future<void> _updateNewsArticle(
      BuildContext context, QueryDocumentSnapshot article) async {
    final TextEditingController titleController =
        TextEditingController(text: article['title']);
    final TextEditingController contentController =
        TextEditingController(text: article['content']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit News Article'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Show confirmation dialog before updating
              bool confirmUpdate = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Update'),
                  content: const Text(
                      'Are you sure you want to update this article?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                            context, false); // Return false if canceled
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                            context, true); // Return true if confirmed
                      },
                      child: const Text('Update'),
                    ),
                  ],
                ),
              );

              if (confirmUpdate == true) {
                if (titleController.text.isNotEmpty &&
                    contentController.text.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('news')
                      .doc(article.id)
                      .update({
                    'title': titleController.text,
                    'content': contentController.text,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // Delete News Article with Confirmation
  Future<void> _deleteNewsArticle(BuildContext context, String id) async {
    // Show confirmation dialog before deleting
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this article?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false); // Return false if canceled
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true); // Return true if confirmed
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      await FirebaseFirestore.instance.collection('news').doc(id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 185, 205, 234),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 75, 69, 178),
        title: const Text(
          'A N N O U N C E M E N T S',
          style: TextStyle(color: Colors.white, fontSize: 25),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _addNewsArticle(context),
          ),
        ],
      ),
      drawer: myDrawer(context), // Add the drawer here
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('news')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final articles = snapshot.data!.docs;

          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(article['title']),
                  subtitle: Text(article['content']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _updateNewsArticle(context, article),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _deleteNewsArticle(context, article.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
