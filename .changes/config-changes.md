---
bump: minor
category: Changes
---

Breaking: `Config.protocolVersion` is removed (the protocol version is library-owned), `Action.run` now receives a guaranteed params table instead of `unknown?`, and `Config` gained optional `description` and `instructions`.
