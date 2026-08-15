import 'package:flutter_travel_audio_guide/features/home/domain/entities/home_state.dart';

class OpenTimeResult {
  const OpenTimeResult({
    required this.status,
    required this.badgeText,
    required this.reasonText,
    required this.isOpenNow,
    required this.closeHour,
    required this.closeMinute,
  });

  factory OpenTimeResult.uncertain() {
    return const OpenTimeResult(
      status: RecommendStatus.uncertain,
      badgeText: '時間待確認',
      reasonText: '營業時間請以現場公告為準',
      isOpenNow: false,
      closeHour: null,
      closeMinute: null,
    );
  }
  final RecommendStatus status;
  final String badgeText;
  final String? reasonText;
  final bool isOpenNow;
  final int? closeHour;
  final int? closeMinute;
}

class OpenTimeParser {
  const OpenTimeParser();

  OpenTimeResult parse(String openTime, DateTime now) {
    final text = openTime.trim();
    if (text.isEmpty) {
      return OpenTimeResult.uncertain();
    }
    if (_isUncertainText(text)) {
      return OpenTimeResult.uncertain();
    }
    if (_isAlwaysOpen(text)) {
      return const OpenTimeResult(
        status: RecommendStatus.alwaysOpen,
        badgeText: '全天開放',
        reasonText: '全天開放・適合彈性安排',
        isOpenNow: true,
        closeHour: null,
        closeMinute: null,
      );
    }
    if (_isClosedToday(text, now)) {
      return const OpenTimeResult(
        status: RecommendStatus.uncertain,
        badgeText: '今日可能休館',
        reasonText: '今日可能休館，建議出發前再次確認',
        isOpenNow: false,
        closeHour: null,
        closeMinute: null,
      );
    }
    final range = _extractTimeRange(text);
    if (range == null) {
      return OpenTimeResult.uncertain();
    }
    final start = range.$1;
    final end = range.$2;
    final startMinutes = start.$1 * 60 + start.$2;
    final endMinutes = end.$1 * 60 + end.$2;
    final nowMinutes = now.hour * 60 + now.minute;
    final isOverMidnight = endMinutes <= startMinutes;
    final isOpen = isOverMidnight
        ? nowMinutes >= startMinutes || nowMinutes <= endMinutes
        : nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    if (!isOpen) {
      return OpenTimeResult(
        status: RecommendStatus.uncertain,
        badgeText: '${_formatTime(start)} 開始',
        reasonText: '目前未在可解析的開放時段內',
        isOpenNow: false,
        closeHour: end.$1,
        closeMinute: end.$2,
      );
    }
    return OpenTimeResult(
      status: RecommendStatus.openUntil,
      badgeText: '至 ${_formatTime(end)}',
      reasonText: _buildRemainingText(now, end.$1, end.$2),
      isOpenNow: true,
      closeHour: end.$1,
      closeMinute: end.$2,
    );
  }

  bool _isAlwaysOpen(String text) {
    return text.contains('全天') ||
        text.contains('24小時') ||
        text.contains('24 小時');
  }

  bool _isUncertainText(String text) {
    return text.contains('各店家營業時間不同') ||
        text.contains('以店家公告為準') ||
        text.contains('以現場公告為準') ||
        text.contains('詳見官網') ||
        text.contains('請參考最新消息');
  }

  bool _isClosedToday(String text, DateTime now) {
    final weekdayText = _weekdayText(now.weekday);
    return text.contains('$weekdayText固定休館') ||
        text.contains('$weekdayText休館') ||
        text.contains('$weekdayText公休');
  }

  String _weekdayText(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return '週一';
      case DateTime.tuesday:
        return '週二';
      case DateTime.wednesday:
        return '週三';
      case DateTime.thursday:
        return '週四';
      case DateTime.friday:
        return '週五';
      case DateTime.saturday:
        return '週六';
      case DateTime.sunday:
        return '週日';
      default:
        return '';
    }
  }

  ((int, int), (int, int))? _extractTimeRange(String text) {
    final normalized = text
        .replaceAll('：', ':')
        .replaceAll('－', '-')
        .replaceAll('–', '-')
        .replaceAll('~', '-')
        .replaceAll('至', '-')
        .replaceAll('凌晨0時', '00:00')
        .replaceAll('下午5時', '17:00')
        .replaceAll('時', ':00');
    final regex = RegExp(r'(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})');
    final match = regex.firstMatch(normalized);
    if (match == null) return null;
    final startHour = int.tryParse(match.group(1) ?? '');
    final startMinute = int.tryParse(match.group(2) ?? '');
    final endHour = int.tryParse(match.group(3) ?? '');
    final endMinute = int.tryParse(match.group(4) ?? '');
    if (startHour == null ||
        startMinute == null ||
        endHour == null ||
        endMinute == null) {
      return null;
    }
    return ((startHour, startMinute), (endHour, endMinute));
  }

  String _formatTime((int, int) time) {
    final hour = time.$1.toString().padLeft(2, '0');
    final minute = time.$2.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String? _buildRemainingText(DateTime now, int closeHour, int closeMinute) {
    var closeTime = DateTime(
      now.year,
      now.month,
      now.day,
      closeHour,
      closeMinute,
    );
    if (closeTime.isBefore(now)) {
      closeTime = closeTime.add(const Duration(days: 1));
    }
    final diff = closeTime.difference(now);
    if (diff.inMinutes <= 0) return null;
    if (diff.inHours >= 1) {
      return '剩 ${diff.inHours} 小時關閉';
    }
    return '剩 ${diff.inMinutes} 分鐘關閉';
  }
}
