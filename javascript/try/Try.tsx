import React, { useMemo, useState } from 'react'

import { CucumberExpression, ParameterTypeRegistry } from '../src/index'

type Result = {
  expression?: CucumberExpression
  error?: Error
}

export const Try: React.FunctionComponent = () => {
  const reg = useMemo(() => new ParameterTypeRegistry(), [])
  const [src, setSrc] = useState('I have {int} cukes in my {word}')
  const [text, setText] = useState('I have 42 cukes in my belly')
  const result = useMemo<Result>(() => {
    try {
      return { expression: new CucumberExpression(src, reg) }
    } catch (error) {
      return { error }
    }
  }, [src])
  const args = useMemo(() => result.expression?.match(text), [result, text])

  return (
    <div>
      <h1>Try Cucumber Expressions yo</h1>
      <input type="text" value={src} onChange={(e) => setSrc(e.target.value)} />
      <pre>/{result.expression?.regexp.source || result.error?.message}/</pre>
      <br />
      <input type="text" value={text} onChange={(e) => setText(e.target.value)} />
      {(args && (
        <ol>
          {args.map((arg, i) => (
            <li key={i}>{arg.getValue(null)}</li>
          ))}
        </ol>
      )) || <div>No match</div>}
    </div>
  )
}
