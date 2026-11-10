# Changelog

## 0.6.0

Hard fork of `quirkey/resque-status` for Cartoway.

- Relax runtime dependency to `resque >= 1.19` (unblock Resque 2/3)
- Require Ruby `>= 3.1`
- Fix `kill` / `killed` for redis-rb 4.8+ (raw `sadd?`/`srem?` under Resque DataStore)
- When `expire_in` is set, refresh `_statuses` zset score on each status update
- Use float zset scores so same-second jobs stay ordered
- Add `Resque::Plugins::Status::Hash.patch` to merge into an existing status (deep-merge `options`)
- Add `status_options` hook to omit large keys from the status hash; store full enqueue args for `dequeue`
- CI matrix: Ruby 3.1–3.4 / 4.0 × Resque 1.x / 2.x / 3.x (pins `redis ~> 4.8` under Resque 1)
- Standalone README (upstream `README.rdoc` dropped)
- Drop Jeweler; modernize test harness (external Redis / `REDIS_URL`)
