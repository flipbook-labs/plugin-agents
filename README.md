# AgentGateway

[![CI](https://github.com/flipbook-labs/agent-gateway/actions/workflows/ci.yml/badge.svg)](https://github.com/flipbook-labs/agent-gateway/actions/workflows/ci.yml)

AgentGateway is a Roblox library for defining actions an agent can perform with a plugin in Studio through a small, MCP-inspired gateway.

## Installation

### Wally

```toml
[dependencies]
AgentGateway = "flipbook-labs/agent-gateway@x.x.x"
```

## Usage

Define your plugin's actions, register them, and stand up a gateway. Registered actions are discoverable and invokable by in-Studio agents.

```lua
local AgentGateway = require(path.to.AgentGateway)

type Context = { plugin: Plugin }

local config: AgentGateway.Config = {
	name = "MyPluginGateway",
	description = "Actions for driving MyPlugin.",
	instructions = "Insert parts with insertPart. Paths are slash-separated from the DataModel root.",
}

local context: Context = { plugin = plugin }

local actions: { AgentGateway.Action<Context> } = {
	{
		name = "insertPart",
		title = "Insert Part",
		description = "Insert a new anchored Part into the Workspace.",
		inputSchema = {
			type = "object",
			properties = {
				name = { type = "string", description = "Name for the new Part" },
			},
		},
		run = function(ctx, params)
			local part = Instance.new("Part")
			if type(params.name) == "string" then
				part.Name = params.name :: string
			end
			part.Anchored = true
			part.Parent = workspace
			return { name = part.Name }
		end,
	},
}

local registry = AgentGateway.createActionRegistry(config, context, actions)
local cleanup = AgentGateway.createGateway(registry, config)

plugin.Unloading:Connect(cleanup)
```

The registry validates incoming params against each action's `inputSchema` (required params, declared types, `enum` values, unknown-param rejection) before `run` is called, and returns schema-quoting errors to the caller — actions only need to enforce what a schema can't express. Action results must be JSON-encodable tables.

`config.instructions` is free-form prose for agents. It is returned from the gateway's `list` method, so it's the first thing an agent reads — use it for workflow guidance: what to call first, readiness rules, caveats.

## How agents find and use the gateway

Every gateway `BindableFunction` (parented to `CoreGui` by default) is tagged with the `AgentGateway` CollectionService tag and carries self-describing attributes (`Description`, `Usage`, `ProtocolVersion`). An agent still has to be told to look — that's the job of the [`use-agent-gateway`](.agents/skills/use-agent-gateway/SKILL.md) skill, a consumer repo's own instructions, or the user's prompt — but the tag shrinks what needs telling to one convention shared by every plugin built on this library, independent of gateway names, parents, or which plugins happen to be installed:

```lua
local CollectionService = game:GetService("CollectionService")
local gateway = CollectionService:GetTagged("AgentGateway")[1]

-- Discover: identity, instructions, and available actions with input schemas
gateway:Invoke({ method = "list" })

-- Invoke one
gateway:Invoke({ method = "call", action = "insertPart", params = { name = "AgentPart" } })
```

Responses are always `{ ok: boolean, result: any?, error: string? }`, and every error message is written to teach the caller the fix — malformed requests restate the request grammar, unknown actions list the valid names, and invalid params quote the schema.

Agent-facing runbooks live in [`.agents/skills`](.agents/skills): [`use-agent-gateway`](.agents/skills/use-agent-gateway/SKILL.md) covers Studio MCP setup, discovery, and the full protocol — it's the skill to copy or reference from repos that consume AgentGateway.

For a complete, runnable plugin see [`examples/agent-plugin`](examples/agent-plugin), and the [`e2e`](.agents/skills/e2e/SKILL.md) skill for the agent↔plugin round-trip test.

## License

The contents of this repository are available under the MIT License. For full license text, see [LICENSE](LICENSE).
