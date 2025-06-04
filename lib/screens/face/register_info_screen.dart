// register_info_screen.dart
// 사용자 이름과 이메일 입력 후 얼굴 이미지 파일 이름을 사용자 이름 기반으로 변경

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register_info_preview_screen.dart';

class RegisterInfoScreen extends StatefulWidget {
  final String previewPath;

  const RegisterInfoScreen({super.key, required this.previewPath});

  @override
  State<RegisterInfoScreen> createState() => _RegisterInfoScreenState();
}

class _RegisterInfoScreenState extends State<RegisterInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _saving = false;

  String _safeFileName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'[^\w\d_-]'), '_');
  }

  void _showSnack(String msg, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveUserInfoAndRenameImages() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      _showSnack('Please enter both name and email.');
      return;
    }
    if (!email.contains('@')) {
      _showSnack('Invalid email format.');
      return;
    }

    setState(() => _saving = true);

    final appDir = await getApplicationSupportDirectory();
    final faceDir = Directory('${appDir.path}/faces');
    if (!await faceDir.exists()) {
      await faceDir.create(recursive: true);
    }

    final safeName = _safeFileName(name);
    final capturedImagePaths = <String>[];

    final dbFile = File('${faceDir.path}/user_db.json');
    Map<String, dynamic> userDB = {};
    if (await dbFile.exists()) {
      final jsonStr = await dbFile.readAsString();
      userDB = jsonDecode(jsonStr);
    }

    if (userDB.containsKey(safeName)) {
      _showSnack('This user name is already used. Please choose a different name.', color: Colors.orange);
      setState(() => _saving = false);
      return;
    }

    for (int i = 0; i < 3; i++) {
      final oldFile = File('${faceDir.path}/face_tmp_$i.jpg');
      final newFile = File('${faceDir.path}/${safeName}_$i.jpg');
      if (await oldFile.exists()) {
        final length = await oldFile.length();
        if (length > 0) {
          await oldFile.rename(newFile.path);
          capturedImagePaths.add('${safeName}_$i.jpg');
          
        } else {
          _showSnack('Image ${i + 1} is empty or corrupted.');
          setState(() => _saving = false);
          return;
        }
      } else {
        _showSnack('Image ${i + 1} not found.');
        setState(() => _saving = false);
        return;
      }
    }
    // 임베딩 파일 이름 변경: tmp_0.json → userId_0.json
    for (int i = 0; i < 3; i++) {
      final oldEmb = File('${faceDir.path}/tmp_$i.json');
      final newEmb = File('${faceDir.path}/${safeName}_$i.json');
      if (await oldEmb.exists()) {
        await oldEmb.rename(newEmb.path);
        
      } else {
        _showSnack('Embedding ${i + 1} not found.');
        setState(() => _saving = false);
        return;
      }
    }

    final embeddingFiles = List.generate(3, (i) => '${safeName}_$i.json');

    userDB[safeName] = {
      'name': name,
      'email': email,
      'images': capturedImagePaths,
      'embeddings': embeddingFiles,
    };

    await dbFile.writeAsString(jsonEncode(userDB), flush: true);

    final exists = await dbFile.exists();

    // 임시 파일 삭제
    final tempFiles = faceDir.listSync();
    for (final file in tempFiles) {
      if (file is File && (file.path.contains('tmp_'))) {
        file.deleteSync();
      }
    }

    setState(() => _saving = false);

    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterPreviewScreen(
          userName: safeName,
          email: email,
        ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Icon(
              Icons.person,
              size: 60,
              color: const Color(0xFF247BBE),
            ),
            const SizedBox(height: 16),
            Text(
              'User Register',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                //fontStyle: FontStyle.italic,
                color: Colors.blueGrey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 32),
            ClipOval(
              child: Image.file(
                File(widget.previewPath),
                width: 160,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 32),
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter your information",
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey,),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: GoogleFonts.notoSans(fontSize: 16),
                  border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                  labelText: 'Email',
                labelStyle: GoogleFonts.notoSans(fontSize: 16),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: _saving ? const CircularProgressIndicator() : ElevatedButton.icon(
                  onPressed: _saveUserInfoAndRenameImages,
                icon: const Icon(Icons.check),
                label: Text('Register', ),
                style: ElevatedButton.styleFrom(
                  elevation: 10,
                  backgroundColor: const Color(0xFF247BBE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ),
          ],
        )
        )

      ],
        ),
      ),
    );
  }
}