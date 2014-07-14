# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'yard_types/version'

Gem::Specification.new do |spec|
  spec.name          = "yard_types"
  spec.version       = YardTypes::VERSION
  spec.authors       = ["Kyle Hargraves"]
  spec.email         = ["pd@krh.me"]
  spec.summary       = %q{Parse and validate objects against YARD type descriptions.}
  spec.description   = %q{Your API docs say you return Array<#to_date>, but do you really?}
  spec.homepage      = "https://github.com/pd/yard_types"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "~> 0.7.1"
  spec.add_development_dependency "pry", "> 0"
end
