import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:app_lints/src/path_utils.dart';

/// Different features should not depend on each other directly.
///
/// Shared logic should be moved down to `lib/core/`,
/// or integrated via domain abstractions / dependency injection.
class AvoidCrossFeatureImport extends AnalysisRule {
  AvoidCrossFeatureImport()
    : super(
        name: 'avoid_cross_feature_import',
        description: 'Different features must not import each other.',
      );

  static const LintCode code = LintCode(
    'avoid_cross_feature_import',
    'Different features must not import each other.',
    correctionMessage:
        'If logic must be shared, move it to lib/core/ or expose it via domain interfaces and assemble with DI.',
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addImportDirective(
      this,
      _Visitor(this),
    );
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitImportDirective(ImportDirective node) {
    final unit = node.thisOrAncestorOfType<CompilationUnit>();
    final path =
        unit?.declaredFragment?.source.fullName.replaceAll(r'\', '/') ?? '';
    // test / integration_test does not apply the production feature boundary.
    if (isTestFilePath(path)) {
      return;
    }
    final currentFeature = featureNameOf(path);
    // The source is not features/{feature}/..., no need to check.
    if (currentFeature == null) {
      return;
    }
    final uri = node.uri.stringValue ?? '';
    final importedFeature = featureNameOf(uri);
    if (importedFeature != null && importedFeature != currentFeature) {
      rule.reportAtNode(node);
    }
  }
}
