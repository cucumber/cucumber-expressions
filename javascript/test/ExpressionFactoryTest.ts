import * as assert from 'assert'

import { describe, beforeEach, it } from 'minispec'

import CucumberExpression from '../src/CucumberExpression.js'
import ExpressionFactory from '../src/ExpressionFactory.js'
import ParameterTypeRegistry from '../src/ParameterTypeRegistry.js'
import RegularExpression from '../src/RegularExpression.js'

describe('ExpressionFactory', async () => {
  let expressionFactory: ExpressionFactory
  beforeEach(async () => {
    expressionFactory = new ExpressionFactory(new ParameterTypeRegistry())
  })

  it('creates a RegularExpression', async () => {
    assert.strictEqual(expressionFactory.createExpression(/x/).constructor, RegularExpression)
  })

  it('creates a CucumberExpression', async () => {
    assert.strictEqual(expressionFactory.createExpression('x').constructor, CucumberExpression)
  })
})
