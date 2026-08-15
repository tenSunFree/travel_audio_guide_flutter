import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// The domain layer should remain pure Dart and should not depend on the Flutter framework.
class AvoidDomainFlutterImport extends AnalysisRule {
  AvoidDomainFlutterImport()
    : super(
        name: 'avoid_domain_flutter_import',
        description:
            'The domain layer must not depend on the Flutter framework.',
      );

  static const LintCode code = LintCode(
    'avoid_domain_flutter_import',
    'The domain layer must not depend on the Flutter framework.',
    correctionMessage:
        'Move Flutter-specific types or logic to the presentation/infrastructure layers.',
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
    if (!path.contains('/domain/')) {
      return;
    }
    final uri = node.uri.stringValue ?? '';
    if (uri.startsWith('package:flutter/')) {
      rule.reportAtNode(node);
    }
  }
}
