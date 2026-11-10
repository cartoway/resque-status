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

`Hash.set` rebuilds a status from scratch (it does not read Redis first). Use `Hash.patch` when you need a **partial update** of an existing status:

- clear a field after the worker no longer needs it in the public status
- update `message` / metadata without rewriting the whole hash
- clear one key inside `options` without replacing the whole `options` hash

```ruby
# Clear one option key, keep the others; also clear the display name
Resque::Plugins::Status::Hash.patch(uuid,
  'name' => nil,
  'options' => { 'payload' => nil }
)

# Update only the message
Resque::Plugins::Status::Hash.patch(uuid, 'message' => 'phase 2')
```

Top-level keys are shallow-merged (`nil` clears a field). The `options` hash is deep-merged one level. Returns `nil` if the UUID is unknown. Persists via `set` (TTL / zset refresh included).

### Keeping large options out of status

**Use case:** you enqueue a job with a large argument (file contents, serialized object, big JSON) that the worker needs in `#perform`, but you do **not** want that blob duplicated on the status hash used by `Hash.get` / UIs / listings.

By default every enqueue option is copied onto the status. Override `status_options` to store only the small metadata on the status:

```ruby
class ExportJob
  include Resque::Plugins::Status

  def self.status_options(options)
    options.reject { |k, _| k.to_s == 'payload' }
  end

  def perform
    data = options['payload'] # still available on the worker
    # ...
  end
end

ExportJob.create('user_id' => 42, 'payload' => huge_string)
# status.options => { 'user_id' => 42 }  — no payload
# worker options => { 'user_id' => 42, 'payload' => huge_string }
```

`#name` (written on each `#tick` / `#at`) also uses `status_options`, so the large key is not re-injected into the status while the job runs.

A side key (`status:uuid:enqueue_args`) keeps the full options for `dequeue` while the job is still queued, then is removed when the worker starts (or on `Hash.remove`).

Prefer `status_options` at enqueue time over enqueueing the blob into the status and `patch`-ing it away later.

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
