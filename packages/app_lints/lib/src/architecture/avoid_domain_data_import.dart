import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

class AvoidDomainDataImport extends AnalysisRule {
  AvoidDomainDataImport()
    : super(
        name: 'avoid_domain_data_import',
        description:
            'The domain layer must not import the data layer; this violates Clean Architecture dependency direction.',
      );

  static const LintCode code = LintCode(
    'avoid_domain_data_import',
    'The domain layer must not import the data layer; this violates Clean Architecture dependency direction.',
    correctionMessage:
        'Define a Repository interface (abstract class) in domain and implement it in the data layer instead.',
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
    if (uri.contains('/data/')) {
      rule.reportAtNode(node);
    }
  }
}
