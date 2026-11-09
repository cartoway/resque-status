# frozen_string_literal: true

require_relative 'lib/resque/plugins/status/version'

Gem::Specification.new do |s|
  s.name          = 'resque-status'
  s.version       = Resque::Plugins::Status::VERSION
  s.authors       = ['Aaron Quint', 'Cartoway']
  s.email         = ['aaron@quirkey.com']
  s.homepage      = 'https://github.com/cartoway/resque-status'
  s.summary       = 'Trackable/killable Resque jobs (Cartoway hard fork)'
  s.description   = 'Hard fork of quirkey/resque-status (unmaintained since 2015). ' \
                    'Provides Resque::Plugins::Status for UUID trackable/killable jobs.'
  s.license       = 'MIT'

  s.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject { |f| f.start_with?('test/', '.git') }
  end
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.7'

  # Upstream pinned ~> 1.19; allow Resque 2/3 (Sinatra still comes from Resque itself).
  s.add_runtime_dependency 'resque', '>= 1.19'
end
