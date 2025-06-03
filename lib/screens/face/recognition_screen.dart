// recognition_screen.dart
// 얼굴 인식 화면 – 실제 임베딩 로직 생략 상태이며, 얼굴 감지 후 임의 사용자 정보로 이동

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
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

  bool _isDetecting = false;
  bool _faceRecognized = false;
  bool _isCameraReady = false;

  String _statusText = 'Scanning for face...';

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
      if (_isDetecting || _faceRecognized) return;
      _isDetecting = true;

      final faces = await _cameraService.detectFaces(image, _faceDetector);
      if (faces.isNotEmpty) {
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
            final cropped = _preprocessor.cropAndResize(
                decoded, faces.first.boundingBox);
            final input = _preprocessor.normalizeImage(cropped);
            final embedding = _faceNetService.getEmbedding(input);
            embeddings.add(embedding);
          }


        final avgEmbedding = _averageEmbedding(embeddings);
        final matchedUserId = await _findMostSimilarUser(avgEmbedding);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) =>
                UserPreviewScreen(userId: matchedUserId ?? 'unknown',
                  imagePath: previewImagePath!,
                ),
            ),
          );
        }
      }
      _isDetecting = false;
    });
  }

  List<double> _averageEmbedding(List<List<double>> vectors) {
    final avg = List<double>.filled(vectors[0].length, 0.0);
    for (var v in vectors) {
      for (int i = 0; i < v.length; i++) {
        avg[i] += v[i];
      }
    }
    return avg.map((e) => e / vectors.length).toList();
  }


  Future<String?> _findMostSimilarUser(List<double> inputEmbedding) async {
    final dir = await getApplicationDocumentsDirectory();
    final faceDir = Directory('${dir.path}/faces');
    if (!await faceDir.exists()) return null;

    // 사용자별 이미지 그룹화
    final Map<String, List<File>> userImageMap = {};
    for (final file in faceDir.listSync().whereType<File>()) {
      final fileName = file.uri.pathSegments.last;
      if (!fileName.contains('_')) continue;
      final userId = fileName.split('_').first;
      userImageMap.putIfAbsent(userId, () => []).add(file);
    }

    String? bestMatch;
    double bestScore = -1;

    for (final entry in userImageMap.entries) {
      final userId = entry.key;
      final files = entry.value;

      final embeddings = <List<double>>[];

      for (final file in files) {
        debugPrint("📁 [$userId] DB 이미지: ${file.path}");

        final bytes = await file.readAsBytes();
        final image = img.decodeImage(bytes);
        if (image == null) {
          debugPrint("⚠️ 이미지 디코딩 실패: ${file.path}");
          continue;
        }

        final resized = img.copyResize(image, width:160, height:160);
        final embedding = _faceNetService.getEmbedding(_preprocessor.normalizeImage(resized));
        embeddings.add(embedding);
      }

      if (embeddings.isEmpty) continue;

      final avgEmbedding = _averageEmbedding(embeddings);
      final sim = _similarityService.cosineSimilarity(inputEmbedding, avgEmbedding);

      debugPrint("🔍 [$userId] 평균 유사도: $sim");

      if (sim > bestScore && sim > 0.6) {
        bestScore = sim;
        bestMatch = userId;
        debugPrint("✅ 임시 매칭: $bestMatch (score: $bestScore");
      }
    }
    if (bestMatch == null) {
      debugPrint("❌ 유사한 사용자 없음");
    } else {
      debugPrint("✅ 최종 매칭 : $bestMatch (score: $bestScore");
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
      appBar: AppBar(title: const Text('Face Recognition')),
      body: (!_isCameraReady || controller == null || !controller.value.isInitialized)
          ? const Center(child: CircularProgressIndicator())
      : Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(controller),
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

