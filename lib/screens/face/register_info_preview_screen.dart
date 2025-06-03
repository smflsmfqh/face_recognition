// register_info_preview_screen.dart
// 사용자가 등록한 정보 기반으로 입력 최종 확인 페이지

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
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
          return SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                const SizedBox(height: 100),
                Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Text(
                  'Registration Successful!',
                  style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 40),
                Text('Name: $userName',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w500, color: Colors.blueGrey
                    )),
                Text('Email: $email',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w500, color: Colors.blueGrey
                    )),
                const SizedBox(height: 40),
                ClipOval(
                  child: Image.file(
                    File(imagePath),
                    width: 220,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 60),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 10,
                    backgroundColor: const Color(0xFF247BBE),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  child: Text('Back to Home', style: GoogleFonts.poppins(fontSize:17, fontWeight: FontWeight.w600, letterSpacing: 0.5,),
                  ),
                )
              ],
                )
              ],
            ),
          )
          );
        },
      ),
    );
  }
}
