import CucumberExpression from './CucumberExpression'
import type ParameterTypeRegistry from './ParameterTypeRegistry'
import RegularExpression from './RegularExpression'
import type { Expression } from './types'

export default class ExpressionFactory {
  public constructor(private readonly parameterTypeRegistry: ParameterTypeRegistry) {}

  public createExpression(expression: string | RegExp): Expression {
    return typeof expression === 'string'
      ? new CucumberExpression(expression, this.parameterTypeRegistry)
      : new RegularExpression(expression, this.parameterTypeRegistry)
  }
}
