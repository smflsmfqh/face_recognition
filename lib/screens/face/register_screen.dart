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
  late EmbeddingCacheService _embeddingCacheService;
  
  bool _isDetecting = false;
  bool _faceFound = false;
  bool _isCameraReady = false;
  bool _showSuccessIcon = false;
  bool _isLiveFace = false;

  String _statusText = 'Scanning for face...';
  DateTime? _livenessStartTime;
  DateTime? _lastDetectionTime;
  final Duration _maxLivenessWait = Duration(seconds: 7);



  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(options: FaceDetectorOptions(
      enableClassification: true, // 눈 감을 확률 측정
      performanceMode: FaceDetectorMode.accurate,
    ));
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _cameraService.initializeCamera();
    await _faceNetService.loadModel();
    setState(() {
      _isCameraReady = _cameraService.isInitialized;
    });

    final appDir = await getApplicationSupportDirectory();
    final userDbPath = '${appDir.path}/faces/user_db.json';
    _embeddingCacheService = EmbeddingCacheService(userDbPath: userDbPath);

    _startCameraStream();
  }

  void _startCameraStream() async {
    _cameraService.controller?.startImageStream((CameraImage image) async {
      final now = DateTime.now();
      if (_isDetecting || _faceFound ||
          (_lastDetectionTime != null && now.difference(_lastDetectionTime!) < Duration(seconds: 1))) return;
      _isDetecting = true;
      _lastDetectionTime = now;

      final faces = await _cameraService.detectFaces(image, _faceDetector);

      if (faces.isNotEmpty) {
        final face = faces.first;

        // Liveness Detection
        if (!_isLiveFace) {
          final yaw = face.headEulerAngleY;
          final leftEye = face.leftEyeOpenProbability;
          final rightEye = face.rightEyeOpenProbability;

          // 얼굴 각도와 눈 깜빡임으로 liveness 탐지
          // 15: 고개 각도, 0.3: 눈이 얼마나 열려있는지 정도(0.2~0.3 정도면 감은 눈)
          final liveDetected = (yaw != null && yaw.abs() > 15) ||
              (leftEye != null && leftEye < 0.3) ||
              (rightEye != null && rightEye < 0.3);

          if (liveDetected) {
            _isLiveFace = true;
            _livenessStartTime = null;
            
            _updateStatus("✅ 실제 얼굴 확인됨");

            await Future.delayed(const Duration(seconds: 2));
            _updateStatus("📸 정면을 바라봐 주세요...");
            await Future.delayed(const Duration(seconds: 2));
          } else {
            _updateStatus("👀 좌우로 고개를 움직이거나 눈을 감아주세요");
            _livenessStartTime ??= now;

            if (now.difference(_livenessStartTime!) >= _maxLivenessWait) {
              _updateStatus("⚠️ 얼굴 움직임 또는 눈 깜빡임이 감지되지 않았습니다.");
              await Future.delayed(const Duration(seconds: 1));

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                    '❌ Liveness 확인 실패, 홈 화면으로 돌아갑니다.',
                    style: TextStyle(fontSize: 16),
                  ),
                  duration: Duration(seconds: 3),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ));
              }

              await Future.delayed(const Duration(seconds: 4));
              if (mounted) Navigator.pop(context);
            }
            _isDetecting = false;
            return;
          }
        }

        debugPrint("👤 얼굴 감지됨. 캡처 시작.");
        setState(() => _faceFound = true);
        await _cameraService.controller?.stopImageStream();
        await Future.delayed(const Duration(milliseconds: 300));

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
                _statusText = '';
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

          final appDir = await getApplicationSupportDirectory();
          final faceDir = Directory('${appDir.path}/faces');

          if (!await faceDir.exists()) {
            await faceDir.create(recursive: true);
          
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
              
            }
          }
          await _embeddingCacheService.saveEmbeddings('tmp', newEmbeddings);
          

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
  void _updateStatus(String newText) {
    if (!mounted) return;
    if (_statusText != newText) {
      setState(() => _statusText = newText);
    }
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
                    top: 32,
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
                            _statusText,
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