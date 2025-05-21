import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class MockUserInfoPage extends StatelessWidget {
  final String userId;
  const MockUserInfoPage({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    Future<List<String>> loadFaceImages() async {
      final dir = await getApplicationDocumentsDirectory();
      final faceDir = Directory(dir.path);
      if (!await faceDir.exists()) return [];
      final image = faceDir.listSync().whereType<File>().where((f) => f.path.contains('recognized_${userId}_')&&f.path.endsWith('.jpg')).map((f) => f.path).toList();
      return image;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('User Info')),
      body: FutureBuilder<List<String>>(
          future: loadFaceImages(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final paths = snapshot.data!;
            return ListView.builder(
              itemCount: paths.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Text('Face Image ${index + 1}'),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.file(
                        File(paths[index]),
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
    );
  }
}