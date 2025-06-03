// register_screen.dart
// 새로운 얼굴 등록 시작 화면
// 카메라를 실행 -> 얼굴 감지 -> 얼굴 감지 되면, 연속 캡처 및 저장 -> 사용자 정보 입력 화면으로 이동

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:google_fonts/google_fonts.dart';

import '../../services/camera_service.dart';
import '../../services/preprocessing_service.dart';
import '../../services/facenet_service.dart';
import '../../services/similarity_service.dart';
import '../../services/embedding_cache_service.dart';

import 'register_info_screen.dart';
import '../home_screen.dart';

import 'dart:io';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final CameraService _cameraService = CameraService();
  late FaceDetector _faceDetector;
  final PreprocessingService _preprocessor = PreprocessingService();
  final FaceNetService _faceNetService = FaceNetService();
  final SimilarityService _similarityService = SimilarityService();
  final EmbeddingCacheService _embeddingCacheService = EmbeddingCacheService();
  
  bool _isDetecting = false;
  bool _faceFound = false;
  bool _isCameraReady = false;
  bool _showSuccessIcon = false;
  String _statusMessage = 'Scanning for face...';

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(options: FaceDetectorOptions());
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _cameraService.initializeCamera();
    await _faceNetService.loadModel();
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
        await _cameraService.controller?.stopImageStream();

        final picture = await _cameraService.controller!.takePicture();
        final raw = File(picture.path).readAsBytesSync();
        final decoded = img.decodeImage(raw);
        if (decoded == null) return;

        final cropped = _preprocessor.cropAndResize(decoded, faces.first.boundingBox);
        final input = _preprocessor.normalizeImage(cropped);
        final currentEmbedding = _faceNetService.getEmbedding(input);

        // 얼굴 중복 검사
        final userIds = await _embeddingCacheService.listRegisteredUsers();
        for (final userId in userIds) {
          final existingEmbeddings = await _embeddingCacheService.loadUserEmbeddings(userId);
          for (final emb in existingEmbeddings) {
            final sim = _similarityService.cosineSimilarity(currentEmbedding, emb);
            if (sim > 0.7) {
              setState(() {
                _isDetecting = false;
                _faceFound = false;
                _showSuccessIcon = false;
                _statusMessage = '';
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                        content: Text('이미 등록된 사용자입니다. 홈 화면으로 이동합니다.'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                  );
              }
              await Future.delayed(const Duration(seconds: 3));
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                );
              }
                return;
              }
            }
          }

          // 중복 아님 -> 얼굴 등록 시작
          await Future.delayed(const Duration(seconds: 2));

          final appDir = await getApplicationDocumentsDirectory();
          final faceDir = Directory('${appDir.path}/faces');
          debugPrint("📁 저장 디렉토리: ${faceDir.path}");

          if (!await faceDir.exists()) {
            await faceDir.create(recursive: true);
            debugPrint("📁 faces directory created.");
          }

          final newEmbeddings = <List<double>>[];
          String? previewPath;

          for (int i = 0; i < 3; i++) {
            try {
              final file = await _cameraService.controller!.takePicture();
              final fileName = 'face_tmp_$i.jpg';
              final savePath = '${faceDir.path}/$fileName';

              if (i==0) {
                previewPath = savePath;
              }

              await File(file.path).copy(savePath);
              debugPrint("📸 저장 완료: $savePath");

              final raw = File(savePath).readAsBytesSync();
              final decoded = img.decodeImage(raw);
              if (decoded != null) {
                final cropped = _preprocessor.cropAndResize(
                    decoded, faces.first.boundingBox);
                final input = _preprocessor.normalizeImage(cropped);
                final embedding = _faceNetService.getEmbedding(input);
                newEmbeddings.add(embedding);
              }
              await Future.delayed(const Duration(milliseconds: 800));
            } catch (e) {
              debugPrint("❌ 사진 저장 실패 ($i): $e");
            }
          }
          await _embeddingCacheService.saveEmbeddings('tmp', newEmbeddings);
          debugPrint("✅ 3장 임베딩 저장 완료");

          if (mounted && previewPath != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RegisterInfoScreen(previewPath: previewPath!),
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
    _faceNetService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraService.controller;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: !_isCameraReady || controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: controller.value.previewSize!.height,
                      height: controller.value.previewSize!.width,
                      child: CameraPreview(controller),
                    ),
                    ),
                  ),
                ),
                Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        AnimatedOpacity(
                            opacity: _showSuccessIcon ? 1.0 : 0.0,
                            duration: const Duration(milliseconds:  600),
                            child: Icon(Icons.check_circle, color: Colors.green, size: 48),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(128),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _statusMessage,
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
                          ),
                        )
                      ],
                    ),
                   )

        ],
      ),
    );
  }
}