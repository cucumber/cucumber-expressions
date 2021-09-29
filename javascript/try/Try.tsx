import React, { Dispatch, SetStateAction, useMemo, useState } from 'react'

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
  const [expressionText, setExpressionText] = useState('there are {int} flights from {airport}')
  const [stepText, setStepText] = useState('there are 12 flights from LHR')
  const expressionResult = useMemo<ExpressionResult>(() => {
    try {
      return { expression: new CucumberExpression(expressionText, reg) }
    } catch (error) {
      return { error }
    }
  }, [expressionText, reg])
  const matchResult = useMemo<MatchResult>(() => {
    const generatedExpressions = gen.generateExpressions(stepText)
    const args = expressionResult.expression?.match(stepText)
    return { args, generatedExpressions }
  }, [expressionResult, stepText])

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
    <div className="grid grid-cols-3 gap-6">
      <div>
        <ParameterTypes
          parameterTypes={[...reg.parameterTypes]}
          updateParameterType={updateParameterType}
        />
      </div>
      <div className="col-span-2">
        <CucumberExpressionInput value={expressionText} setValue={setExpressionText} />
        <StepTextInput value={stepText} setValue={setStepText} />
        <GeneratedCucumberExpressions generatedExpressions={matchResult.generatedExpressions} />
        <Args args={matchResult.args} />
        <EquivalentRegularExpression expressionResult={expressionResult} />
      </div>
    </div>
  )
}

const CucumberExpressionInput: React.FunctionComponent<{
  value: string
  setValue: Dispatch<SetStateAction<string>>
}> = ({ value, setValue }) => (
  <label className="block mb-4">
    <span className="text-gray-700">Cucumber Expression</span>
    <input
      type="text"
      className="mt-1 block w-full"
      value={value}
      onChange={(e) => setValue(e.target.value)}
    />
  </label>
)

const StepTextInput: React.FunctionComponent<{
  value: string
  setValue: Dispatch<SetStateAction<string>>
}> = ({ value, setValue }) => (
  <label className="block mb-4">
    <span className="text-gray-700">Step Text</span>
    <input
      type="text"
      className="mt-1 block w-full"
      value={value}
      onChange={(e) => setValue(e.target.value)}
    />
  </label>
)
const Args: React.FunctionComponent<{ args?: readonly Argument[] | null }> = ({ args }) => {
  if (Array.isArray(args)) {
    return (
      <div className="mb-4">
        <span className="text-gray-700">Match</span>
        <ol className="list-decimal list-inside">
          {args.map((arg, i) => (
            <li key={i}>{JSON.stringify(arg.getValue(null))}</li>
          ))}
        </ol>
      </div>
    )
  } else {
    return <div className="mb-4">No match</div>
  }
}

const EquivalentRegularExpression: React.FunctionComponent<{ expressionResult: ExpressionResult }> =
  ({ expressionResult }) => {
    return (
      <div className="mb-4">
        <span className="text-gray-700">Regular Expression</span>
        {expressionResult.expression && (
          <pre className="whitespace-pre-line border border-gray-500 mt-1 bg-gray-100 p-2">
            /{expressionResult.expression.regexp.source}/
          </pre>
        )}
        {expressionResult.error && (
          <pre className="p-2 border-4 border-red-500 whitespace-pre-line">
            {expressionResult.error.message}
          </pre>
        )}
      </div>
    )
  }

const GeneratedCucumberExpressions: React.FunctionComponent<{
  generatedExpressions: readonly GeneratedExpression[]
}> = ({ generatedExpressions }) => (
  <div className="mb-4">
    <span className="text-gray-700">Generated Cucumber Expressions</span>
    <ul className="list-disc list-inside">
      {generatedExpressions.map((generatedExpression, i) => (
        <li key={i}>{generatedExpression.source}</li>
      ))}
    </ul>
  </div>
)

const ParameterTypes: React.FunctionComponent<{
  parameterTypes: readonly ParameterType<unknown>[]
  updateParameterType: UpdateParameterType
}> = ({ parameterTypes, updateParameterType }) => (
  <div className="mb-4">
    <span className="text-gray-700">Parameter Types</span>
    <div className="table w-full border-collapse border border-gray-500 mt-1">
      <div className="table-row-group">
        <div className="table-row">
          <div className="table-cell border border-gray-500 bg-gray-100 p-2">Name</div>
          <div className="table-cell border border-gray-500 bg-gray-100 p-2">Regexp</div>
        </div>
        {parameterTypes.map((parameterType, i) => (
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
)

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
    <div className="table-cell border border-gray-500 bg-gray-100 p-2">{parameterType.name}</div>
    <div className="table-cell border border-gray-500 bg-gray-100 p-2">
      {parameterType.regexpStrings[0]}
    </div>
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
