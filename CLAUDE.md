# CLAUDE.md

See [AGENTS.md](AGENTS.md) for the repo overview.

Task-specific runbooks live as skills under `.agents/skills/<name>/SKILL.md`. Each skill's frontmatter `description` says when to use it. To use one, read its `SKILL.md` and follow the steps.

Available skills:

- **`use-agent-gateway`** (`.agents/skills/use-agent-gateway/SKILL.md`) — discover and drive AgentGateway-based plugins from inside Studio; Studio MCP setup and troubleshooting.
- **`e2e`** (`.agents/skills/e2e/SKILL.md`) — end-to-end test: build the example Studio plugin, install it, then discover and invoke its actions through the gateway from inside Studio.
