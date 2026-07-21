import 'package:cucumber_expressions/cucumber_expressions.dart';

void main() {
  final expression = ExpressionFactory(
    ParameterTypeRegistry(),
  ).createExpression('I have {int} cukes');

  final arguments = expression.match('I have 24 cukes');
  print('I have ${arguments?.first.getValue()} cukes.');
}
