import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AudioGuideLocalDataSource {
  const AudioGuideLocalDataSource();

  Future<Directory> _audioFolder() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(directory.path, 'audio_guides'));
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      return folder;
    } catch (e) {
      throw LocalStorageException('建立本地資料夾失敗：$e');
    }
  }

  Future<String> getAudioFilePath({
    required int id,
    required String title,
  }) async {
    final folder = await _audioFolder();
    final filename = _buildFileName(id: id, title: title);
    return p.join(folder.path, filename);
  }

  Future<bool> existsPath(String path) async {
    try {
      return File(path).exists();
    } catch (e) {
      throw LocalStorageException('檢查本地檔案失敗：$e');
    }
  }

  Future<void> writeBytes({
    required Uint8List bytes,
    required String path,
  }) async {
    try {
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      throw LocalStorageException('儲存本地檔案失敗：$e');
    }
  }

  String _buildFileName({required int id, required String title}) {
    final sanitizedTitle = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();

    final safeTitle = sanitizedTitle.isEmpty
        ? 'audio_$id'
        : '${id}_$sanitizedTitle';
    return '$safeTitle.mp3';
  }
}
