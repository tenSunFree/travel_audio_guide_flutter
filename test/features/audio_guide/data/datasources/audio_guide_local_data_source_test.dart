import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/datasources/audio_guide_local_data_source.dart';

/// Use a fake PathProviderPlatform to redirect the application's documents
/// directory to a temporary test folder. This avoids touching the real device
/// file system and also avoids mocking dart:io's File/Directory.
class FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  FakePathProviderPlatform(this.basePath);

  final String basePath;

  @override
  Future<String?> getApplicationDocumentsPath() async => basePath;
}

void main() {
  late Directory tempDir;
  late AudioGuideLocalDataSource dataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'audio_guide_local_ds_test_',
    );
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    dataSource = const AudioGuideLocalDataSource();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AudioGuideLocalDataSource.getAudioFilePath', () {
    test('會自動建立 audio_guides 資料夾，並回傳 id_標題.mp3 的路徑', () async {
      final path = await dataSource.getAudioFilePath(id: 1, title: '故宮導覽');

      expect(path, endsWith('1_故宮導覽.mp3'));
      expect(await Directory('${tempDir.path}/audio_guides').exists(), isTrue);
    });

    test('標題含有不合法的檔名字元時，每個字元會被替換成底線', () async {
      final path = await dataSource.getAudioFilePath(
        id: 2,
        title: '故宮:導覽/測試*檔名',
      );
      expect(path, endsWith('2_故宮_導覽_測試_檔名.mp3'));
    });

    test('標題中間的連續空白會被壓縮成單一底線', () async {
      final path = await dataSource.getAudioFilePath(id: 3, title: '台北 101');
      expect(path, endsWith('3_台北_101.mp3'));
    });

    test('標題整理後仍非空（例如純空白）時，不會觸發 fallback 檔名', () async {
      // Note: a string containing only whitespace will become a single "_"
      // after replacing \s+, so it is not an empty string. Therefore the
      // fallback branch that produces "audio_<id>" will not be triggered —
      // this is the intended behavior of the implementation and this test
      // protects this easily-misunderstood detail.
      final path = await dataSource.getAudioFilePath(id: 4, title: '   ');
      expect(path, endsWith('4__.mp3'));
    });

    test('標題為完全空字串時，改用 audio_<id> 當檔名', () async {
      final path = await dataSource.getAudioFilePath(id: 5, title: '');
      expect(path, endsWith('audio_5.mp3'));
    });
  });

  group('AudioGuideLocalDataSource.existsPath / writeBytes', () {
    test('寫入後 existsPath 回傳 true，且內容正確', () async {
      final path = await dataSource.getAudioFilePath(id: 1, title: '測試');
      expect(await dataSource.existsPath(path), isFalse);
      final bytes = Uint8List.fromList([1, 2, 3]);
      await dataSource.writeBytes(bytes: bytes, path: path);
      expect(await dataSource.existsPath(path), isTrue);
      expect(await File(path).readAsBytes(), bytes);
    });

    test('路徑不存在時，existsPath 回傳 false', () async {
      final exists = await dataSource.existsPath(
        '${tempDir.path}/not_exist.mp3',
      );
      expect(exists, isFalse);
    });
  });
}
