// register_screen.dart
// 새로운 얼굴 등록 시작 화면
// 카메라를 실행 -> 얼굴 감지 -> 얼굴 감지 되면, 연속 캡처 3장 저장 -> 사용자 정보를 입력 화면으로 이동

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../services/camera_service.dart';
import 'register_info_screen.dart';
import 'dart:io';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final CameraService _cameraService = CameraService();
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  bool _faceFound = false;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(options: FaceDetectorOptions());
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _cameraService.initializeCamera();
    setState(() {
      _isCameraReady = _cameraService.isInitialized;
    });
    _startCameraStream();
  }

  void _startCameraStream() async {
    _cameraService.controller?.startImageStream((CameraImage image) async {
      if (_isDetecting || _faceFound) return;
      _isDetecting = true;

      final faces = await _cameraService.detectFaces(image, _faceDetector);

      if (faces.isNotEmpty) {
        debugPrint("👤 얼굴 감지됨. 캡처 시작.");
        setState(() => _faceFound = true);
        _cameraService.controller?.stopImageStream();

        final appDir = await getApplicationDocumentsDirectory();
        final faceDir = Directory('${appDir.path}/faces');
        debugPrint("📁 저장 디렉토리: ${faceDir.path}");

        if (!await faceDir.exists()) {
          await faceDir.create(recursive: true);
          debugPrint("📂 faces 디렉토리 생성됨.");
        }

        for (int i = 0; i < 3; i++) {
          try {
            final file = await _cameraService.controller!.takePicture();
            final fileName = 'face_tmp_$i.jpg';
            final savePath = '${faceDir.path}/$fileName';

            await File(file.path).copy(savePath);
            debugPrint("📸 저장 완료: $savePath");

            await Future.delayed(const Duration(seconds: 1));
          } catch (e) {
            debugPrint("❌ 사진 저장 실패 ($i): $e");
          }
        }
          // 저장된 파일 리스트 출력
          final savedFiles = faceDir.listSync();
          for (var f in savedFiles) {
            debugPrint("📄 저장된 파일: ${f.path}");
          }

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterInfoScreen()),
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
      appBar: AppBar(title: const Text('Register Face')),
      body: !_isCameraReady || controller == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
          const SizedBox(height: 20),
          Text(
              _faceFound ? 'Face detected!' : 'Face detecting...'
          ),
        ],
      ),
    );
  }
}