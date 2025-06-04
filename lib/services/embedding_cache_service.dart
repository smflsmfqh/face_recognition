// embedding_cache_service.dart
// 임베딩 추출 후 저장

import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

class EmbeddingCacheService {
  final String userDbPath;

  EmbeddingCacheService({required this.userDbPath});
  // 개별 임베딩 저장 후 파일명 리스트 반환
  Future<List<String>> saveEmbeddings(String userId, List<List<double>> embeddings) async {
    final dir = await getApplicationSupportDirectory();
    final faceDir = Directory('${dir.path}/faces');
    if (!await faceDir.exists()) {
      await faceDir.create(recursive: true);
    }

    final savedFiles = <String>[];
    for (int i = 0; i < embeddings.length; i++) {
      final fileName = '${userId}_$i.json';
      final file = File('${faceDir.path}/$fileName');
      await file.writeAsString(jsonEncode(embeddings[i]));
      savedFiles.add(fileName);
    }

    return savedFiles;
  }

  // user_db.json에서 임베딩 파일 목록을 읽어 해당 임베딩 로딩
  Future<List<List<double>>> loadUserEmbeddings(String userId) async {
    //final dir = await getApplicationSupportDirectory();
    //final faceDir = Directory('${dir.path}/faces');
    //final dbFile = File('${faceDir.path}/user_db.json');
    final dbFile = File(userDbPath);
    final faceDir = dbFile.parent;

    if (!await dbFile.exists()) {
      debugPrint("❌ user_db.json 없음");
      return [];
    }
    try {
      final dbContent = await dbFile.readAsString();
      final userDB = jsonDecode(dbContent) as Map<String, dynamic>;
      debugPrint("📄 user_db.json raw keys:");
      userDB.keys.forEach((k) {
        debugPrint("key: '${k}' / length: ${k.length}");
      });
      final normalizedUserId = userId.trim().toLowerCase();

      String? realMatchedKey;
      for (final k in userDB.keys) {
        final trimmedKey = k.trim().toLowerCase();
        debugPrint("🔍 비교 중: key='$k' => trimmed='$trimmedKey', target='$normalizedUserId'");
        if (trimmedKey == normalizedUserId) {
          realMatchedKey = k;
          break;
        }
      }

      if (realMatchedKey == null) {
        debugPrint("❌ $userId not found in user_db.json");
        return [];
      }

      debugPrint("✅ 최종 일치 키: '$realMatchedKey'");

      final userData = userDB[realMatchedKey];


      final fileNames = List<String>.from(userData['embeddings']);
      final embeddings = <List<double>>[];

      for (final name in fileNames) {
        final path = '${faceDir.path}/$name';
        final file = File(path);
        if (!await file.exists()) {
          debugPrint("⚠️ 파일 없음: $path");
          continue;
        }

        final data = await file.readAsString();
        final json = jsonDecode(data);

        if (json is List) {
          embeddings.add(List<double>.from(json));
        } else {
            debugPrint("❌ 예상과 다른 형식: $path");
        }
      }
      return embeddings;
      } catch (e) {
      debugPrint("❌ user_db.json 파싱 실패: $e");
      return [];
      }
    }


  // 모든 등록 사용자 ID 목록 (증복 제거)
  Future <List<String>> listRegisteredUsers() async {
    //final dir = await getApplicationSupportDirectory();
    //final faceDir = Directory('${dir.path}/faces');
    //final dbFile = File('${faceDir.path}/user_db.json');

    final dbFile = File(userDbPath);

    debugPrint("📂 [EmbeddingCache] user_db.json 경로: ${dbFile.path}");

    if (!await dbFile.exists()) {
      debugPrint("❌ [EmbeddingCache] user_db.json 없음");
      return [];
    }

    try {
      final dbContent = await dbFile.readAsString();
      final userDB = jsonDecode(dbContent) as Map<String, dynamic>;

      final userIds = userDB.keys.toList();
      debugPrint("✅ [EmbeddingCache] 등록된 사용자 ID: $userIds");

      return userIds;
    } catch (e) {
      debugPrint("❌ [EmbeddingCache] user_db.json 파싱 실패: $e");
      return [];

      /*final userIds = <String>{};
      for (final f in faceDir.listSync().whereType<File>()) {
        final filename = f.uri.pathSegments.last;
        if (!filename.endsWith('.json')) continue;

        final idPart = filename.split('_').first;
        if (idPart.length < 3 || idPart == 'tmp' || idPart == 'user') continue;
        userIds.add(idPart);
      }
      return userIds.toList();*/
    }
  }
}