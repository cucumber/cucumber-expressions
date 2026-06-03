import * as assert from 'node:assert'

import Argument from '../src/Argument'
import ParameterTypeRegistry from '../src/ParameterTypeRegistry'
import TreeRegexp from '../src/TreeRegexp'

describe('Argument', () => {
  it('exposes getParameterTypeName()', () => {
    const treeRegexp = new TreeRegexp('three (.*) mice')
    const parameterTypeRegistry = new ParameterTypeRegistry()
    const group = treeRegexp.match('three blind mice')!
    const args = Argument.build(group, [parameterTypeRegistry.lookupByTypeName('string')!])
    const argument = args[0]
    assert.strictEqual(argument.getParameterType().name, 'string')
  })
})
