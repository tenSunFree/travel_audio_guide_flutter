import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:app_lints/src/path_utils.dart';

/// The presentation layer should obtain data only via the domain (UseCase / Repository interfaces)
/// and DI (provider assembly), and must not directly touch data layer RemoteDataSource / Model / RepositoryImpl.
class AvoidPresentationDataImport extends AnalysisRule {
  AvoidPresentationDataImport()
    : super(
        name: 'avoid_presentation_data_import',
        description:
            'The presentation layer must not import the data layer directly.',
      );

  static const LintCode code = LintCode(
    'avoid_presentation_data_import',
    'The presentation layer must not import the data layer directly.',
    correctionMessage:
        'Access data via domain UseCase / Repository interfaces instead.',
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
    // Do not apply the production Clean Architecture dependency rule to test code.
    if (isTestFilePath(path)) {
      return;
    }
    if (!path.contains('/presentation/')) {
      return;
    }
    final uri = node.uri.stringValue ?? '';
    if (uri.contains('/data/')) {
      rule.reportAtNode(node);
    }
  }
}
