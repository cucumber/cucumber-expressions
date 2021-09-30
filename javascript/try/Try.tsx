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

type Props = {
  initialExpressionText: string
  initialStepText: string
  initialRegistry: ParameterTypeRegistry
}

export const Try: React.FunctionComponent<Props> = ({
  initialExpressionText,
  initialStepText,
  initialRegistry,
}) => {
  const [expressionText, setExpressionText] = useState(initialExpressionText)
  const [stepText, setStepText] = useState(initialStepText)
  const [registry, setRegistry] = useState(initialRegistry)

  const generator = useMemo(
    () => new CucumberExpressionGenerator(() => registry.parameterTypes),
    [registry]
  )

  const expressionResult = useMemo<ExpressionResult>(() => {
    try {
      return { expression: new CucumberExpression(expressionText, registry) }
    } catch (error) {
      return { error }
    }
  }, [expressionText, registry])

  const args = useMemo(
    () => expressionResult.expression?.match(stepText),
    [expressionResult, stepText]
  )

  const generatedExpressions = useMemo(() => {
    return generator.generateExpressions(stepText)
  }, [stepText, generator])

  return (
    <div className="grid grid-cols-3 gap-6">
      <div>
        <Registry registry={registry} setRegistry={setRegistry} />
      </div>
      <div className="col-span-2">
        <CucumberExpressionInput value={expressionText} setValue={setExpressionText} />
        <ErrorComponent message={expressionResult.error?.message} />
        <StepTextInput value={stepText} setValue={setStepText} />
        <Args args={args} />
        <GeneratedCucumberExpressions generatedExpressions={generatedExpressions} />
        <RegularExpression cucumberExpression={expressionResult.expression} />
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
    return <ErrorComponent message="No match" />
  }
}

const RegularExpression: React.FunctionComponent<{ cucumberExpression?: CucumberExpression }> = ({
  cucumberExpression,
}) => {
  if (!cucumberExpression) return null
  return (
    <pre className="mt-1 mb-4 p-2 whitespace-pre-line border border-gray-500 bg-gray-100 ">
      /{cucumberExpression.regexp.source}/
    </pre>
  )
}

const ErrorComponent: React.FunctionComponent<{ message?: string }> = ({ message }) => {
  if (!message) return null
  return (
    <pre className="mt-1 mb-4 p-2 whitespace-pre-line border border-red-500 bg-red-100">
      {message}
    </pre>
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

const Registry: React.FunctionComponent<{
  registry: ParameterTypeRegistry
  setRegistry: Dispatch<SetStateAction<ParameterTypeRegistry>>
}> = ({ registry, setRegistry }) => {
  const parameterTypes = [...registry.parameterTypes]
  const builtin = parameterTypes.filter((p) => isBuiltIn(p))
  const custom = parameterTypes.filter((p) => !isBuiltIn(p))
  return (
    <div className="mb-4">
      <span className="text-gray-700">Parameter Types</span>
      <div className="table w-full border-collapse border border-gray-500 mt-1">
        <div className="table-row-group">
          <div className="table-row">
            <div className="table-cell border border-gray-500 bg-gray-100 p-2">Name</div>
            <div className="table-cell border border-gray-500 bg-gray-100 p-2">Regexp</div>
          </div>
          {builtin.map((parameterType) => (
            <ReadOnlyParameterType parameterType={parameterType} key={parameterType.name || ''} />
          ))}
          {custom.map((parameterType, i) => (
            <EditableParameterType
              registry={registry}
              setRegistry={setRegistry}
              index={i}
              key={i}
            />
          ))}
          <EditableParameterType registry={registry} setRegistry={setRegistry} index={-1} />
        </div>
      </div>
    </div>
  )
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
  registry: ParameterTypeRegistry
  setRegistry: Dispatch<SetStateAction<ParameterTypeRegistry>>
  index: number
}> = ({ registry, setRegistry, index }) => {
  const custom = [...registry.parameterTypes].filter((p) => !isBuiltIn(p))

  const [name, setName] = useState(custom[index]?.name || '')
  const [regexp, setRegexp] = useState(custom[index]?.regexpStrings[0] || '')

  function tryUpdateParameterType(n: string, r: string) {
    try {
      // This can fail
      const newParameterType = makeParameterType(n, new RegExp(r))

      if (index === -1) {
        custom.push(newParameterType)
        setName('')
        setRegexp('')
      } else {
        custom.splice(index, 1, newParameterType)
      }
      const newRegistry = new ParameterTypeRegistry()
      for (const parameterType of custom) {
        // This can fail
        newRegistry.defineParameterType(parameterType)
      }

      setRegistry(newRegistry)
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
          onChange={(e) => {
            setName(e.target.value)
            tryUpdateParameterType(e.target.value, regexp)
          }}
        />
      </div>
      <div className="table-cell">
        <input
          type="text"
          className="block w-full"
          value={regexp}
          onChange={(e) => {
            setRegexp(e.target.value)
            tryUpdateParameterType(name, e.target.value)
          }}
        />
      </div>
    </div>
  )
}

export function makeParameterType(name: string, regexp: RegExp): ParameterType<unknown> {
  return new ParameterType(
    name,
    regexp,
    undefined,
    (...args) => (args.length === 1 ? args[0] : args),
    true,
    false
  )
}

function isBuiltIn(parameterType: ParameterType<unknown>): boolean {
  return ['int', 'float', 'word', 'string', ''].includes(parameterType.name || '')
}
