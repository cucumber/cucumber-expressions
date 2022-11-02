import CucumberExpression, { CucumberExpressionJson } from './CucumberExpression.js'
import ParameterTypeRegistry from './ParameterTypeRegistry.js'
import RegularExpression, { RegularExpressionJson } from './RegularExpression.js'
import { Expression } from './types.js'

export default class ExpressionFactory {
  public constructor(private readonly parameterTypeRegistry: ParameterTypeRegistry) {}

  public createExpression(expression: string | RegExp): Expression {
    return typeof expression === 'string'
      ? new CucumberExpression(expression, this.parameterTypeRegistry)
      : new RegularExpression(expression, this.parameterTypeRegistry)
  }

  public createExpressionFromJson(json: CucumberExpressionJson | RegularExpressionJson) {
    switch (json.type) {
      case 'CucumberExpression':
        return new CucumberExpression(json.expression, this.parameterTypeRegistry)
      case 'RegularExpression':
        return new RegularExpression(
          new RegExp(json.expression, json.flags),
          this.parameterTypeRegistry
        )
    }
  }
}
