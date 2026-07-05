---
bump: minor
category: Features
---

The registry now validates `params` against each action's `inputSchema` before dispatch — required params, declared types, `enum` values, and unknown-param rejection — with errors that quote the schema. Schemas themselves are validated at registry construction, and action results are checked to be JSON-encodable so encoding problems blame the action instead of surfacing on the agent's side.
