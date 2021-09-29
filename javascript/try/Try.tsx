import React, { useMemo, useState } from 'react'

import {
  Argument,
  CucumberExpression,
  CucumberExpressionGenerator,
  GeneratedExpression,
  ParameterType,
  ParameterTypeRegistry,
} from '../src/index'

type ExpressionResult = {
  expression?: CucumberExpression
  error?: Error
}

type MatchResult = {
  args?: readonly Argument[] | null
  generatedExpressions: readonly GeneratedExpression[]
}

type UpdateParameterType = (parameterType: ParameterType<unknown>, index: number) => void

function makeParameterType(name: string, regexp: RegExp) {
  return new ParameterType(
    name,
    regexp,
    undefined,
    (...args) => (args.length === 1 ? args[0] : args),
    false,
    false
  )
}

export const Try: React.FunctionComponent = () => {
  const [parameterTypes, setParameterTypes] = useState<ParameterType<unknown>[]>([
    makeParameterType('airport', /[A-Z]{3}/),
  ])
  const reg = useMemo(() => {
    const parameterTypeRegistry = new ParameterTypeRegistry()
    for (const parameterType of parameterTypes) {
      parameterTypeRegistry.defineParameterType(parameterType)
    }
    return parameterTypeRegistry
  }, [parameterTypes])
  const gen = useMemo(() => new CucumberExpressionGenerator(() => reg.parameterTypes), [reg])
  const [src, setSrc] = useState('I have {int} cukes in my {word}')
  const [text, setText] = useState('I have 42 cukes in my belly')
  const expressionResult = useMemo<ExpressionResult>(() => {
    try {
      return { expression: new CucumberExpression(src, reg) }
    } catch (error) {
      return { error }
    }
  }, [src, reg])
  const matchResult = useMemo<MatchResult>(() => {
    const generatedExpressions = gen.generateExpressions(text)
    const args = expressionResult.expression?.match(text)
    return { args, generatedExpressions }
  }, [expressionResult, text])

  const updateParameterType: UpdateParameterType = (
    parameterType: ParameterType<unknown>,
    index: number
  ) => {
    const newParameterTypes = parameterTypes.slice()
    if (index === -1) {
      newParameterTypes.push(parameterType)
    } else {
      newParameterTypes.splice(index, 1, parameterType)
    }
    setParameterTypes(newParameterTypes)
  }

  return (
    <div className="grid grid-cols-3 gap-4">
      <div className="col-span-2">
        <label className="block">
          <span className="text-gray-700">Cucumber Expression</span>
          <input
            type="text"
            className="mt-1 block w-full"
            value={src}
            onChange={(e) => setSrc(e.target.value)}
          />
        </label>

        {expressionResult.expression && <pre>/{expressionResult.expression.regexp.source}/</pre>}
        {expressionResult.error && (
          <pre className="p-2 border-4 border-red-500">{expressionResult.error.message}</pre>
        )}
      </div>
      <div>
        Parameter types
        <div className="table w-full border border-black border-collapse">
          <div className="table-row-group">
            <div className="table-row">
              <div className="table-cell border border-black p-2">Name</div>
              <div className="table-cell border border-black p-2">Regexp</div>
            </div>
            {[...reg.parameterTypes].map((parameterType, i) => (
              <ParameterTypeComponent
                parameterType={parameterType}
                updateParameterType={updateParameterType}
                index={5 - i}
                key={i}
              />
            ))}
            <EditableParameterType
              initialName={''}
              initialRegexp={''}
              updateParameterType={updateParameterType}
              index={-1}
            />
          </div>
        </div>
      </div>

      <div className="col-span-2">
        <label className="block">
          <span className="text-gray-700">Step text</span>
          <input
            type="text"
            className="mt-1 block w-full"
            value={text}
            onChange={(e) => setText(e.target.value)}
          />
        </label>
      </div>
      <div>
        {(Array.isArray(matchResult.args) && (
          <div>
            <span className="text-gray-700">Arguments</span>
            <ol className="list-decimal list-inside">
              {matchResult.args.map((arg, i) => (
                <li key={i}>{JSON.stringify(arg.getValue(null))}</li>
              ))}
            </ol>
          </div>
        )) || <div>No match</div>}
      </div>

      <div className="col-span-3">
        <span className="text-gray-700">Generated Cucumber Expressions</span>
        {matchResult.generatedExpressions && (
          <div>
            <ul className="list-disc list-inside">
              {matchResult.generatedExpressions.map((generatedExpression, i) => (
                <li key={i}>{generatedExpression.source}</li>
              ))}
            </ul>
          </div>
        )}
      </div>
    </div>
  )
}

const ParameterTypeComponent: React.FunctionComponent<{
  parameterType: ParameterType<unknown>
  updateParameterType: UpdateParameterType
  index: number
}> = ({ parameterType, updateParameterType, index }) => {
  const name = parameterType.name || ''
  if (['int', 'float', 'word', 'string', ''].includes(name)) {
    return <ReadOnlyParameterType parameterType={parameterType} />
  } else {
    return (
      <EditableParameterType
        initialName={name}
        initialRegexp={parameterType.regexpStrings[0]}
        updateParameterType={updateParameterType}
        index={index}
      />
    )
  }
}

const ReadOnlyParameterType: React.FunctionComponent<{ parameterType: ParameterType<unknown> }> = ({
  parameterType,
}) => (
  <div className="table-row">
    <div className="table-cell border border-black p-2">{parameterType.name}</div>
    <div className="table-cell border border-black p-2">{parameterType.regexpStrings[0]}</div>
  </div>
)

const EditableParameterType: React.FunctionComponent<{
  initialName: string
  initialRegexp: string
  updateParameterType: UpdateParameterType
  index: number
}> = ({ initialName, initialRegexp, updateParameterType, index }) => {
  const [name, setName] = useState(initialName)
  const [regexp, setRegexp] = useState(initialRegexp)

  function submitParameterType() {
    try {
      updateParameterType(makeParameterType(name, new RegExp(regexp)), index)
      if (index === -1) {
        setName('')
        setRegexp('')
      }
    } catch (error) {
      console.error(error.message)
    }
  }

  return (
    <div className="table-row">
      <div className="table-cell">
        <input
          type="text"
          className="block w-full"
          value={name}
          onChange={(e) => setName(e.target.value)}
          onKeyPress={(e) => {
            if (e.key === 'Enter') {
              submitParameterType()
            }
          }}
        />
      </div>
      <div className="table-cell">
        <input
          type="text"
          className="block w-full"
          value={regexp}
          onChange={(e) => setRegexp(e.target.value)}
          onKeyPress={(e) => {
            if (e.key === 'Enter') {
              submitParameterType()
            }
          }}
        />
      </div>
    </div>
  )
}
