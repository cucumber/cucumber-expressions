import 'package:cucumber_expressions/src/ast.dart';
import 'package:cucumber_expressions/src/generated_expression.dart';
import 'package:cucumber_expressions/src/parameter_type.dart';

class CucumberExpressionException implements Exception {
  CucumberExpressionException(this.message);

  final String message;

  @override
  String toString() => message;
}

CucumberExpressionException createAlternativeMayNotExclusivelyContainOptionals(
  Node node,
  String expression,
) {
  return CucumberExpressionException(
    _message(
      node.start,
      expression,
      _pointAtLocated(node),
      'An alternative may not exclusively contain optionals',
      r"If you did not mean to use an optional you can use '\(' to escape the '('",
    ),
  );
}

CucumberExpressionException createAlternativeMayNotBeEmpty(
  Node node,
  String expression,
) {
  return CucumberExpressionException(
    _message(
      node.start,
      expression,
      _pointAtLocated(node),
      'Alternative may not be empty',
      r"If you did not mean to use an alternative you can use '\/' to escape the '/'",
    ),
  );
}

CucumberExpressionException createOptionalMayNotBeEmpty(
  Node node,
  String expression,
) {
  return CucumberExpressionException(
    _message(
      node.start,
      expression,
      _pointAtLocated(node),
      'An optional must contain some text',
      r"If you did not mean to use an optional you can use '\(' to escape the '('",
    ),
  );
}

CucumberExpressionException createParameterIsNotAllowedInOptional(
  Node node,
  String expression,
) {
  return CucumberExpressionException(
    _message(
      node.start,
      expression,
      _pointAtLocated(node),
      'An optional may not contain a parameter type',
      r"If you did not mean to use an parameter type you can use '\{' to escape the '{'",
    ),
  );
}

CucumberExpressionException createOptionalIsNotAllowedInOptional(
  Node node,
  String expression,
) {
  return CucumberExpressionException(
    _message(
      node.start,
      expression,
      _pointAtLocated(node),
      'An optional may not contain an other optional',
      r"If you did not mean to use an optional type you can use '\(' to escape the '('. For more complicated expressions consider using a regular expression instead.",
    ),
  );
}

CucumberExpressionException createTheEndOfLineCanNotBeEscaped(
  String expression,
) {
  final index = expression.runes.length - 1;
  return CucumberExpressionException(
    _message(
      index,
      expression,
      _pointAt(index),
      'The end of line can not be escaped',
      r"You can use '\\' to escape the '\'",
    ),
  );
}

CucumberExpressionException createMissingEndToken(
  String expression,
  TokenType beginToken,
  TokenType endToken,
  Token current,
) {
  final beginSymbol = symbolOf(beginToken);
  final endSymbol = symbolOf(endToken);
  final purpose = purposeOf(beginToken);
  return CucumberExpressionException(
    _message(
      current.start,
      expression,
      _pointAtLocated(current),
      "The '$beginSymbol' does not have a matching '$endSymbol'",
      "If you did not intend to use $purpose you can use '\\$beginSymbol' to escape the $purpose",
    ),
  );
}

CucumberExpressionException createAlternationNotAllowedInOptional(
  String expression,
  Token current,
) {
  return CucumberExpressionException(
    _message(
      current.start,
      expression,
      _pointAtLocated(current),
      'An alternation can not be used inside an optional',
      r"If you did not mean to use an alternation you can use '\/' to escape the '/'. Otherwise rephrase your expression or consider using a regular expression instead.",
    ),
  );
}

CucumberExpressionException createCantEscaped(String expression, int index) {
  return CucumberExpressionException(
    _message(
      index,
      expression,
      _pointAt(index),
      r"Only the characters '{', '}', '(', ')', '\', '/' and whitespace can be escaped",
      r"If you did mean to use an '\' you can use '\\' to escape it",
    ),
  );
}

CucumberExpressionException createInvalidParameterTypeNameInNode(
  Token token,
  String expression,
) {
  return CucumberExpressionException(
    _message(
      token.start,
      expression,
      _pointAtLocated(token),
      r"Parameter names may not contain '{', '}', '(', ')', '\' or '/'",
      'Did you mean to use a regular expression?',
    ),
  );
}

String _message(
  int index,
  String expression,
  String pointer,
  String problem,
  String solution,
) {
  return 'This Cucumber Expression has a problem at column ${index + 1}:'
      '\n\n'
      '$expression\n'
      '$pointer\n'
      '$problem.\n'
      '$solution';
}

String _pointAt(int index) {
  final pointer = <String>[];
  for (var i = 0; i < index; i++) {
    pointer.add(' ');
  }
  pointer.add('^');
  return pointer.join();
}

String _pointAtLocated(Located node) {
  final pointer = <String>[_pointAt(node.start)];
  if (node.start + 1 < node.end) {
    for (var i = node.start + 1; i < node.end - 1; i++) {
      pointer.add('-');
    }
    pointer.add('^');
  }
  return pointer.join();
}

class AmbiguousParameterTypeException extends CucumberExpressionException {
  AmbiguousParameterTypeException(super.message);

  static AmbiguousParameterTypeException forRegExp(
    String parameterTypeRegexp,
    RegExp expressionRegexp,
    List<ParameterType<Object?>> parameterTypes,
    List<GeneratedExpression> generatedExpressions,
  ) {
    return AmbiguousParameterTypeException(
      'Your Regular Expression /${expressionRegexp.pattern}/\n'
      'matches multiple parameter types with regexp $parameterTypeRegexp:\n'
      '   ${_parameterTypeNames(parameterTypes)}\n'
      '\n'
      "I couldn't decide which one to use. You have two options:\n"
      '\n'
      '1) Use a Cucumber Expression instead of a Regular Expression. Try one of these:\n'
      '   ${_expressions(generatedExpressions)}\n'
      '\n'
      '2) Make one of the parameter types preferential and continue to use a Regular Expression.\n',
    );
  }

  static String _parameterTypeNames(
    List<ParameterType<Object?>> parameterTypes,
  ) {
    return parameterTypes.map((p) => '{${p.name}}').join('\n   ');
  }

  static String _expressions(List<GeneratedExpression> generatedExpressions) {
    return generatedExpressions.map((e) => e.source).join('\n   ');
  }
}

class UndefinedParameterTypeException extends CucumberExpressionException {
  UndefinedParameterTypeException(
    this.undefinedParameterTypeName,
    super.message,
  );

  final String undefinedParameterTypeName;
}

UndefinedParameterTypeException createUndefinedParameterType(
  Node node,
  String expression,
  String undefinedParameterTypeName,
) {
  return UndefinedParameterTypeException(
    undefinedParameterTypeName,
    _message(
      node.start,
      expression,
      _pointAtLocated(node),
      "Undefined parameter type '$undefinedParameterTypeName'",
      "Please register a ParameterType for '$undefinedParameterTypeName'",
    ),
  );
}
