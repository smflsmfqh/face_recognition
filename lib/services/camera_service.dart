// camera_service.dart
// 카메라 초기화 및 얼굴 감지

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraService {
  CameraController? _cameraController;
  late CameraDescription _cameraDescription;

  Future<void> initializeCamera({
    CameraLensDirection direction = CameraLensDirection.front,
  }) async {
    final cameras = await availableCameras();
    _cameraDescription = cameras.firstWhere(
        (camera) => camera.lensDirection == direction,
    );

    _cameraController = CameraController(
      _cameraDescription,
      ResolutionPreset.veryHigh,
      enableAudio: false,
    );
    await _cameraController!.initialize();
  }

  CameraController? get controller => _cameraController;
  bool get isInitialized => _cameraController?.value.isInitialized ?? false;

  InputImageRotation _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        throw Exception("Invalid rotation: $rotation");
    }
  }

  Future<List<Face>> detectFaces(CameraImage image, FaceDetector faceDetector) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      throw Exception('카메라가 초기화되지 않았습니다.');
    }
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final rotation = _rotationIntToImageRotation(_cameraDescription.sensorOrientation);
    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

    final inputImageMetaData = InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
    );

    final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageMetaData
    );

    final faces = await faceDetector.processImage(inputImage);

    return faces;
  }

  void dispose() {
    _cameraController?.dispose();
    _cameraController = null;
  }
}