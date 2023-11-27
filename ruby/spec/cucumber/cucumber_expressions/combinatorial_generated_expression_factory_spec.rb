# frozen_string_literal: true

require 'cucumber/cucumber_expressions/parameter_type'
require 'cucumber/cucumber_expressions/combinatorial_generated_expression_factory'

describe Cucumber::CucumberExpressions::CombinatorialGeneratedExpressionFactory do
  let(:color) { Class.new }
  let(:css_color) { Class.new }
  let(:date) { Class.new }
  let(:date_time) { Class.new }
  let(:timestamp) { Class.new }

  it 'generates multiple expressions' do
    parameter_type_combinations = [
      [
        Cucumber::CucumberExpressions::ParameterType.new('color', /red|blue|yellow/, color, ->(_) { color.new }, true, false),
        Cucumber::CucumberExpressions::ParameterType.new('csscolor', /red|blue|yellow/, css_color, ->(_) { css_color.new }, true, false)
      ],
      [
        Cucumber::CucumberExpressions::ParameterType.new('date', /\d{4}-\d{2}-\d{2}/, date, ->(_) { date.new }, true, false),
        Cucumber::CucumberExpressions::ParameterType.new('datetime', /\d{4}-\d{2}-\d{2}/, date_time, ->(_) { date_time.new }, true, false),
        Cucumber::CucumberExpressions::ParameterType.new('timestamp', /\d{4}-\d{2}-\d{2}/, timestamp, ->(_) { timestamp.new }, true, false)
      ]
    ]

    factory = described_class.new(
      'I bought a {%s} ball on {%s}',
      parameter_type_combinations
    )
    expressions = factory.generate_expressions.map { |ge| ge.source }
    expect(expressions).to eq([
      'I bought a {color} ball on {date}',
      'I bought a {color} ball on {datetime}',
      'I bought a {color} ball on {timestamp}',
      'I bought a {csscolor} ball on {date}',
      'I bought a {csscolor} ball on {datetime}',
      'I bought a {csscolor} ball on {timestamp}',
    ])
  end
end
