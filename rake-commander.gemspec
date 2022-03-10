lib = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require './lib/rake-commander/version'

Gem::Specification.new do |spec|
  spec.name          = 'rake-commander'
  spec.version       = RakeCommander::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ['Oscar Segura']
  spec.email         = ['oscar@ecoportal.co.nz']
  spec.date          = '2022-03-11'
  spec.summary       = 'rake-commander to ease building cli integrations'
  spec.homepage      = 'https://www.ecoportal.com'
  spec.licenses      = 'MIT'
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.required_ruby_version = '>= 2.6.3'

  # spec.test_files    = `git ls-files -- {test,spec,features}/*`.split('\n')
  # spec.executables   = `git ls-files -- bin/*`.split('\n').map{ |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler',     '>= 2.2.17', '< 2.3'
  spec.add_development_dependency 'rake',        '>= 13.0.3', '< 13.1'
  #spec.add_development_dependency 'factory_bot', '>= 6.2.0',  '< 6.3'
  spec.add_development_dependency 'redcarpet',   '>= 3.5.1',  '< 3.6'
  spec.add_development_dependency 'rspec',       '>= 3.10.0', '< 3.11'
  spec.add_development_dependency 'yard',        '>= 0.9.26', '< 0.10'
  spec.add_development_dependency "pry",         "~> 0.14"

  spec.add_dependency 'neatjson',     '>= 0.9.0', '< 0.10'
end
