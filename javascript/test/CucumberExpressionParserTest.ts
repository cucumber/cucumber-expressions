import assert from 'assert'
import fs from 'fs'
import yaml from 'js-yaml'

import CucumberExpressionError from '../src/CucumberExpressionError.js'
import CucumberExpressionParser from '../src/CucumberExpressionParser.js'

interface Expectation {
  expression: string
  expected?: string
  exception?: string
}

describe('Cucumber expression parser', () => {
  fs.readdirSync('../testdata/ast').forEach((testcase) => {
    const testCaseData = fs.readFileSync(`../testdata/ast/${testcase}`, 'utf-8')
    const expectation = yaml.load(testCaseData) as Expectation
    it(`${testcase}`, () => {
      const parser = new CucumberExpressionParser()
      if (expectation.expected !== undefined) {
        const node = parser.parse(expectation.expression)
        assert.deepStrictEqual(
          JSON.parse(JSON.stringify(node)), // Removes type information.
          JSON.parse(expectation.expected)
        )
      } else if (expectation.exception !== undefined) {
        assert.throws(() => {
          parser.parse(expectation.expression)
        }, new CucumberExpressionError(expectation.exception))
      }
    })
  })
})
