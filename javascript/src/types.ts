import Argument from './Argument.js'
import ParameterType from './ParameterType'

export interface DefinesParameterType {
  defineParameterType<T>(parameterType: ParameterType<T>): void
}

export interface Expression {
  readonly source: string
  match(text: string): readonly Argument[] | null
}
