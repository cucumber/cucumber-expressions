import React from 'react'
import { render } from 'react-dom'
import { BrowserRouter as Router, Route } from 'react-router-dom'
import { QueryParamProvider } from 'use-query-params'

import { Try } from './Try'

render(
  <Router>
    <QueryParamProvider ReactRouterRoute={Route}>
      <Try
        defaultExpressionText={'there are {int} flights from {airport}'}
        defaultStepText={'there are 12 flights from LHR'}
        defaultParameters={[
          { name: 'airport', regexp: '[A-Z]{3}' },
          { name: 'person', regexp: '[A-Z][a-z]+' },
        ]}
      />
    </QueryParamProvider>
  </Router>,
  document.querySelector('#try')
)
