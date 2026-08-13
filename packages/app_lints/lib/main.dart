import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:app_lints/src/architecture/avoid_cross_feature_import.dart';
import 'package:app_lints/src/architecture/avoid_domain_data_import.dart';
import 'package:app_lints/src/architecture/avoid_domain_flutter_import.dart';
import 'package:app_lints/src/architecture/avoid_presentation_data_import.dart';
import 'package:app_lints/src/conventions/avoid_debug_print.dart';
import 'package:app_lints/src/conventions/usecase_naming_convention.dart';

/// Dart Analysis Server looks for a top-level variable named `plugin` as the plugin entry point.
final plugin = AppLintsPlugin();

class AppLintsPlugin extends Plugin {
  @override
  String get name => 'app_lints';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerLintRule(AvoidDomainDataImport())
      ..registerLintRule(AvoidDomainFlutterImport())
      ..registerLintRule(AvoidCrossFeatureImport())
      ..registerLintRule(AvoidPresentationDataImport())
      ..registerLintRule(AvoidDebugPrint())
      ..registerLintRule(UsecaseNamingConvention());
  }
}
