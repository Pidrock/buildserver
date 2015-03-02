# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "buildserver"
  spec.version       = '0.0.4'
  spec.authors       = ["Kasper Grubbe"]
  spec.email         = ["kawsper@gmail.com"]
  spec.summary       = %q{Lets you easily compile bash scripts from Ruby to build server instances on your favorite Linux distro.}
  spec.description   = %q{Build bash scripts from Ruby}
  spec.homepage      = "https://github.com/Pidrock/buildserver"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.3"
end
