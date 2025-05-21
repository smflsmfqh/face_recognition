// home_screen.dart
// 메인 화면 - 얼굴 인식 로그인(face recognition), 얼굴 등록(new register)로 이동할 수 있음

import 'package:flutter/material.dart';
import 'face/recognition_screen.dart';
import 'face/register_screen.dart';
import 'face/register_info_screen.dart';
import 'object/detection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Recognition')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                child: const Text('Face Recognition (Login)'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecognitionScreen()),
                ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('New Face Register'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Tflite model Test'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CatClassifierPage()),
              ),
            )
          ],
        )
      )
    );
  }
}