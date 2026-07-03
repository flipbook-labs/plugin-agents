local constants = require("@root/constants")
local types = require("@root/types")
local validateInputSchema = require("@root/validateInputSchema")
local validateParams = require("@root/validateParams")
local validateResult = require("@root/validateResult")

type Action<Context> = types.Action<Context>
type ActionResult = types.ActionResult
type Config = types.Config
type Manifest = types.Manifest
type ManifestEntry = types.ManifestEntry

type ActionRegistry<Context> = {
	actions: { Action<Context> },
	dispatch: (name: string, params: unknown?) -> ActionResult,
	manifest: () -> Manifest,
}

local function createActionRegistry<Context>(
	config: Config,
	context: Context,
	actions: { Action<Context> }
): ActionRegistry<Context>
	-- Snapshot the caller's array so manifest and dispatch always agree,
	-- even if the caller mutates the original table after construction.
	local snapshot: { Action<Context> } = table.move(actions, 1, #actions, 1, {})

	local nameSet: { [string]: boolean } = {}
	for _, action in snapshot do
		if action.name == "" then
			error("action name must not be empty")
		end
		if nameSet[action.name] then
			error(`duplicate action name: "{action.name}"`)
		end
		nameSet[action.name] = true

		validateInputSchema(action.name, action.inputSchema)
	end

	local actionMap: { [string]: Action<Context> } = {}
	local sortedActionNames: { string } = {}
	for _, action in snapshot do
		actionMap[action.name] = action
		table.insert(sortedActionNames, action.name)
	end
	table.sort(sortedActionNames)

	local function dispatch(name: string, params: unknown?): ActionResult
		local result: ActionResult

		local action = actionMap[name]
		if action == nil then
			result = {
				ok = false,
				error = if #sortedActionNames == 0
					then `unknown action: {name} — this gateway has no registered actions`
					else `unknown action: {name} — available actions: {table.concat(sortedActionNames, ", ")}.`
						.. ' Use {method = "list"} for descriptions and input schemas.',
			}
		else
			local validated, paramsError = validateParams(name, action.inputSchema, params)
			if validated == nil then
				result = {
					ok = false,
					error = paramsError,
				}
			else
				local ok, value = pcall(action.run, context, validated)
				if not ok then
					result = {
						ok = false,
						error = tostring(value),
					}
				else
					-- Agents read results by JSON-encoding them on their side
					-- of the boundary; a result that can't encode (Instance,
					-- mixed-key table, cycle) would fail or silently lose data
					-- there, where it looks like the agent's fault instead of
					-- the action's.
					local resultProblem = validateResult(value)
					if resultProblem ~= nil then
						result = {
							ok = false,
							error = `action {name} returned a result that cannot be JSON-encoded`
								.. ` ({resultProblem}); this is a bug in the action, not in the request`,
						}
					else
						result = {
							ok = true,
							result = value,
						}
					end
				end
			end
		end

		if config.onActionResult ~= nil then
			-- Observability only — a throwing observer must not break dispatch.
			pcall(config.onActionResult, name, result)
		end

		return result
	end

	local function manifest(): Manifest
		local entries: { ManifestEntry } = {}

		for _, action in snapshot do
			table.insert(entries, {
				name = action.name,
				title = action.title,
				description = action.description,
				inputSchema = action.inputSchema,
			})
		end

		return {
			protocolVersion = constants.PROTOCOL_VERSION,
			name = config.name,
			description = config.description,
			instructions = config.instructions,
			actions = entries,
		}
	end

	return {
		actions = snapshot,
		dispatch = dispatch,
		manifest = manifest,
	}
end

return createActionRegistry
