---
bump: minor
category: Features
---

Gateways are now discoverable and self-describing: every gateway BindableFunction carries the `AgentGateway` CollectionService tag plus `Description`, `Usage`, and `ProtocolVersion` attributes, the `list` manifest includes the gateway's `name`, `description`, and new `Config.instructions` prose, and every protocol error teaches the fix (malformed requests restate the request grammar; unknown actions list the valid names). `TAG` and `PROTOCOL_VERSION` are exported constants.
