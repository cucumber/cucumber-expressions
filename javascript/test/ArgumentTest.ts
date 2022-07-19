import * as assert from 'assert'

import { describe, it } from 'minispec'

import Argument from '../src/Argument.js'
import ParameterTypeRegistry from '../src/ParameterTypeRegistry.js'
import TreeRegexp from '../src/TreeRegexp.js'

describe('Argument', async () => {
  it('exposes getParameterTypeName()', async () => {
    const treeRegexp = new TreeRegexp('three (.*) mice')
    const parameterTypeRegistry = new ParameterTypeRegistry()
    const group = treeRegexp.match('three blind mice')!
    const args = Argument.build(group, [parameterTypeRegistry.lookupByTypeName('string')!])
    const argument = args[0]
    assert.strictEqual(argument.getParameterType().name, 'string')
  })
})
