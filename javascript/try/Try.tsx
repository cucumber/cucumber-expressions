import { Switch } from '@headlessui/react'
import React, { Dispatch, SetStateAction, useMemo, useState } from 'react'
import { BooleanParam, JsonParam, StringParam, useQueryParam, withDefault } from 'use-query-params'

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

type Parameter = {
  name: string
  regexp: string
}

type Props = {
  defaultExpressionText: string
  defaultStepText: string
  defaultParameters: readonly Parameter[]
}

export const Try: React.FunctionComponent<Props> = ({
  defaultExpressionText,
  defaultStepText,
  defaultParameters,
}) => {
  const [expressionText, setExpressionText] = useQueryParam(
    'expression',
    withDefault(StringParam, defaultExpressionText)
  )
  const [stepText, setStepText] = useQueryParam('step', withDefault(StringParam, defaultStepText))
  const [showBuiltins, setShowBuiltins] = useQueryParam(
    'showBuiltins',
    withDefault(BooleanParam, false)
  )
  const [parameters, setParameters] = useQueryParam<readonly Parameter[]>(
    'parameters',
    withDefault(JsonParam, defaultParameters)
  )

  const registry = useMemo(() => {
    const newRegistry = new ParameterTypeRegistry()
    for (const parameter of parameters) {
      try {
        newRegistry.defineParameterType(
          makeParameterType(parameter.name, new RegExp(parameter.regexp))
        )
      } catch (error) {
        // TODO: Set state to mark the parameter as problematic and render the error somehow
        console.error(error.message)
      }
    }
    return newRegistry
  }, [parameters])

  const builtinParameterTypes = useMemo(() => {
    const parameterTypes = [...registry.parameterTypes]
    return parameterTypes.filter((p) => isBuiltIn(p))
  }, [registry.parameterTypes])

  const generator = useMemo(
    () => new CucumberExpressionGenerator(() => registry.parameterTypes),
    [registry]
  )

  const expressionResult = useMemo<ExpressionResult>(() => {
    if (expressionText === null || expressionText === undefined) {
      return {}
    }
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
        <Registry
          builtinParameterTypes={builtinParameterTypes}
          showBuiltins={showBuiltins || false}
          setShowBuiltins={setShowBuiltins}
          parameters={parameters.concat([{ name: '', regexp: '' }])}
          setParameters={setParameters}
        />
      </div>
      <div className="col-span-2">
        <CucumberExpressionInput value={expressionText} setValue={setExpressionText} />
        <RegularExpression cucumberExpression={expressionResult.expression} />
        <ErrorComponent message={expressionResult.error?.message} />
        <StepTextInput value={stepText || ''} setValue={setStepText} />
        <Args args={args} />
        <GeneratedCucumberExpressions generatedExpressions={generatedExpressions} />
      </div>
    </div>
  )
}

const CucumberExpressionInput: React.FunctionComponent<{
  value: string
  setValue: Dispatch<SetStateAction<string>>
}> = ({ value, setValue }) => (
  <div className="mb-4">
    <label className="block">
      <Label>Cucumber Expression</Label>
      <input
        autoFocus={true}
        type="text"
        className="block w-full"
        value={value}
        onChange={(e) => setValue(e.target.value)}
      />
    </label>
  </div>
)

const StepTextInput: React.FunctionComponent<{
  value: string
  setValue: Dispatch<SetStateAction<string>>
}> = ({ value, setValue }) => (
  <div className="mb-4">
    <label className="block">
      <Label>Step Text</Label>
      <input
        type="text"
        className="block w-full"
        value={value}
        onChange={(e) => setValue(e.target.value)}
      />
    </label>
  </div>
)
const Args: React.FunctionComponent<{ args?: readonly Argument[] | null }> = ({ args }) => {
  if (Array.isArray(args)) {
    return (
      <div className="mb-4">
        <Label>Match</Label>
        <ol className="list-decimal list-inside p-2 border border-green-500 bg-green-100">
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
    <div className="mb-4">
      <Label>Regular Expression</Label>
      <pre className="p-2 whitespace-pre-wrap break-words border border-gray-500 bg-gray-100">
        /{cucumberExpression.regexp.source}/
      </pre>
    </div>
  )
}

const ErrorComponent: React.FunctionComponent<{ message?: string }> = ({ message }) => {
  if (!message) return null
  return (
    <div className="mb-4">
      <pre className="p-2 whitespace-pre-wrap break-words border border-red-500 bg-red-100">
        {message}
      </pre>
    </div>
  )
}

const GeneratedCucumberExpressions: React.FunctionComponent<{
  generatedExpressions: readonly GeneratedExpression[]
}> = ({ generatedExpressions }) => (
  <div className="mb-4">
    <Label>Cucumber Expressions that match Step Text</Label>
    <ul className="list-disc list-inside p-2 border border-gray-500 bg-gray-100">
      {generatedExpressions.map((generatedExpression, i) => (
        <li key={i}>{generatedExpression.source}</li>
      ))}
    </ul>
  </div>
)

const Registry: React.FunctionComponent<{
  builtinParameterTypes: readonly ParameterType<unknown>[]
  showBuiltins: boolean
  setShowBuiltins: Dispatch<SetStateAction<boolean>>
  parameters: readonly Parameter[]
  setParameters: Dispatch<SetStateAction<readonly Parameter[]>>
}> = ({ builtinParameterTypes, showBuiltins, setShowBuiltins, parameters, setParameters }) => {
  return (
    <div className="mb-4">
      <Label>
        Parameter Types{' '}
        <Switch
          checked={showBuiltins}
          onChange={setShowBuiltins}
          className={`${
            showBuiltins ? 'bg-blue-600' : 'bg-gray-200'
          } relative inline-flex items-center h-6 rounded-full w-11 float-right`}
        >
          <span
            className={`${
              showBuiltins ? 'translate-x-6' : 'translate-x-1'
            } inline-block w-4 h-4 transform transition ease-in-out duration-200 bg-white rounded-full`}
          />
        </Switch>
      </Label>
      <div className="table w-full border-collapse border border-gray-500">
        <div className="table-row-group">
          <div className="table-row">
            <div className="table-cell border border-gray-500 bg-gray-100 p-2">Name</div>
            <div className="table-cell border border-gray-500 bg-gray-100 p-2">Regexp</div>
          </div>
          {showBuiltins &&
            builtinParameterTypes.map((parameterType) => (
              <ReadOnlyParameterType parameterType={parameterType} key={parameterType.name || ''} />
            ))}
          {parameters.map((parameterType, i) => (
            <EditableParameterType
              parameters={parameters}
              setParameters={setParameters}
              index={i}
              key={i}
            />
          ))}
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
  parameters: readonly Parameter[]
  setParameters: Dispatch<SetStateAction<readonly Parameter[]>>
  index: number
}> = ({ parameters, setParameters, index }) => {
  const [name, setName] = useState(parameters[index]?.name || '')
  const [regexp, setRegexp] = useState(parameters[index]?.regexp || '')

  function tryUpdateParameterType(n: string, r: string) {
    const newParameters = parameters.slice()
    newParameters.splice(index, 1, { name: n, regexp: r })
    const ps = newParameters.filter((p) => p.name !== '')
    setParameters(ps)
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

const Label: React.FunctionComponent = ({ children }) => (
  <div className="mb-1 text-gray-700">{children}</div>
)

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
