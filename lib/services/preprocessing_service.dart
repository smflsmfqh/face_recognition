// preprocessing_service.dart
// 임베딩하기 전에 이미지 전처리 역할

import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class PreprocessingService {
  //YUV420 to RGB 변환 (CameraImage -> img.Image)
  img.Image convertCameraImage(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel!;

    final img.Image imgBuffer = img.Image(width: width, height: height);

    for(int h = 0; h < height; h++) {
      for(int w = 0; w < width; w++) {
        final uvIndex = uvPixelStride * (w ~/ 2) + uvRowStride * (h ~/ 2);
        final y = image.planes[0].bytes[h * width + w];
        final u = image.planes[1].bytes[uvIndex];
        final v = image.planes[2].bytes[uvIndex];

        int r = (y + (1.370705 * (v - 128))).round();
        int g = (y - (0.337633 * (u - 128)) - (0.698001 * (v - 128))).round();
        int b = (y + (1.732446 * (u - 128))).round();

        imgBuffer.setPixelRgb(
            w, h, r.clamp(0, 255).toInt(), g.clamp(0, 255).toInt(), b.clamp(0, 255).toInt(),
        );
      }
    }
    return imgBuffer;
  }
  // 얼굴 bounding box 기준으로 crop 후 리사이즈
  img.Image cropAndResize(img.Image image, Rect faceRect) {
    final margin = 10;
    final x = faceRect.left.round().clamp(0, image.width - 1);
    final y = faceRect.top.round().clamp(0, image.height - 1);
    final w = (faceRect.width + 2 * margin).round().clamp(1, image.width - x);
    final h = (faceRect.height + 2 * margin).round().clamp(1, image.height - y);

    if (w < 40 || h < 40) {
      debugPrint("❌ 얼굴 크기가 너무 작음: ${w}x$h");
    }

    final crop = img.copyCrop(image, x: x, y: y, width: w, height: h);
    return img.copyResize(crop, width: 160, height: 160);
  }

  // Float32List [-1, 1] 정규화
  Float32List normalizeImage(img.Image image) {
    final buffer = Float32List(160*160*3);
    int index = 0;
    double normalize(int c) => (((c - 128) / 128).clamp(-1.0, 1.0)).toDouble();


    for (int y = 0; y < 160; y++) {
      for (int x = 0; x < 160; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        if (y == 0 && x < 5) {
          debugPrint("⚗️ [$x, $y] 정규화 샘플: R=$r, G=$g, B=$b → ${normalize(r)}, ${normalize(g)}, ${normalize(b)}");
        }

        buffer[index++] = normalize(r);
        buffer[index++] = normalize(g);
        buffer[index++] = normalize(b);
      }
    }
    return buffer;
  }
}