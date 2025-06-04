// user_info_screen.dart
// 인식된 얼굴을 저장된 사용자 정보와 매칭해서 보여주는 페이지

import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home_screen.dart';
import 'recognition_screen.dart';

class UserPreviewScreen extends StatelessWidget {
  final String userId;
  final String imagePath;

  const UserPreviewScreen({required this.userId, required this.imagePath});

  Future<Map<String, dynamic>?> _loadUserData(String userId) async {
    final dir = await getApplicationSupportDirectory();
    final dbFile = File('${dir.path}/faces/user_db.json');

    if (!await dbFile.exists()) return null;

    final jsonString = await dbFile.readAsString();
    final userDB = jsonDecode(jsonString) as Map<String, dynamic>;

    if (!userDB.containsKey(userId)) {
      
      return null;
    }
    return userDB[userId];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadUserData(userId),
      builder: (context, snapshot) {
        if (userId == 'unknown' || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("User Info"), backgroundColor: const Color(0xFF7E57C2),),
            body: const Center(
                child: Text(
                  "User not found",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
                ),
            ),
          );
        }
        final data = snapshot.data!;
        final name = data['name'];
        final email = data['email'];
        final images = List<String>.from(data['images']);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 0,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Text('Recognized Face', style: GoogleFonts.notoSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF247BBE),)),
                const SizedBox(height: 10),
                ClipOval(
                  child: Image.file(
                    File(imagePath),
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 30),
                Text('Name: $name', style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.blueGrey,), ),
                Text('Email: $email', style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.blueGrey,)),
                const SizedBox(height: 40),

                Text('Registered Face', style: GoogleFonts.notoSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF247BBE),)),
                const SizedBox(height: 10),
                FutureBuilder<Directory>(
                    future: getApplicationSupportDirectory(),
                    builder: (context, dirSnapshot) {
                      if (!dirSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                      final faceDir = Directory('${dirSnapshot.data!.path}/faces');
                      final imageEntry = images.isNotEmpty ? images.first : null;

                      if (imageEntry == null) {
                        return const Text("No registered face found.");
                      }

                      final path = imageEntry.contains('/faces/') ? imageEntry : '${faceDir.path}/$imageEntry';

                      final file = File(path);
                      if (!file.existsSync()) {
                        return const ListTile(
                        leading: Icon(Icons.warning, color: Colors.red),
                        title: Text("Image not found"),
                        );
                      }
                      return Container(
                          padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF247BBE), width: 2),
                              ),
                            child: ClipOval(
                              child: Image.file(
                                file,
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                                ),
        ),
        );
                        },
                       ),



                const SizedBox(height: 60),
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
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF247BBE),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text("No, not me"),
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const RecognitionScreen()),
                          );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    ),
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