# frozen_string_literal: true

require 'bundler/setup'
require 'resque-status'
require 'socket'
require 'uri'

require 'minitest/autorun'
require 'mocha/minitest'

REDIS_URL = ENV.fetch('REDIS_URL', 'redis://127.0.0.1:9736/1')
REDIS_PID = nil

def redis_up?
  uri = URI.parse(REDIS_URL)
  Socket.tcp(uri.host, uri.port || 6379, connect_timeout: 1, &:close)
  true
rescue StandardError
  false
end

unless redis_up?
  conf = File.expand_path('redis-test.conf', __dir__)
  if system('which redis-server > /dev/null 2>&1')
    system("rm -f #{__dir__}/dump.rdb")
    abort 'redis-server failed to start' unless system("redis-server #{conf}")
    REDIS_PID = File.read(File.expand_path('redis-test.pid', __dir__)).to_i
    sleep 0.2
  else
    abort <<~MSG
      Redis not reachable at #{REDIS_URL}.
      Start one, e.g.: docker run -d --name resque-status-redis -p 9736:6379 redis:7-alpine
      Or set REDIS_URL.
    MSG
  end
end

Minitest.after_run do
  next unless REDIS_PID && REDIS_PID > 0

  Process.kill('TERM', REDIS_PID)
rescue Errno::ESRCH
  # already gone
end

# Resque 1.x rejects redis:// URLs (Redis.connect removed in redis-rb 4+).
# Path segment is the Resque namespace (historical test isolation), not Redis DB.
_uri = URI.parse(REDIS_URL)
_ns = (_uri.path || '/1').delete('/')
_ns = '1' if _ns.empty?
Resque.redis = "#{_uri.host}:#{_uri.port || 6379}/#{_ns}"

#### Fixtures

class WorkingJob
  include Resque::Plugins::Status

  def perform
    total = options['num']
    (1..total).each do |num|
      at(num, total, "At #{num}")
    end
  end
end

class ErrorJob
  include Resque::Plugins::Status

  def perform
    raise "I'm a bad little job"
  end
end

class KillableJob
  include Resque::Plugins::Status

  def perform
    Resque.redis.set("#{uuid}:iterations", 0)
    100.times do |num|
      Resque.redis.incr("#{uuid}:iterations")
      at(num, 100, "At #{num} of 100")
    end
  end
end

class BasicJob
  include Resque::Plugins::Status
end

class FailureJob
  include Resque::Plugins::Status

  def perform
    failed("I'm such a failure")
  end
end

class NeverQueuedJob
  include Resque::Plugins::Status

  def self.before_enqueue(*args)
    false
  end

  def perform
    # will never get called
  end
end

class SlimStatusJob
  include Resque::Plugins::Status

  def self.status_options(options)
    options.reject { |k, _| k.to_s == 'fat' }
  end

  def perform
    # no-op
  end
end
