# frozen_string_literal: true

require 'yaml'
require 'cucumber/cucumber_expressions/cucumber_expression'
require 'cucumber/cucumber_expressions/parameter_type_registry'

module Cucumber
  module CucumberExpressions
    describe CucumberExpression do
      Dir['../testdata/cucumber-expression/transformation/*.yaml'].each do |path|
        expectation = YAML.load_file(path)
        it "transforms #{path}" do
          parameter_registry = ParameterTypeRegistry.new
          if expectation['exception']
            expect {
              cucumber_expression = described_class.new(expectation['expression'], parameter_registry)
              cucumber_expression.match(expectation['text'])
            }.to raise_error(expectation['exception'])
          else
            cucumber_expression = described_class.new(expectation['expression'], parameter_registry)
            matches = cucumber_expression.match(expectation['text'])
            values = matches.nil? ? nil : matches.map { |arg| arg.value(nil) }
            expect(values).to eq(expectation['expected_args'])
          end
        end
      end
    end
  end
end
