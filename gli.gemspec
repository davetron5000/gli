# Make sure we get the gli that's local
require File.join([File.dirname(__FILE__),"lib","gli","version.rb"])

spec = Gem::Specification.new do |s|
  s.name = "gli"
  s.version = GLI::VERSION
  s.licenses = ["Apache-2.0"]
  s.author = "David Copeland"
  s.email = "davidcopeland@naildrivin5.com"
  s.homepage = "http://davetron5000.github.com/gli"
  s.platform = Gem::Platform::RUBY
  s.summary = "Build command-suite CLI apps that are awesome."
  s.description = "Build command-suite CLI apps that are awesome.  Bootstrap your app, add commands, options and documentation while maintaining a well-tested idiomatic command-line app"

  s.metadata = {
    'yard.run'          => 'yard',
    'bug_tracker_uri'   => 'https://github.com/davetron5000/gli/issues',
    'changelog_uri'     => 'https://github.com/davetron5000/gli/releases',
    'documentation_uri' => 'https://www.rubydoc.info/gems/gli/',
    'homepage_uri'      => 'https://davetron5000.github.com/gli/',
    'source_code_uri'   => 'https://github.com/davetron5000/gli/'
  }

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.extra_rdoc_files = ["README.rdoc", "gli.rdoc"]
  s.rdoc_options << "--title" << "Git Like Interface" << "--main" << "README.rdoc"

  s.bindir      = "exe"
  s.executables = "gli"

  s.add_development_dependency("rake", "~> 0.9.2.2")
  s.add_development_dependency("rdoc", "~> 4.2")
  s.add_development_dependency("rainbow", "~> 1.1", "~> 1.1.1")
  s.add_development_dependency("sdoc", "~> 0.4")
  s.add_development_dependency("minitest")
end
