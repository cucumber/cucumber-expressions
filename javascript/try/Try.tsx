import { Switch } from '@headlessui/react'
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
  const [showBuiltins, setShowBuiltins] = useState(false)

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
        <Registry
          registry={registry}
          setRegistry={setRegistry}
          showBuiltins={showBuiltins}
          setShowBuiltins={setShowBuiltins}
        />
      </div>
      <div className="col-span-2">
        <CucumberExpressionInput value={expressionText} setValue={setExpressionText} />
        <RegularExpression cucumberExpression={expressionResult.expression} />
        <ErrorComponent message={expressionResult.error?.message} />
        <StepTextInput value={stepText} setValue={setStepText} />
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
  registry: ParameterTypeRegistry
  setRegistry: Dispatch<SetStateAction<ParameterTypeRegistry>>
  showBuiltins: boolean
  setShowBuiltins: Dispatch<SetStateAction<boolean>>
}> = ({ registry, setRegistry, showBuiltins, setShowBuiltins }) => {
  const parameterTypes = [...registry.parameterTypes]
  const builtin = parameterTypes.filter((p) => isBuiltIn(p))
  const custom = parameterTypes.filter((p) => !isBuiltIn(p))
  custom.push(makeParameterType('', /./))
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
            builtin.map((parameterType) => (
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
      if (n === '') {
        custom.splice(index, 1)
      } else {
        // This can fail
        const newParameterType = makeParameterType(n, new RegExp(r))

        if (index === -1) {
          custom.push(newParameterType)
          setName('')
          setRegexp('')
        } else {
          custom.splice(index, 1, newParameterType)
        }
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
