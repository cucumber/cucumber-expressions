import React, { useMemo, useState } from 'react'

import {
  Argument,
  CucumberExpression,
  CucumberExpressionGenerator,
  GeneratedExpression,
  ParameterTypeRegistry,
} from '../src/index'

type ExpressionResult = {
  expression?: CucumberExpression
  error?: Error
}

type MatchResult = {
  args?: readonly Argument[] | null
  generatedExpressions?: readonly GeneratedExpression[]
}

export const Try: React.FunctionComponent = () => {
  const reg = useMemo(() => new ParameterTypeRegistry(), [])
  const gen = useMemo(() => new CucumberExpressionGenerator(() => reg.parameterTypes), [reg])
  const [src, setSrc] = useState('I have {int} cukes in my {word')
  const [text, setText] = useState('I have 42 cukes in my belly')
  const result = useMemo<ExpressionResult>(() => {
    try {
      return { expression: new CucumberExpression(src, reg) }
    } catch (error) {
      return { error }
    }
  }, [src])
  const matchResult = useMemo<MatchResult>(() => {
    const args = result.expression?.match(text)
    if (args) {
      return { args }
    } else {
      return { generatedExpressions: gen.generateExpressions(text) }
    }
  }, [result, text])

  return (
    <div className="grid grid-cols-1 gap-4">
      <label className="block">
        <span className="text-gray-700">Cucumber Expression</span>
        <input
          type="text"
          className="mt-1 block w-full"
          value={src}
          onChange={(e) => setSrc(e.target.value)}
        />
      </label>

      {result.expression && <pre>/{result.expression.regexp.source}/</pre>}
      {result.error && <pre className="p-2 border-4 border-red-500">{result.error.message}</pre>}

      <label className="block">
        <span className="text-gray-700">Step text</span>
        <input
          type="text"
          className="mt-1 block w-full"
          value={text}
          onChange={(e) => setText(e.target.value)}
        />
      </label>

      {matchResult.args && (
        <div>
          <span className="text-gray-700">Arguments</span>
          <ol className="list-decimal list-inside">
            {matchResult.args.map((arg, i) => (
              <li key={i}>{arg.getValue(null)}</li>
            ))}
          </ol>
        </div>
      )}
      {matchResult.generatedExpressions && (
        <div>
          <span className="text-gray-700">Arguments</span>
          <ul className="list-disc list-inside">
            {matchResult.generatedExpressions.map((generatedExpression, i) => (
              <li key={i}>{generatedExpression.source}</li>
            ))}
          </ul>
        </div>
      )}
    </div>
  )
}
