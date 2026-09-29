# frozen_string_literal: true

require 'cucumber/cucumber_expressions/errors'

module Cucumber
  module CucumberExpressions
    class ParameterType
      ILLEGAL_PARAMETER_NAME_PATTERN = /([\[\]()$.|?*+])/.freeze
      UNESCAPE_PATTERN = /(\\([\[$.|?*+\]]))/.freeze

      attr_reader :name, :type, :transformer, :use_for_snippets, :prefer_for_regexp_match, :regexps

      def self.check_parameter_type_name(type_name)
        raise CucumberExpressionError.new("Illegal character in parameter name {#{type_name}}. Parameter names may not contain '[]()$.|?*+'") unless valid_parameter_type_name?(type_name)
      end

      def self.valid_parameter_type_name?(type_name)
        unescaped_type_name = type_name.gsub(UNESCAPE_PATTERN) { Regexp.last_match(2) }
        !(ILLEGAL_PARAMETER_NAME_PATTERN.match?(unescaped_type_name))
      end

      # Create a new ParameterType
      #
      # @param name [String] the name of the parameter type
      # @param regexp [Array, Regexp] list of regexps for capture groups. A single regexp can also be used
      # @param type [Object] the return type of the transformed
      # @param transformer [Proc] lambda that transforms a String to (possibly) another type
      # @param use_for_snippets [Boolean] true if this should be used for snippet generation
      # @param prefer_for_regexp_match [Boolean] true if this should be preferred over similar types
      #
      def initialize(name, regexp, type, transformer, use_for_snippets = false, prefer_for_regexp_match = false)
        self.class.check_parameter_type_name(name) unless name.nil?
        @name = name
        @type = type
        @transformer = transformer
        @use_for_snippets = use_for_snippets
        @prefer_for_regexp_match = prefer_for_regexp_match
        @regexps = string_array(regexp)
      end

      def transform(self_obj, group_values)
        self_obj.instance_exec(*group_values, &@transformer)
      end

      def <=>(other)
        return -1 if prefer_for_regexp_match && !other.prefer_for_regexp_match
        return 1 if other.prefer_for_regexp_match && !prefer_for_regexp_match

        name <=> other.name
      end

      private

      def string_array(regexps)
        array = regexps.is_a?(Array) ? regexps : [regexps]
        array.map { |regexp| regexp.is_a?(String) ? regexp : regexp_source(regexp) }
      end

      def regexp_source(regexp)
        [
          'EXTENDED',
          'IGNORECASE',
          'MULTILINE'
        ].each do |option_name|
          option = Regexp.const_get(option_name)
          raise CucumberExpressionError.new("ParameterType Regexps can't use option Regexp::#{option_name}") if regexp.options & option != 0
        end
        regexp.source
      end
    end
  end
end
