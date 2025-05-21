// lib/screens/object/detection_screen.dart
// facenet512 모델 띄우기 전에 test용

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'dart:math';

class CatClassifierPage extends StatefulWidget {
  const CatClassifierPage({super.key});

  @override
  _CatClassifierPageState createState() => _CatClassifierPageState();
}

class _CatClassifierPageState extends State<CatClassifierPage> {
  late Interpreter interpreter;
  late List<String> labels;
  String result = "로딩 중...";

  @override
  void initState() {
    super.initState();
    classifyImage();
  }

  Future<void> classifyImage() async {
    try {
      // 1. 라벨 불러오기
      final labelData = await rootBundle.loadString('assets/labels.txt');
      labels = labelData.split('\n');

      // 2. 모델 불러오기
      interpreter = await Interpreter.fromAsset('assets/mobilenet.tflite');
      //interpreter = await Interpreter.fromBuffer(buffer); // 하드코딩으로 넣어주기, 바이너리 파일을 다트로 코드로 변환

      // 3. 이미지 불러오기
      ByteData imageData = await rootBundle.load('assets/cat.jpg');
      img.Image? oriImage = img.decodeImage(imageData.buffer.asUint8List());

      if (oriImage == null) {
        setState(() {
          result = "❌ 이미지 디코딩 실패";
        });
        return;
      }

      // 4. 이미지 리사이즈 (224x224)
      final resized = img.copyResize(oriImage, width: 224, height: 224);

      // 5. Uint8List로 전처리 ([-1, 1] 범위로 정규화)
      final input = Uint8List(1 * 224 * 224 * 3);
      int index = 0;
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = resized.getPixel(x, y);
          input[index++] = pixel.r.toInt();
          input[index++] = pixel.g.toInt();
          input[index++] = pixel.b.toInt();
        }
      }

      // 6. 입력 텐서 형태에 맞춰 reshape
      //var inputTensor = input.buffer.asUint8List();
      var output = List.filled(1001, 0.0).reshape([1, 1001]);

      // 7. 추론 실행
      interpreter.run(input.reshape([1, 224, 224, 3]), output);

      // 8. 결과 해석
      //final scores = output[0].cast<double>();
      //final maxScore = scores.reduce(max);
      final scores = output[0].map((e) => (e as num).toDouble()).toList();
      final maxScore = scores.reduce((a, b) => a > b ? a : b);
      final maxIndex = scores.indexOf(maxScore);
      final topLabel = labels[maxIndex];

      setState(() {
        result = "✅ 예측 결과: $topLabel\n(클래스 index: $maxIndex)";
      });
    } catch (e) {
      setState(() {
        result = "❌ 오류 발생: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cat Image Classifier')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(result, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
