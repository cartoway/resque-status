# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# CI matrix override, e.g. RESQUE='~> 2.7' bundle update resque
if (resque = ENV['RESQUE'])
  gem 'resque', resque
  # Resque 1.x passes thread_safe: to Redis.new — removed in redis-rb 5+
  gem 'redis', '~> 4.8' if resque.include?('1.')
end

gem 'minitest', '~> 5.0'
gem 'mocha'
gem 'rake'
