import assert from 'assert'

import CucumberExpression, { CucumberExpressionJson } from '../src/CucumberExpression.js'
import ExpressionFactory from '../src/ExpressionFactory.js'
import ParameterType from '../src/ParameterType.js'
import ParameterTypeRegistry, { ParameterTypeRegistryJson } from '../src/ParameterTypeRegistry.js'
import RegularExpression, { RegularExpressionJson } from '../src/RegularExpression.js'

describe('Serialization', () => {
  describe('ParameterTypeRegistry', () => {
    it('can be serialized', () => {
      const registry = new ParameterTypeRegistry()
      registry.defineParameterType(
        new ParameterType('color', /red|blue|yellow/, null, (s) => s, false, true)
      )
      const expected: ParameterTypeRegistryJson = {
        parameterTypes: [
          {
            name: 'color',
            regexpStrings: ['red|blue|yellow'],
            useForSnippets: false,
            preferForRegexpMatch: true,
            builtin: false,
          },
        ],
      }
      assert.deepStrictEqual(registry.toJSON(), expected)

      const registryFromJson = ParameterTypeRegistry.fromJSON(registry.toJSON())
      assert(registryFromJson.lookupByTypeName('color'))
    })
  })

  describe('ParameterType', () => {
    it('can be serialized', () => {
      const registry = new ParameterTypeRegistry()
      const expression = new CucumberExpression('hello', registry)
      const expected: CucumberExpressionJson = {
        type: 'CucumberExpression',
        expression: 'hello',
      }
      assert.deepStrictEqual(expression.toJSON(), expected)

      const factory = new ExpressionFactory(registry)
      assert.deepStrictEqual(factory.createExpressionFromJson(expected).toJSON(), expected)
    })
  })

  describe('CucumberExpression', () => {
    it('can be serialized', () => {
      const registry = new ParameterTypeRegistry()
      const expression = new CucumberExpression('hello', registry)
      const expected: CucumberExpressionJson = {
        type: 'CucumberExpression',
        expression: 'hello',
      }
      assert.deepStrictEqual(expression.toJSON(), expected)

      const factory = new ExpressionFactory(registry)
      assert.deepStrictEqual(factory.createExpressionFromJson(expected).toJSON(), expected)
    })
  })

  describe('RegularExpression', () => {
    it('can be serialized', () => {
      const registry = new ParameterTypeRegistry()
      const expression = new RegularExpression(/hello/i, registry)
      const expected: RegularExpressionJson = {
        type: 'RegularExpression',
        expression: 'hello',
        flags: 'i',
      }
      assert.deepStrictEqual(expression.toJSON(), expected)

      const factory = new ExpressionFactory(registry)
      assert.deepStrictEqual(factory.createExpressionFromJson(expected).toJSON(), expected)
    })
  })
})
