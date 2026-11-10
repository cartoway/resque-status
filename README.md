# resque-status (Cartoway hard fork)

Hard fork of [`quirkey/resque-status`](https://github.com/quirkey/resque-status) (last upstream release **0.5.0**, 2015).

## Why

Upstream is unmaintained and pins `resque ~> 1.19`, which blocks Resque 2/3. This fork keeps the same public API (`Resque::Plugins::Status`) and relaxes the dependency to `resque >= 1.19`.

## Install

```ruby
# Gemfile
gem 'resque-status', github: 'cartoway/resque-status'
```

Requires **Ruby >= 3.1**.

## Usage

```ruby
class ExportJob
  include Resque::Plugins::Status

  def perform
    total = options['num'].to_i
    total.times do |i|
      # options keys are strings (Resque JSON round-trip)
      at(i + 1, total, "Step #{i + 1}/#{total}")
    end
    completed('Done')
  end
end

uuid = ExportJob.create('num' => 10)
# or ExportJob.create(num: 10) — symbols become strings after enqueue

status = Resque::Plugins::Status::Hash.get(uuid)
status.pct_complete
status.working?
status.message
```

Progress / kill checks happen in `#at` / `#tick`. A job that never calls them cannot be killed mid-flight.

### Kill

```ruby
Resque::Plugins::Status::Hash.kill(uuid)
# next at/tick raises Resque::Plugins::Status::Killed and sets status to killed
```

### Expiration

```ruby
Resque::Plugins::Status::Hash.expire_in = 3600 # seconds
```

Status keys get a Redis TTL, and the `_statuses` index score is refreshed on each `#set` so long-running jobs are not pruned while still updating.

### Patching a status

`Hash.set` rebuilds a status from scratch. To merge into an existing Redis status (e.g. drop a large option after the worker loaded it):

```ruby
Resque::Plugins::Status::Hash.patch(uuid,
  'name' => nil,
  'options' => { 'services_vrps' => nil }
)
```

Top-level keys are shallow-merged (`nil` clears a field). The `options` hash is deep-merged one level. Returns `nil` if the UUID is unknown. Persists via `set` (TTL / zset refresh included).

### Options convention

Always read **string keys** inside `#perform` (`options['num']`, not `options[:num]`). Resque encodes arguments as JSON.

## resque-web Statuses tab

Optional Sinatra extension (`lib/resque/status_server.rb`). Auto-registers when Resque’s web app loads it.

**Status:** best-effort / legacy. Validated historically against Resque 1 + `resque-web`. Not a supported product surface for this fork — use `Hash.get` / your own UI in production. PRs welcome if you need it on Resque 2/3.

## Development

```bash
# Redis for tests (default REDIS_URL=redis://127.0.0.1:9736/1)
docker run -d --name resque-status-redis -p 9736:6379 redis:7-alpine

bundle install
bundle exec rake test

# Matrix locally (Resque 1 CI pins redis ~> 4.8 — Resque 1.x + redis 5/6 break)
rm -f Gemfile.lock
RESQUE='~> 2.7' bundle install && bundle exec rake test
```

## License

MIT — same as upstream (Aaron Quint).
