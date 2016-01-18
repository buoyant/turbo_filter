# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'turbo_filter/version'

Gem::Specification.new do |spec|
  spec.name          = "turbo_filter"
  spec.version       = TurboFilter::VERSION
  spec.authors       = ["Sandeep Kumar"]
  spec.email         = ["isandeepthota@gmail.com"]
  spec.description   = %q{Filtering ActiveRecord Results}
  spec.summary       = %q{Filter records}
  spec.homepage      = "https://github.com/buoyant/turbo_filter"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
