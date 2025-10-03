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
  s.required_ruby_version = '>= 2.7'
  s.required_rubygems_version = '>= 3.2.8'

  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/cucumber/cucumber/issues',
    'changelog_uri' => 'https://github.com/cucumber/cucumber-expressions/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://github.com/cucumber/cucumber-expressions#readme',
    'mailing_list_uri' => 'https://community.smartbear.com/category/cucumber/discussions/cucumberos',
    'source_code_uri' => 'https://github.com/cucumber/cucumber-expressions/tree/main/ruby',
  }

  s.add_runtime_dependency 'bigdecimal'

  s.add_development_dependency 'rake', '~> 13.3'
  s.add_development_dependency 'rspec', '~> 3.13'
  s.add_development_dependency 'rubocop', '~> 1.55.0'
  s.add_development_dependency 'rubocop-performance', '~> 1.21.0'
  s.add_development_dependency 'rubocop-rake', '~> 0.6.0'
  s.add_development_dependency 'rubocop-rspec', '~> 3.0.0'

  s.files            = Dir['lib/**/*', 'CHANGELOG.md', 'CONTRIBUTING.md', 'LICENSE', 'README.md']
  s.rdoc_options     = ['--charset=UTF-8']
  s.require_path     = 'lib'
end
