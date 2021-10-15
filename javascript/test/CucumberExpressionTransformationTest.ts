import assert from 'assert'
import fs from 'fs'
import glob from 'glob'
import yaml from 'js-yaml'

import CucumberExpression from '../src/CucumberExpression.js'
import ParameterTypeRegistry from '../src/ParameterTypeRegistry.js'
import { testDataDir } from './testDataDir.js'

type Expectation = {
  expression: string
  expected_regex: string
}

describe('CucumberExpression', () => {
  for (const path of glob.sync(`${testDataDir}/cucumber-expression/transformation/*.yaml`)) {
    const expectation = yaml.load(fs.readFileSync(path, 'utf-8')) as Expectation
    it(`transforms ${path}`, () => {
      const parameterTypeRegistry = new ParameterTypeRegistry()
      const expression = new CucumberExpression(expectation.expression, parameterTypeRegistry)
      assert.deepStrictEqual(expression.regexp.source, expectation.expected_regex)
    })
  }
})
