# frozen_string_literal: true

require 'yaml'
require 'cucumber/cucumber_expressions/cucumber_expression_parser'
require 'cucumber/cucumber_expressions/errors'

module Cucumber
  module CucumberExpressions
    describe CucumberExpressionParser do
      Dir['../testdata/cucumber-expression/parser/*.yaml'].each do |path|
        expectation = YAML.load_file(path)
        it "parses #{path}" do
          parser = described_class.new
          if expectation['exception']
            expect { parser.parse(expectation['expression']) }.to raise_error(expectation['exception'])
          else
            node = parser.parse(expectation['expression'])
            node_hash = node.to_hash
            expect(node_hash).to eq(expectation['expected_ast'])
          end
        end
      end
    end
  end
end
