import 'package:dio/dio.dart';

/// Controls which API paths should be logged.
///
/// Paths added to [_blockedPaths] are excluded from console output.
class DioLogFilter {
  const DioLogFilter._();

  /// Paths that should not be logged.
  static const List<String> _blockedPaths = [
    // '/Media/Audio',
    // '/Events/Activity',
    // '/Attractions/All',
  ];

  static bool _shouldLog(String path) {
    return !_blockedPaths.any(path.contains);
  }

  static bool shouldLogRequest(RequestOptions options) =>
      _shouldLog(options.path);

  static bool shouldLogResponse(Response<dynamic> response) =>
      _shouldLog(response.requestOptions.path);

  static bool shouldLogError(DioException error) =>
      _shouldLog(error.requestOptions.path);
}
