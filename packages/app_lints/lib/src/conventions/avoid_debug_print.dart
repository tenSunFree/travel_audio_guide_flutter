import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// The project provides `lib/core/utils/app_logger.dart`. Use it consistently so logs
/// can be collected by Talker and uploaded to Sentry. Avoid scattered use of print / debugPrint.
class AvoidDebugPrint extends AnalysisRule {
  AvoidDebugPrint()
    : super(
        name: 'avoid_debug_print',
        description: 'Avoid using print / debugPrint; use AppLogger instead.',
      );

  static const LintCode code = LintCode(
    'avoid_debug_print',
    'Avoid using print / debugPrint; use AppLogger instead.',
    correctionMessage:
        'Use the AppLogger provided by lib/core/utils/app_logger.dart instead.',
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry
      ..addMethodInvocation(this, visitor)
      ..addFunctionExpressionInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  static const _bannedNames = {
    'print',
    'debugPrint',
  };

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null && _bannedNames.contains(node.methodName.name)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitFunctionExpressionInvocation(
    FunctionExpressionInvocation node,
  ) {
    final function = node.function;
    if (function is SimpleIdentifier && _bannedNames.contains(function.name)) {
      rule.reportAtNode(node);
    }
  }
}
