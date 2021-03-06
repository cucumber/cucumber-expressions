import GeneratedExpression from './GeneratedExpression.js'
import ParameterType from './ParameterType.js'

// 256 generated expressions ought to be enough for anybody
const MAX_EXPRESSIONS = 256

export default class CombinatorialGeneratedExpressionFactory {
  constructor(
    private readonly expressionTemplate: string,
    private readonly parameterTypeCombinations: Array<Array<ParameterType<unknown>>>
  ) {
    this.expressionTemplate = expressionTemplate
  }

  public generateExpressions(): readonly GeneratedExpression[] {
    const generatedExpressions: GeneratedExpression[] = []
    this.generatePermutations(generatedExpressions, 0, [])
    return generatedExpressions
  }

  private generatePermutations(
    generatedExpressions: GeneratedExpression[],
    depth: number,
    currentParameterTypes: Array<ParameterType<unknown>>
  ) {
    if (generatedExpressions.length >= MAX_EXPRESSIONS) {
      return
    }

    if (depth === this.parameterTypeCombinations.length) {
      generatedExpressions.push(
        new GeneratedExpression(this.expressionTemplate, currentParameterTypes)
      )
      return
    }

    // tslint:disable-next-line:prefer-for-of
    for (let i = 0; i < this.parameterTypeCombinations[depth].length; ++i) {
      // Avoid recursion if no elements can be added.
      if (generatedExpressions.length >= MAX_EXPRESSIONS) {
        return
      }

      const newCurrentParameterTypes = currentParameterTypes.slice() // clone
      newCurrentParameterTypes.push(this.parameterTypeCombinations[depth][i])
      this.generatePermutations(generatedExpressions, depth + 1, newCurrentParameterTypes)
    }
  }
}
