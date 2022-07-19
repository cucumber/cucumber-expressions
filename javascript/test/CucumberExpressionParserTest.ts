import assert from 'assert'
import fs from 'fs'
import glob from 'glob'
import yaml from 'js-yaml'
import { describe, it } from 'minispec'

import CucumberExpressionError from '../src/CucumberExpressionError.js'
import CucumberExpressionParser from '../src/CucumberExpressionParser.js'
import { testDataDir } from './testDataDir.js'

type Expectation = {
  expression: string
  expected_ast?: unknown
  exception?: string
}

describe('CucumberExpressionParser', async () => {
  for (const path of glob.sync(`${testDataDir}/cucumber-expression/parser/*.yaml`)) {
    const expectation = yaml.load(fs.readFileSync(path, 'utf-8')) as Expectation
    it(`parses ${path}`, async () => {
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
  }
})
