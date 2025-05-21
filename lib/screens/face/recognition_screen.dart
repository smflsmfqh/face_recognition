// recognition_screen.dart
// 얼굴 인식 화면 – 실제 임베딩 로직 생략 상태이며, 얼굴 감지 후 임의 사용자 정보로 이동

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../services/camera_service.dart';
import 'user_info_screen.dart';

class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({super.key});

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {
  final CameraService _cameraService = CameraService();
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  bool _faceRecognized = false;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(options: FaceDetectorOptions());
    _startCameraStream();
  }

  Future<void> _initializeCamera() async {
    await _cameraService.initializeCamera();
    setState(() {
      _isCameraReady = _cameraService.isInitialized;
    });
    _startCameraStream();
  }

  void _startCameraStream() async {
    await _cameraService.initializeCamera();
    _cameraService.controller?.startImageStream((CameraImage image) async {
      if (_isDetecting || _faceRecognized) return;
      _isDetecting = true;

      final faces = await _cameraService.detectFaces(image, _faceDetector);
      if (faces.isNotEmpty) {
        _faceRecognized = true;
        _cameraService.controller?.stopImageStream();

        // 얼굴이 감지되면 1장 캡처
        final file = await _cameraService.controller!.takePicture();
        final appDir = await getApplicationDocumentsDirectory();
        final userId = const Uuid().v4(); // 추후에
        final fileName = 'recognized_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await file.saveTo('${appDir.path}/$fileName');

        // 실제로는 여기서 임베딩 → 유사도 비교 → 사용자 판별이 이뤄져야 하지만 생략
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MockUserInfoPage(userId: userId),
            ),
          );
        }
      }
      _isDetecting = false;
    });
  }

  @override
  void dispose() {
    _faceDetector.close();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraService.controller;

    return Scaffold(
      appBar: AppBar(title: const Text('Face Recognition')),
      body: !_isCameraReady || controller == null
          ? const Center(child: CircularProgressIndicator())
      : Column(
        children: [
          AspectRatio(
            aspectRatio:controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
          const SizedBox(height: 20),
          Text(
              _faceRecognized ? 'Face recognized!' : 'Scanning for face...'
          ),
        ],
      ),
    );
  }
}

