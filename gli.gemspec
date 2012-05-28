# Make sure we get the gli that's local
require File.join([File.dirname(__FILE__),'lib','gli','version.rb'])

spec = Gem::Specification.new do |s| 
  s.name = 'gli'
  s.version = GLI::VERSION
  s.author = 'David Copeland'
  s.email = 'davidcopeland@naildrivin5.com'
  s.homepage = 'http://davetron5000.github.com/gli'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A Git Like Interface for building command line apps'
  s.description = 'An application and API for describing command line interfaces that can be used to quickly create a shell for executing command-line tasks.  The command line user interface is similar to Git''s, in that it takes global options, a command, command-specific options, and arguments'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   =  'gli'
  s.require_paths = ["lib"]

  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc', 'gli.rdoc']
  s.rdoc_options << '--title' << 'Git Like Interface' << '--main' << 'README.rdoc'
  s.bindir = 'bin'
  s.rubyforge_project = 'gli'
  s.add_development_dependency('rake', '~> 0.9.2.2')
  s.add_development_dependency('rdoc', '~> 3.11')
  s.add_development_dependency('roodi', '~> 2.1.0')
  s.add_development_dependency('reek')
  s.add_development_dependency('grancher', '~> 0.1.5')
  s.add_development_dependency('rainbow', '~> 1.1.1')
  s.add_development_dependency('clean_test')
  s.add_development_dependency('aruba', '~> 0.4.7')
  s.add_development_dependency('sdoc')
end

