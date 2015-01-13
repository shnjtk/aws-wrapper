# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aws-wrapper/version'

Gem::Specification.new do |spec|
  spec.name          = "aws-wrapper"
  spec.version       = AwsWrapper::VERSION
  spec.authors       = ["Shinji Takae"]
  spec.email         = ["shnjtk@gmail.com"]
  spec.summary       = %q{aws-sdk wrapper.}
  spec.description   = %q{aws-sdk wrapper.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
