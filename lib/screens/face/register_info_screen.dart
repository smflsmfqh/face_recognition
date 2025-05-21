// register_info_screen.dart
// 사용자 이름과 이메일 입력 후 얼굴 이미지 파일 이름을 사용자 이름 기반으로 변경

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'register_info_preview_screen.dart';

class RegisterInfoScreen extends StatefulWidget {
  const RegisterInfoScreen({super.key});

  @override
  State<RegisterInfoScreen> createState() => _RegisterInfoScreenState();
}

class _RegisterInfoScreenState extends State<RegisterInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _saving = false;

  String _safeFileName(String name) {
    return name.trim().replaceAll(RegExp(r'[^\w\d_-]'), '_');
  }

  Future<void> _saveUserInfoAndRenameImages() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both name and email.')),
      );
      return;
    }

    setState(() => _saving = true);

    final appDir = await getApplicationDocumentsDirectory();
    final faceDir = Directory('${appDir.path}/faces');
    if (!await faceDir.exists()) {
      await faceDir.create(recursive: true);
    }

    for (int i = 0; i < 3; i++) {
      final oldFile = File('${faceDir.path}/face_tmp_$i.jpg');
      final newFile = File('${faceDir.path}/${name}_$i.jpg');
      if (await oldFile.exists()) {
        debugPrint('✅ renamed: ${oldFile.path} → ${newFile.path}');
        await oldFile.rename(newFile.path);
      } else {
        debugPrint('❌ old file not found: ${oldFile.path}');
        setState(() => _saving = false);
        return;
      }
    }

    setState(() => _saving = false);

    debugPrint("🧪 전달된 userName: $name");
    debugPrint("🧪 전달된 email: $email");

    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterPreviewScreen(
          userName: name,
          email: email,
        ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter User Information')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            _saving
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _saveUserInfoAndRenameImages,
              child: const Text('Complete Registration'),
            ),
          ],
        ),
      ),
    );
  }
}