import assert from 'assert'
import fs from 'fs'
import glob from 'glob'
import yaml from 'js-yaml'

import { describe, it } from 'minispec'

import CucumberExpressionError from '../src/CucumberExpressionError.js'
import CucumberExpressionTokenizer from '../src/CucumberExpressionTokenizer.js'
import { testDataDir } from './testDataDir.js'

type Expectation = {
  expression: string
  expected_tokens?: unknown
  exception?: string
}

describe('CucumberExpressionTokenizer', async () => {
  for (const path of glob.sync(`${testDataDir}/cucumber-expression/tokenizer/*.yaml`)) {
    const expectation = yaml.load(fs.readFileSync(path, 'utf-8')) as Expectation
    it(`tokenizes ${path}`, async () => {
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
  }
})
