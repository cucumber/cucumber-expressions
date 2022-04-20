import Compiler from './Compiler.js'
import ParameterType from './ParameterType.js'
import ParameterTypeRegistry from './ParameterTypeRegistry'

const ESCAPE_PATTERN = () => /([\\^[({$.|?*+})\]])/g

export default class RegExpCompiler extends Compiler<string> {
  constructor(
    expression: string,
    parameterTypeRegistry: ParameterTypeRegistry,
    private readonly parameterTypes: Array<ParameterType<unknown>>
  ) {
    super(expression, parameterTypeRegistry)
  }

  protected produceText(expression: string) {
    return expression.replace(ESCAPE_PATTERN(), '\\$1')
  }

  protected produceOptional(segments: string[]): string {
    const regex = segments.join('')
    return `(?:${regex})?`
  }

  protected produceAlternation(segments: string[]): string {
    const regex = segments.join('|')
    return `(?:${regex})`
  }

  protected produceAlternative(segments: string[]): string {
    return segments.join('')
  }

  protected produceParameter(parameterType: ParameterType<unknown>): string {
    this.parameterTypes.push(parameterType)
    const regexps = parameterType.regexpStrings
    if (regexps.length == 1) {
      return `(${regexps[0]})`
    }
    return `((?:${regexps.join(')|(?:')}))`
  }

  protected produceExpression(segments: string[]): string {
    const regex = segments.join('')
    return `^${regex}$`
  }
}
