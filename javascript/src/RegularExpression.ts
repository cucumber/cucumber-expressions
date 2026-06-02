import Argument from './Argument'
import ParameterType from './ParameterType'
import type ParameterTypeRegistry from './ParameterTypeRegistry'
import TreeRegexp from './TreeRegexp'
import type { Expression } from './types'

export default class RegularExpression implements Expression {
  private readonly treeRegexp: TreeRegexp

  constructor(
    public readonly regexp: RegExp,
    private readonly parameterTypeRegistry: ParameterTypeRegistry
  ) {
    this.treeRegexp = new TreeRegexp(regexp)
  }

  public match(text: string): readonly Argument[] | null {
    const group = this.treeRegexp.match(text)
    if (!group) {
      return null
    }

    const parameterTypes = this.treeRegexp.groupBuilder.children.map((groupBuilder) => {
      const parameterTypeRegexp = groupBuilder.source

      const parameterType = this.parameterTypeRegistry.lookupByRegexp(
        parameterTypeRegexp,
        this.regexp,
        text
      )
      return (
        parameterType ||
        new ParameterType(
          undefined,
          parameterTypeRegexp,
          String,
          (s) => (s === undefined ? null : s),
          false,
          false
        )
      )
    })

    return Argument.build(group, parameterTypes)
  }

  get source(): string {
    return this.regexp.source
  }
}
