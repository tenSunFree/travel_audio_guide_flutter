import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Global Logger singleton, the entire app shares the same Talker instance.
class AppLogger {
  AppLogger._();

  static final Talker talker = TalkerFlutter.init(
    settings: TalkerSettings(),
  );

  static void debug(Object? message) {
    if (kDebugMode) talker.debug(message);
  }

  static void info(Object? message) {
    if (kDebugMode) talker.info(message);
  }

  static void warning(Object? message) {
    if (kDebugMode) talker.warning(message);
  }

  static void error(
    Object? message, {
    Object? exception,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      if (exception != null || stackTrace != null) {
        talker.handle(exception ?? message!, stackTrace, message?.toString());
      } else {
        talker.error(message);
      }
    }
  }

  /// Prints formatted JSON, suitable for printing API response.data
  static void json(Object? data, {String tag = 'JSON'}) {
    if (!kDebugMode) return;
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(data);
      talker.debug('[$tag]\n$prettyJson');
    } catch (e, st) {
      talker.handle(e, st, 'AppLogger.json parse failed');
      talker.debug('[$tag] $data');
    }
  }
}
