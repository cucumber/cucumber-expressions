import assert from 'assert'
import fs from 'fs'
import yaml from 'js-yaml'

import CucumberExpressionError from '../src/CucumberExpressionError.js'
import CucumberExpressionTokenizer from '../src/CucumberExpressionTokenizer.js'
import { testDataDir } from './testDataDir.js'

type TokenExpectation = {
  expression: string
  expected_tokens?: unknown
  exception?: string
}

describe('Cucumber expression tokenizer', () => {
  fs.readdirSync(`${testDataDir}/tokens`).forEach((testcase) => {
    const testCaseData = fs.readFileSync(`${testDataDir}/tokens/${testcase}`, 'utf-8')
    const expectation = yaml.load(testCaseData) as TokenExpectation
    it(`${testcase}`, () => {
      const tokenizer = new CucumberExpressionTokenizer()
      if (expectation.expected_tokens !== undefined) {
        const tokens = tokenizer.tokenize(expectation.expression)
        assert.deepStrictEqual(
          JSON.parse(JSON.stringify(tokens)), // Removes type information.
          expectation.expected_tokens
        )
      } else if (expectation.exception !== undefined) {
        assert.throws(() => {
          tokenizer.tokenize(expectation.expression)
        }, new CucumberExpressionError(expectation.exception))
      } else {
        throw new Error(
          `Expectation must have expected_tokens or exception: ${JSON.stringify(expectation)}`
        )
      }
    })
  })
})
