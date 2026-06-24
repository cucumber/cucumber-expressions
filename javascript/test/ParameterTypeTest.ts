import * as assert from 'node:assert'

import ParameterType from '../src/ParameterType.js'
import ParameterTypeRegistry from '../src/ParameterTypeRegistry.js'

describe('ParameterType', () => {
  it('does not allow ignore flag on regexp', () => {
    assert.throws(
      () => new ParameterType('case-insensitive', /[a-z]+/i, String, (s) => s, true, true),
      { message: "ParameterType Regexps can't use flag 'i'" }
    )
  })

  it('has a type name for {int}', () => {
    const r = new ParameterTypeRegistry()
    const t = r.lookupByTypeName('int')!
    // @ts-expect-error
    assert.strictEqual(t.type.name, 'Number')
  })

  it('has a type name for {bigint}', () => {
    const r = new ParameterTypeRegistry()
    const t = r.lookupByTypeName('biginteger')!
    // @ts-expect-error
    assert.strictEqual(t.type.name, 'BigInt')
  })

  it('has a type name for {word}', () => {
    const r = new ParameterTypeRegistry()
    const t = r.lookupByTypeName('word')!
    // @ts-expect-error
    assert.strictEqual(t.type.name, 'String')
  })
})
