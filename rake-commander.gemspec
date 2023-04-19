lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rake-commander/version"

Gem::Specification.new do |spec|
  spec.name          = "rake-commander"
  spec.version       = RakeCommander::VERSION
  spec.authors       = ["Oscar Segura Samper"]
  spec.email         = ["oscar@ecoportal.co.nz"]

  spec.summary       = 'The classed version of rake with task options. Create re-usable tasks and samples.'
  spec.homepage      = "https://www.ecoportal.com"
  spec.licenses      = %w[MIT]

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.7.2'

  spec.add_development_dependency "bundler",   ">= 2.4.9",  "< 3"
  spec.add_development_dependency "rake",      ">= 13.0.6", "< 14"
  spec.add_development_dependency "redcarpet", ">= 3.6.0",  "< 4"
  spec.add_development_dependency "rspec",     ">= 3.10.0", "< 4"
  spec.add_development_dependency "yard",      ">= 0.9.34", "< 1"
end
