# frozen_string_literal: true

require 'cucumber/cucumber_expressions/parameter_type'

module Cucumber
  module CucumberExpressions
    describe ParameterType do
      it 'does not allow ignore flag on regexp' do
        expect { described_class.new('case-insensitive', /[a-z]+/i, String, ->(s) { s }, true, true) }
          .to raise_error(
            CucumberExpressionError,
            "ParameterType Regexps can't use 'IGNORECASE' option"
          )
      end
    end
  end
end
