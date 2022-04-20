import Argument from './Argument.js'
import { Node } from './ast.js'
import CucumberExpressionParser from './CucumberExpressionParser.js'
import ParameterType from './ParameterType.js'
import ParameterTypeRegistry from './ParameterTypeRegistry.js'
import RegExpCompiler from './RegExpCompiler.js'
import TreeRegexp from './TreeRegexp.js'
import { Expression } from './types.js'

export default class CucumberExpression implements Expression {
  private readonly parameterTypes: Array<ParameterType<unknown>> = []
  private readonly treeRegexp: TreeRegexp
  public readonly ast: Node

  /**
   * @param expression
   * @param parameterTypeRegistry
   */
  constructor(
    private readonly expression: string,
    private readonly parameterTypeRegistry: ParameterTypeRegistry
  ) {
    const parser = new CucumberExpressionParser()
    this.ast = parser.parse(expression)
    const compiler = new RegExpCompiler(expression, parameterTypeRegistry, this.parameterTypes)
    const pattern = compiler.compile(this.ast)
    this.treeRegexp = new TreeRegexp(pattern)
  }

  public match(text: string): readonly Argument[] | null {
    const group = this.treeRegexp.match(text)
    if (!group) {
      return null
    }
    return Argument.build(group, this.parameterTypes)
  }

  get regexp(): RegExp {
    return this.treeRegexp.regexp
  }

  get source(): string {
    return this.expression
  }
}
