// facenet_service.dart
// facenet512.tflite 모델 불러와서 임베딩

import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceNetService {
  late final Interpreter _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/facenet512.tflite');
  }

  List<double> getEmbedding(Float32List input) {
    final output = List.filled(512, 0.0).reshape([1, 512]);
    _interpreter.run(input.reshape([1, 160, 160, 3]), output);
    return List<double>.from(output[0]);
  }

  void close() {
    _interpreter.close();
  }
}