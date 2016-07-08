# -*- encoding: utf-8 -*-
require File.expand_path('../lib/asynk/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Danil Nurgaliev"]
  gem.email         = ["jkonalegi@gmail.com"]
  gem.summary       = "Async/sync inter sevrer communication tool."
  gem.description   = "Async/sync inter sevrer communication tool, based on RabbitMQ and Celluloid"
  gem.license       = "LGPL-3.0"
  gem.homepage       = "https://github.com/konalegi/asynk"

  gem.files         = `git ls-files -z`.split("\x0")
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "asynk"
  gem.require_paths = ["lib"]
  gem.version       = Asynk::VERSION
  gem.add_dependency                  'celluloid', '~> 0.17'
  gem.add_dependency                  'celluloid-io', '~> 0.17'
  gem.add_dependency                  'connection_pool', '~> 2.2'
  gem.add_dependency                  'activesupport', '>= 4.2'
  gem.add_dependency                  'json', '~> 1.0'
  gem.add_dependency                  'bunny', '~> 2.3'
  gem.add_development_dependency      'minitest', '~> 5.7', '>= 5.7.0'
  gem.add_development_dependency      'rake', '~> 10.0'
  gem.add_development_dependency      'rails', '~> 4'
end
