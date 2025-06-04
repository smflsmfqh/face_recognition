// recognition_screen.dart
// 얼굴 인식 화면 얼굴 감지 후 저장된 사용자와 비교 및 매칭

import 'package:face_recognition/services/embedding_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import 'dart:io';

import '../../services/camera_service.dart';
import '../../services/preprocessing_service.dart';
import '../../services/similarity_service.dart';
import '../../services/facenet_service.dart';

import 'user_info_screen.dart';


class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({super.key});

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {
  final CameraService _cameraService = CameraService();
  late FaceDetector _faceDetector;

  final PreprocessingService _preprocessor = PreprocessingService();
  final FaceNetService _faceNetService = FaceNetService();
  final SimilarityService _similarityService = SimilarityService();
  final EmbeddingCacheService _embeddingCacheService = EmbeddingCacheService();

  bool _isDetecting = false;
  bool _faceRecognized = false;
  bool _isCameraReady = false;
  bool _isLiveFace = false;


  String _statusText = 'Scanning for face...';
  DateTime? _livenessStartTime;
  DateTime? _lastDetectionTime;
  final Duration _maxLivenessWait = Duration(seconds: 7);

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(options: FaceDetectorOptions());
    _initialize();
  }

  Future<void> _initialize() async {
    await _cameraService.initializeCamera();
    await _faceNetService.loadModel();

    setState(() {
      _isCameraReady = _cameraService.isInitialized;
    });
    _startCameraStream();
  }

  void _startCameraStream() async {
    _cameraService.controller?.startImageStream((CameraImage image) async {
      final now = DateTime.now();
      if (_isDetecting || _faceRecognized ||
          (_lastDetectionTime != null && now.difference(_lastDetectionTime!) < Duration(seconds: 1))) return;
      _isDetecting = true;
      _lastDetectionTime = now;

      try {
        final faces = await _cameraService.detectFaces(image, _faceDetector);
        if (faces.isEmpty) {
          _isDetecting = false;
          return;
        }

        final face = faces.first;

        // Liveness Detection
        if (!_isLiveFace) {
          final yaw = face.headEulerAngleY;
          final leftEye = face.leftEyeOpenProbability;
          final rightEye = face.rightEyeOpenProbability;

          final liveDetected = (yaw != null && yaw.abs() > 15) ||
              (leftEye != null && leftEye < 0.3) ||
              (rightEye != null && rightEye < 0.3);

          if (liveDetected) {
            _isLiveFace = true;
            _livenessStartTime = null;
            debugPrint("✅ Liveness 확인됨 (Yaw: $yaw, Eyes: L=$leftEye R=$rightEye)");
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
        // 얼굴 인식
        _faceRecognized = true;
        await _cameraService.controller?.stopImageStream();

        final embeddings = <List<double>>[];
        String? previewImagePath;

        for (int i = 0; i < 3; i++) {
          setState(() {
            _statusText = "Please look straight... (${i+1}/3)";
          });
          await Future.delayed(const Duration(seconds: 1));

          final xfile = await _cameraService.controller!.takePicture();
          final file = File(xfile.path);

          if (i == 0 && await file.exists()) {
            previewImagePath = file.path;
            debugPrint("📸 Preview Set: ${file.path}");
          }

            final raw = File(file.path).readAsBytesSync();
            final decoded = img.decodeImage(raw)!;
            final cropped = _preprocessor.cropAndResize(decoded, faces.first.boundingBox);
            final input = _preprocessor.normalizeImage(cropped);
            final embedding = _faceNetService.getEmbedding(input);
            embeddings.add(embedding);
          }

        final matchedUserId = await _findMostSimilarUser(embeddings);
        final normalizedId = matchedUserId != null ? _normalizeUserId(matchedUserId) : 'unknown';

        debugPrint("🧪 normalized userId: $normalizedId");


        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) =>
                UserPreviewScreen(
                  userId: normalizedId,
                  imagePath: previewImagePath!,
                ),
            ),
          );
        }
      } catch (e) {
        debugPrint("❌ 스트림 처리 오류: $e");
      }
      _isDetecting = false;
    });
  }
  void _updateStatus(String newText) {
    if (_statusText != newText) {
      setState(() => _statusText = newText);
    }
  }

  String _normalizeUserId(String id) {
    return id.trim().toLowerCase().replaceAll(RegExp(r'[^\w\d_-]'), '_');
  }


  Future<String?> _findMostSimilarUser(List<List<double>> inputEmbeddings) async {
    final userIds = await _embeddingCacheService.listRegisteredUsers();

    String? bestMatch;
    double bestScore = -1;

    for (final userId in userIds) {
      final userEmbeddings = await _embeddingCacheService.loadUserEmbeddings(userId);
      for (final emb in userEmbeddings) {
        for (final inputEmb in inputEmbeddings) {
          final sim = _similarityService.cosineSimilarity(inputEmb, emb);
          debugPrint("🔍 [$userId] 유사도 : $sim");

            if (sim > bestScore && sim > 0.6) {
              bestScore = sim;
              bestMatch = userId;
              debugPrint("✅ 새 최고 매칭: $bestMatch (score: $bestScore)");
            }
          }
        }
      }
      if (bestMatch == null) {
        debugPrint("❌ 유사한 사용자 없음");
      } else {
        debugPrint("✅ 최종 매칭: $bestMatch (score: $bestScore)");
      }
      return bestMatch;
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
      body: (!_isCameraReady || controller == null || !controller.value.isInitialized)
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
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _statusText,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  )
                )
              )
          )
        ],
      ),
    );
  }
}

