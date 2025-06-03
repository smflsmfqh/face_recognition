import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import '../home_screen.dart';
import 'recognition_screen.dart';

class UserPreviewScreen extends StatelessWidget {
  final String userId;
  final String imagePath;

  const UserPreviewScreen({required this.userId, required this.imagePath});

  Future<Map<String, dynamic>?> _loadUserData(String userId) async {
    final dir = await getApplicationDocumentsDirectory();
    final dbFile = File('${dir.path}/faces/user_db.json');

    if (!await dbFile.exists()) return null;

    final jsonString = await dbFile.readAsString();
    final userDB = jsonDecode(jsonString);
    return userDB[userId];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadUserData(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text("User Info"),),
            body: const Center(child: Text("User not found")),
          );
        }
        final data = snapshot.data!;
        final name = data['name'];
        final email = data['email'];
        final images = List<String>.from(data['images']);


        return Scaffold(
          appBar: AppBar(title: const Text('User Preview')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recognized Face', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Center(child: Image.file(File(imagePath), width: 160)),

                const SizedBox(height: 20),
                Text('Name: $name', style: const TextStyle(fontSize: 20)),
                Text('Email: $email', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),

                const Text('Registered Face', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Expanded(
                  child:FutureBuilder<Directory>(
                    future: getApplicationDocumentsDirectory(),
                    builder: (context, dirSnapshot) {
                      if (!dirSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final faceDir = Directory('${dirSnapshot.data!.path}/faces');
                    return ListView.builder(
                        itemCount: images.length,
                        itemBuilder: (_, index) {
                          final imageEntry = images[index];
                          final path = imageEntry.contains('/faces/') ? imageEntry : '${faceDir.path}/$imageEntry';

                          final file = File(path);
                          if (!file.existsSync()) {
                            return const ListTile(
                              leading: Icon(Icons.warning, color: Colors.red),
                              title: Text("Image not found"),
                            );
                          }
                          return Card(
                            child: Image.file(file),
                          );
                        },
                       );
                    },
                ),
               ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text("Yes, that's me"),
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const HomeScreen()),
                          );
                          },
                    ),
                    ElevatedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text("No, not me"),
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const RecognitionScreen()),
                          );
                    },),
                  ],
                )
    ],
    ),
    ),
        );
        },

    );
  }
}