# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rm-extensions/version'

Gem::Specification.new do |gem|
  gem.name          = "rm-extensions"
  gem.version       = RMX::VERSION
  gem.authors       = ["Joe Noon"]
  gem.email         = ["joenoon@gmail.com"]
  gem.description   = %q{Extensions and helpers for dealing with various areas of rubymotion}
  gem.summary       = %q{Extensions and helpers for dealing with various areas of rubymotion}
  gem.homepage      = "https://github.com/joenoon/rm-extensions"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
