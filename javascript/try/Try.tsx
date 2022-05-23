import { Switch } from '@headlessui/react'
import React, { Dispatch, ReactNode, SetStateAction, useMemo, useState } from 'react'
import { BooleanParam, JsonParam, StringParam, useQueryParam, withDefault } from 'use-query-params'

import {
  Argument,
  CucumberExpression,
  CucumberExpressionGenerator,
  GeneratedExpression,
  ParameterType,
  ParameterTypeRegistry,
} from '../src/index.js'
import { ExpressionEditor } from './codemirror/ExpressionEditor.js'
import { TextEditor } from './codemirror/TextEditor.js'
import { CopyButton } from './useCopyToClipboard.js'

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
  const [showAdvanced, setShowAdvanced] = useQueryParam(
    'advanced',
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
    <div>
      <CucumberExpressionInput
        value={expressionText}
        setValue={setExpressionText}
        error={expressionResult.error !== undefined}
      />
      <ErrorComponent message={expressionResult.error?.message} />
      <TextInput value={stepText} setValue={setStepText} args={args} />
      <div className="flex justify-end">
        <div className="py-2 pr-8">
          <span className="pr-2">Advanced</span>
          <Switch
            checked={showAdvanced}
            onChange={setShowAdvanced}
            className={`${
              showAdvanced ? 'bg-blue-600' : 'bg-gray-200'
            } relative float-right inline-flex h-6 w-11 items-center rounded-full`}
          >
            <span
              className={`${
                showAdvanced ? 'translate-x-6' : 'translate-x-1'
              } inline-block h-4 w-4 transform rounded-full bg-white transition duration-200 ease-in-out`}
            />
          </Switch>
        </div>

        <CopyButton
          copyStatusText={{
            inactive: 'Copy link',
            copied: 'Copied!',
            failed: 'Copy failed',
          }}
          copyText={() => window.location.href}
        />
      </div>

      {showAdvanced && (
        <>
          <RegularExpression cucumberExpression={expressionResult.expression} />
          <GeneratedCucumberExpressions generatedExpressions={generatedExpressions} />
          <Registry
            builtinParameterTypes={builtinParameterTypes}
            showBuiltins={true}
            parameters={parameters.concat([{ name: '', regexp: '' }])}
            setParameters={setParameters}
          />
        </>
      )}
    </div>
  )
}

const CucumberExpressionInput: React.FunctionComponent<{
  value: string
  setValue: Dispatch<SetStateAction<string>>
  error: boolean
}> = ({ value, setValue, error }) => (
  <div className="mb-4">
    <label className="block">
      <Label>Cucumber Expression</Label>
      <ExpressionEditor value={value} setValue={setValue} error={error} autoFocus={true} />
    </label>
  </div>
)

const TextInput: React.FunctionComponent<{
  value: string
  setValue: Dispatch<SetStateAction<string>>
  args: readonly Argument[] | null | undefined
}> = ({ value, setValue, args }) => {
  return (
    <div className="mb-4">
      <label className="block">
        <Label>Text</Label>
        <TextEditor value={value} setValue={setValue} args={args} autoFocus={false} />
      </label>
    </div>
  )
}

const RegularExpression: React.FunctionComponent<{ cucumberExpression?: CucumberExpression }> = ({
  cucumberExpression,
}) => {
  if (!cucumberExpression) return null
  return (
    <div className="mb-4">
      <Label>Regular Expression</Label>
      <pre className="whitespace-pre-wrap break-words border border-gray-500 bg-gray-100 p-2">
        /{cucumberExpression.regexp.source}/
      </pre>
    </div>
  )
}

const ErrorComponent: React.FunctionComponent<{ message?: string }> = ({ message }) => {
  if (!message) return null
  return (
    <div className="mb-4">
      <pre className="whitespace-pre-wrap break-words border border-red-500 bg-red-100 p-2">
        {message}
      </pre>
    </div>
  )
}

const GeneratedCucumberExpressions: React.FunctionComponent<{
  generatedExpressions: readonly GeneratedExpression[]
}> = ({ generatedExpressions }) => (
  <div className="mb-4">
    <Label>Other Cucumber Expressions that match Text</Label>
    <ul className="list-inside list-disc border border-gray-500 bg-gray-100 p-2">
      {generatedExpressions.map((generatedExpression, i) => (
        <li key={i}>{generatedExpression.source}</li>
      ))}
    </ul>
  </div>
)

const Registry: React.FunctionComponent<{
  builtinParameterTypes: readonly ParameterType<unknown>[]
  showBuiltins: boolean
  parameters: readonly Parameter[]
  setParameters: Dispatch<SetStateAction<readonly Parameter[]>>
}> = ({ builtinParameterTypes, showBuiltins, parameters, setParameters }) => {
  return (
    <div className="mb-4">
      <label className="block">
        <Label>Parameter Types</Label>
        <div className="table w-full border-collapse border border-gray-500">
          <div className="table-row-group">
            <div className="table-row">
              <div className="table-cell border border-gray-500 bg-gray-100 p-2">Name</div>
              <div className="table-cell border border-gray-500 bg-gray-100 p-2">Regexp</div>
            </div>
            {showBuiltins &&
              builtinParameterTypes.map((parameterType) => (
                <ReadOnlyParameterType
                  parameterType={parameterType}
                  key={parameterType.name || ''}
                />
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
        </div>{' '}
      </label>
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

const Label: React.FunctionComponent<{ children?: ReactNode }> = ({ children }) => (
  <div className="mb-1 text-gray-700">{children}</div>
)

export function makeParameterType(name: string, regexp: RegExp): ParameterType<unknown> {
  return new ParameterType(
    name,
    regexp,
    null,
    (...args) => (args.length === 1 ? args[0] : args),
    true,
    false
  )
}

function isBuiltIn(parameterType: ParameterType<unknown>): boolean {
  return ['int', 'float', 'word', 'string', ''].includes(parameterType.name || '')
}
