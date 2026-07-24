import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_playback_state.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/presentation/widgets/playback_card.dart';

void main() {
  group('PlaybackCard', () {
    testWidgets('初始狀態顯示標題與播放鍵，duration 為 0 時顯示 LinearProgressIndicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaybackCard(
              title: '測試導覽',
              playerState: const AudioPlaybackState(),
              onTogglePlayPause: () {},
              onSeek: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('測試導覽'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('loading 狀態顯示 CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaybackCard(
              title: '測試導覽',
              playerState: const AudioPlaybackState(
                status: AudioPlaybackStatus.loading,
              ),
              onTogglePlayPause: () {},
              onSeek: (_) {},
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('playing 狀態顯示 pause icon、時間與 Slider，拖動觸發 onSeek', (
      tester,
    ) async {
      Duration? sought;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaybackCard(
              title: '測試導覽',
              playerState: const AudioPlaybackState(
                status: AudioPlaybackStatus.playing,
                position: Duration(seconds: 30),
                duration: Duration(seconds: 120),
              ),
              onTogglePlayPause: () {},
              onSeek: (d) => sought = d,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.text('00:30'), findsOneWidget);
      expect(find.text('02:00'), findsOneWidget);
      await tester.drag(find.byType(Slider), const Offset(50, 0));
      await tester.pump();
      expect(sought, isNotNull);
    });

    testWidgets('點擊播放鍵呼叫 onTogglePlayPause', (tester) async {
      var toggled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaybackCard(
              title: '測試導覽',
              playerState: const AudioPlaybackState(
                status: AudioPlaybackStatus.paused,
                duration: Duration(seconds: 60),
              ),
              onTogglePlayPause: () => toggled = true,
              onSeek: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();
      expect(toggled, isTrue);
    });

    testWidgets('有 errorMessage 時顯示錯誤文字', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaybackCard(
              title: '測試導覽',
              playerState: const AudioPlaybackState(
                status: AudioPlaybackStatus.error,
                errorMessage: '播放失敗，請稍後再試',
              ),
              onTogglePlayPause: () {},
              onSeek: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('播放失敗，請稍後再試'), findsOneWidget);
    });
  });
}
