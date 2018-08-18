# Make sure we get the gli that's local
require File.join([File.dirname(__FILE__),'lib','gli','version.rb'])

spec = Gem::Specification.new do |s|
  s.name = 'gli'
  s.version = GLI::VERSION
  s.licenses = ['Apache-2.0']
  s.author = 'David Copeland'
  s.email = 'davidcopeland@naildrivin5.com'
  s.homepage = 'http://davetron5000.github.com/gli'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Build command-suite CLI apps that are awesome.'
  s.description = 'Build command-suite CLI apps that are awesome.  Bootstrap your app, add commands, options and documentation while maintaining a well-tested idiomatic command-line app'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   =  'gli'
  s.require_paths = ["lib"]

  s.extra_rdoc_files = ['README.rdoc', 'gli.rdoc']
  s.rdoc_options << '--title' << 'Git Like Interface' << '--main' << 'README.rdoc'
  s.bindir = 'bin'
  s.rubyforge_project = 'gli'
  s.add_development_dependency('rake', '~> 0.9.2.2')
  s.add_development_dependency('rdoc', '~> 4.2')
  s.add_development_dependency('rainbow', '~> 1.1', '~> 1.1.1')
  s.add_development_dependency('clean_test', '~> 1.0')
  s.add_development_dependency('cucumber', '~> 3.1.2')
  s.add_development_dependency('gherkin', '~> 5.1.0')
  s.add_development_dependency('aruba', '~> 0.7.4')
  s.add_development_dependency('sdoc', '~> 0.4')
  s.add_development_dependency('faker','~> 1.9.1')
end
