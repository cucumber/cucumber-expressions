import 'package:cucumber_expressions/src/argument.dart';
import 'package:cucumber_expressions/src/ast.dart';
import 'package:cucumber_expressions/src/cucumber_expression_parser.dart';
import 'package:cucumber_expressions/src/errors.dart';
import 'package:cucumber_expressions/src/expression.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';
import 'package:cucumber_expressions/src/parameter_type_lookup.dart';
import 'package:cucumber_expressions/src/parameter_type_registry.dart';
import 'package:cucumber_expressions/src/tree_regexp.dart';

final RegExp _escapePattern = RegExp(r'([\\^\[({$.|?*+})\]])');

class CucumberExpression implements Expression {
  CucumberExpression(this._expression, this._parameterTypeRegistry) {
    final parser = CucumberExpressionParser();
    final ast = parser.parse(_expression);
    final pattern = _rewriteToRegex(ast);
    _treeRegexp = TreeRegexp.fromString(pattern);
  }

  final String _expression;
  final ParameterTypeRegistry _parameterTypeRegistry;
  final List<ParameterType<Object?>> _parameterTypes = [];
  late final TreeRegexp _treeRegexp;

  String _rewriteToRegex(Node node) {
    switch (node.type) {
      case NodeType.text:
        return _escapeRegex(node.text());
      case NodeType.optional:
        return _rewriteOptional(node);
      case NodeType.alternation:
        return _rewriteAlternation(node);
      case NodeType.alternative:
        return _rewriteAlternative(node);
      case NodeType.parameter:
        return _rewriteParameter(node);
      case NodeType.expression:
        return _rewriteExpression(node);
    }
  }

  static String _escapeRegex(String expression) {
    return expression.replaceAllMapped(
      _escapePattern,
      (m) => '\\${m.group(1)}',
    );
  }

  String _rewriteOptional(Node node) {
    _assertNoParameters(
      node,
      (astNode) => createParameterIsNotAllowedInOptional(astNode, _expression),
    );
    _assertNoOptionals(
      node,
      (astNode) => createOptionalIsNotAllowedInOptional(astNode, _expression),
    );
    _assertNotEmpty(
      node,
      (astNode) => createOptionalMayNotBeEmpty(astNode, _expression),
    );
    final regex = (node.nodes ?? []).map(_rewriteToRegex).join();
    return '(?:$regex)?';
  }

  String _rewriteAlternation(Node node) {
    for (final alternative in node.nodes ?? <Node>[]) {
      final altNodes = alternative.nodes;
      if (altNodes == null || altNodes.isEmpty) {
        throw createAlternativeMayNotBeEmpty(alternative, _expression);
      }
      _assertNotEmpty(
        alternative,
        (astNode) => createAlternativeMayNotExclusivelyContainOptionals(
          astNode,
          _expression,
        ),
      );
    }
    final regex = (node.nodes ?? []).map(_rewriteToRegex).join('|');
    return '(?:$regex)';
  }

  String _rewriteAlternative(Node node) {
    return (node.nodes ?? []).map(_rewriteToRegex).join();
  }

  String _rewriteParameter(Node node) {
    final name = node.text();
    final parameterType = lookupParameterTypeByName(
      _parameterTypeRegistry,
      name,
    );
    if (parameterType == null) {
      throw createUndefinedParameterType(node, _expression, name);
    }
    _parameterTypes.add(parameterType);
    final regexps = parameterType.regexpStrings;
    if (regexps.length == 1) {
      return '(${regexps[0]})';
    }
    return '((?:${regexps.join(')|(?:')}))';
  }

  String _rewriteExpression(Node node) {
    final regex = (node.nodes ?? []).map(_rewriteToRegex).join();
    return '^$regex\$';
  }

  void _assertNotEmpty(
    Node node,
    CucumberExpressionException Function(Node astNode) createException,
  ) {
    final textNodes =
        (node.nodes ?? []).where((astNode) => NodeType.text == astNode.type);
    if (textNodes.isEmpty) {
      throw createException(node);
    }
  }

  void _assertNoParameters(
    Node node,
    CucumberExpressionException Function(Node astNode) createException,
  ) {
    final parameterNodes = (node.nodes ?? [])
        .where((astNode) => NodeType.parameter == astNode.type)
        .toList();
    if (parameterNodes.isNotEmpty) {
      throw createException(parameterNodes[0]);
    }
  }

  void _assertNoOptionals(
    Node node,
    CucumberExpressionException Function(Node astNode) createException,
  ) {
    final optionalNodes = (node.nodes ?? [])
        .where((astNode) => NodeType.optional == astNode.type)
        .toList();
    if (optionalNodes.isNotEmpty) {
      throw createException(optionalNodes[0]);
    }
  }

  @override
  List<Argument<Object?>>? match(String text) {
    final group = _treeRegexp.match(text);
    if (group == null) {
      return null;
    }
    return buildArguments(group, _parameterTypes);
  }

  @override
  RegExp get regexp => _treeRegexp.regexp;

  @override
  String get source => _expression;
}
