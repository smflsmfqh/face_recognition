import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class RegisterPreviewScreen extends StatelessWidget {
  final String userName;
  final String email;

  const RegisterPreviewScreen({
    required this.userName,
    required this.email,
    super.key,
  });

  Future<String?> _loadPreviewImagePath() async {
    try {
      debugPrint("🧪 userName: $userName");
      final dir = await getApplicationDocumentsDirectory();
      final faceDir = Directory('${dir.path}/faces');
      if (!await faceDir.exists()) {
        debugPrint("❌ faces 디렉토리 없음: ${faceDir.path}");
        return null;
      }
        final previewPath = '${faceDir.path}/${userName}_0.jpg';
        final file = File(previewPath);

        final exists = file.existsSync();
        final bytes = exists ? await file.length() : 0;

        debugPrint("✅ 파일 경로: $previewPath");
        debugPrint("✅ 파일 존재 여부: $exists, 크기: $bytes bytes");

        if (!exists || bytes == 0) {
          debugPrint("⚠️ 파일 없음 또는 비어 있음");
          return null;
        }
        return previewPath;
      } catch (e) {
        debugPrint('🔥 오류 발생: $e');
        return null;
      }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration Preview')),
      body: FutureBuilder<String?>(
        future: _loadPreviewImagePath(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final imagePath = snapshot.data;
          if (imagePath == null) {
            return const Center(child: Text('No image found.'));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Registration Successful!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text('Name: $userName'),
                Text('Email: $email'),
                const SizedBox(height: 20),
                Image.file(
                  File(imagePath),
                  height: 250,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Text('Back to Home'),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
