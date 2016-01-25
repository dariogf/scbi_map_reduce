# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'scbi_mapreduce/version'

Gem::Specification.new do |spec|
  spec.name          = "scbi_mapreduce"
  spec.version       = ScbiMapreduce::VERSION
  spec.authors       = ["dariogf"]
  spec.email         = ["dariogf@gmail.com"]
  spec.summary       = %q{scbi_mapreduce brings parallel and distributed computing capabilities to your code.}
  spec.description   = %q{scbi_mapreduce brings parallel and distributed computing capabilities to your code, with a very easy to use framework that allows you to exploit your clustered or cloud computational resources.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_runtime_dependency 'eventmachine','>=0.12.0'
  spec.add_runtime_dependency 'json','>=0'

end
