import 'package:analyzer/analysis_rule/rule_context.dart';

/// Get the full file path of the file currently being analyzed from RuleContext.
String currentFilePath(RuleContext context) {
  final path = context.currentUnit?.file.path ?? '';

  return path.replaceAll(r'\', '/');
}

/// Determine whether the given file path belongs to test code.
bool isTestFilePath(String path) {
  final normalizedPath = path.replaceAll(r'\', '/');

  return normalizedPath.contains('/test/') ||
      normalizedPath.contains('/integration_test/');
}

/// Find the feature name from paths like `features/{feature}/...`.
final _featureReg = RegExp('(?:^|/)features/([^/]+)/');

/// Extract the feature name; returns null if the path is not under a feature.
String? featureNameOf(String path) => _featureReg.firstMatch(path)?.group(1);
