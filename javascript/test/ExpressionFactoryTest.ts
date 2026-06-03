import * as assert from 'node:assert'

import CucumberExpression from '../src/CucumberExpression'
import ExpressionFactory from '../src/ExpressionFactory'
import ParameterTypeRegistry from '../src/ParameterTypeRegistry'
import RegularExpression from '../src/RegularExpression'

describe('ExpressionFactory', () => {
  let expressionFactory: ExpressionFactory
  beforeEach(() => {
    expressionFactory = new ExpressionFactory(new ParameterTypeRegistry())
  })

  it('creates a RegularExpression', () => {
    assert.strictEqual(expressionFactory.createExpression(/x/).constructor, RegularExpression)
  })

  it('creates a CucumberExpression', () => {
    assert.strictEqual(expressionFactory.createExpression('x').constructor, CucumberExpression)
  })
})
