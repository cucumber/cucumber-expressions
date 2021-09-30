import React from 'react'
import { render } from 'react-dom'

import { ParameterTypeRegistry } from '../src'
import { makeParameterType, Try } from './Try'

const registry = new ParameterTypeRegistry()
registry.defineParameterType(makeParameterType('airport', /[A-Z]{3}/))
registry.defineParameterType(makeParameterType('person', /[A-Z][a-z]+/))

render(
  <Try
    initialExpressionText={'there are {int} flights from {airport}'}
    initialStepText={'there are 12 flights from LHR'}
    initialRegistry={registry}
  />,
  document.querySelector('#try')
)
