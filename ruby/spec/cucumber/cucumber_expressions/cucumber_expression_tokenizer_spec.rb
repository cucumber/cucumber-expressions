# frozen_string_literal: true

require 'yaml'
require 'cucumber/cucumber_expressions/cucumber_expression_tokenizer'
require 'cucumber/cucumber_expressions/errors'

module Cucumber
  module CucumberExpressions
    describe CucumberExpressionTokenizer do
      Dir['../testdata/cucumber-expression/tokenizer/*.yaml'].each do |path|
        expectation = YAML.load_file(path)
        it "tokenizes #{path}" do
          tokenizer = described_class.new
          if expectation['exception']
            expect { tokenizer.tokenize(expectation['expression']) }.to raise_error(expectation['exception'])
          else
            tokens = tokenizer.tokenize(expectation['expression'])
            token_hashes = tokens.map { |token| token.to_hash }
            expect(token_hashes).to eq(expectation['expected_tokens'])
          end
        end
      end
    end
  end
end
