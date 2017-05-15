# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require File.expand_path('../lib/sumo_control/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = 'sumo_control'
  spec.version       = SumoControl::VERSION
  spec.authors       = ['Jonathan Hosmer']
  spec.email         = ['jonathan@wink.com']
  spec.description   = 'Gem for interfacing with sumo logic for source management'
  spec.summary       = 'Gem wrapper of the SumoLogic API'
  spec.homepage      = 'https://github.com/winkapp/sumo_control'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.12', '>= 1.12.5'
  spec.add_development_dependency 'rspec', '~> 3.5', '>= 3.5.0'
  spec.add_development_dependency 'rake', '~> 10.1', '>= 10.1.1'
  spec.add_development_dependency 'vcr', '~> 3.0', '>= 3.0.3'

  spec.add_runtime_dependency 'faraday', '~> 0.8.0', '>= 0.8.11'
  spec.add_runtime_dependency 'json', '~> 1.8', '>= 1.8.3'
end
