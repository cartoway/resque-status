# resque-status (Cartoway hard fork)

Hard fork of [`quirkey/resque-status`](https://github.com/quirkey/resque-status) (last upstream release **0.5.0**, 2015).

## Why

Upstream is unmaintained and pins `resque ~> 1.19`, which blocks Resque 2/3. This fork keeps the same public API (`Resque::Plugins::Status`) and relaxes the dependency to `resque >= 1.19`.

## Install

```ruby
# Gemfile
gem 'resque-status', github: 'cartoway/resque-status'
```

## Usage

Unchanged from upstream — include `Resque::Plugins::Status`, use `.create`, `#at` / `#tick`, `Hash.get` / `Hash.kill`.

See the [original README](https://github.com/quirkey/resque-status/blob/master/README.rdoc) for full docs.

## License

MIT — same as upstream (Aaron Quint).
