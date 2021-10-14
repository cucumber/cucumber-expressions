import assert from 'assert'
import fs from 'fs'
import yaml from 'js-yaml'

import CucumberExpressionError from '../src/CucumberExpressionError.js'
import CucumberExpressionParser from '../src/CucumberExpressionParser.js'
import { testDataDir } from './testDataDir.js'

type AstExpectation = {
  expression: string
  expected_ast?: unknown
  exception?: string
}

describe('Cucumber expression parser', () => {
  fs.readdirSync(`${testDataDir}/ast`).forEach((testcase) => {
    const testCaseData = fs.readFileSync(`${testDataDir}/ast/${testcase}`, 'utf-8')
    const expectation = yaml.load(testCaseData) as AstExpectation
    it(`${testcase}`, () => {
      const parser = new CucumberExpressionParser()
      if (expectation.expected_ast !== undefined) {
        const node = parser.parse(expectation.expression)
        assert.deepStrictEqual(
          JSON.parse(JSON.stringify(node)), // Removes type information.
          expectation.expected_ast
        )
      } else if (expectation.exception !== undefined) {
        assert.throws(() => {
          parser.parse(expectation.expression)
        }, new CucumberExpressionError(expectation.exception))
      } else {
        throw new Error(
          `Expectation must have expected or exception: ${JSON.stringify(expectation)}`
        )
      }
    })
  })
})
