# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require './lib/sumo_control/version'

Gem::Specification.new do |spec|
  spec.name          = "sumo_control"
  spec.version       = SumoControl::VERSION
  spec.authors       = ["Tobias Macey", "Christopher Patti"]
  spec.email         = ["tmacey@gazelle.com", "cpatti@gazelle.com"]
  spec.description   = "Gem for interfacing with sumo logic for source management"
  spec.summary       = "Gem for interfacing with sumo logic for source management"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "pry-debugger"

  spec.add_runtime_dependency "faraday", '~> 0.8.0'
  spec.add_runtime_dependency "json"
end
