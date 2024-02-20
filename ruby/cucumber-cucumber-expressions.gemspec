# -*- encoding: utf-8 -*-
# frozen_string_literal: true

version = File.read(File.expand_path('VERSION', __dir__)).strip

Gem::Specification.new do |s|
  s.name        = 'cucumber-cucumber-expressions'
  s.version     = version
  s.authors     = ['Aslak Hellesøy']
  s.description = 'Cucumber Expressions - a simpler alternative to Regular Expressions'
  s.summary     = "cucumber-expressions-#{s.version}"
  s.email       = 'cukes@googlegroups.com'
  s.homepage    = 'https://github.com/cucumber/cucumber-expressions'
  s.platform    = Gem::Platform::RUBY
  s.license     = 'MIT'
  s.required_ruby_version = '>= 2.5'

  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/cucumber/cucumber/issues',
    'changelog_uri' => 'https://github.com/cucumber/cucumber-expressions/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://github.com/cucumber/cucumber-expressions#readme',
    'mailing_list_uri' => 'https://community.smartbear.com/category/cucumber/discussions/cucumberos',
    'source_code_uri' => 'https://github.com/cucumber/cucumber-expressions/tree/main/ruby',
  }

  s.add_runtime_dependency 'bigdecimal'

  s.add_development_dependency 'rake', '~> 13.0', '>= 13.0.6'
  s.add_development_dependency 'rspec', '~> 3.11', '>= 3.11.0'
  s.add_development_dependency 'rubocop', '~> 1.27.0'
  s.add_development_dependency 'rubocop-performance', '~> 1.7.0'
  s.add_development_dependency 'rubocop-rake', '~> 0.5.0'
  s.add_development_dependency 'rubocop-rspec', '~> 2.0.0'

  s.files            = `git ls-files`.split("\n").reject { |path| path =~ /\.gitignore$/ }
  s.rdoc_options     = ['--charset=UTF-8']
  s.require_path     = 'lib'
end
