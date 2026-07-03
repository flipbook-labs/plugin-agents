local types = require("@root/types")

type InputSchema = types.InputSchema
type InputSchemaProperty = types.InputSchemaProperty

local function typeMatches(value: unknown, schemaType: string): boolean
	if schemaType == "string" then
		return type(value) == "string"
	elseif schemaType == "number" then
		return type(value) == "number"
	elseif schemaType == "integer" then
		return type(value) == "number" and (value :: number) % 1 == 0
	elseif schemaType == "boolean" then
		return type(value) == "boolean"
	elseif schemaType == "object" or schemaType == "array" then
		return type(value) == "table"
	end
	return false
end

local function withArticle(schemaType: string): string
	local firstLetter = string.sub(schemaType, 1, 1)
	return if string.find("aeiou", firstLetter, 1, true) then `an {schemaType}` else `a {schemaType}`
end

local function quoted(value: unknown): string
	if type(value) == "string" then
		return `"{value}"`
	end
	return tostring(value)
end

-- "(string) — Path to a .story ModuleScript" or "(string)"; quoting the schema
-- back at the caller is the point: an agent should be able to correct its call
-- from the error alone, without re-fetching the manifest.
local function describeProperty(property: InputSchemaProperty?): string
	if property == nil then
		return ""
	end
	if property.description ~= nil then
		return ` ({property.type}) — {property.description}`
	end
	return ` ({property.type})`
end

local function sortedNames(map: { [string]: unknown }): { string }
	local names = {}
	for name in map do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

--[[
	Validates raw params from the gateway boundary against an action's
	inputSchema. Enforces the shape only — property types, required params,
	enums, and no unknown params. Domain rules (non-empty strings, paths that
	resolve, ...) remain the action's responsibility.

	Returns the params table to pass to the action's run (nil params become an
	empty table), or nil and an error message.
]]
local function validateParams(
	actionName: string,
	inputSchema: InputSchema?,
	params: unknown
): ({ [string]: unknown }?, string?)
	if params == nil then
		params = {}
	end
	if type(params) ~= "table" then
		return nil, `invalid params for {actionName}: params must be a table, got {type(params)}`
	end

	local fields = params :: { [string]: unknown }

	if inputSchema == nil then
		return fields, nil
	end

	local properties: { [string]: InputSchemaProperty } = inputSchema.properties or {}
	local problems: { string } = {}

	local required: { string } = inputSchema.required or {}
	for _, requiredName in required do
		if fields[requiredName] == nil then
			table.insert(
				problems,
				`missing required param "{requiredName}"{describeProperty(properties[requiredName])}`
			)
		end
	end

	for name, value in fields do
		if type(name) ~= "string" then
			table.insert(problems, `param keys must be strings, got {type(name)} ({tostring(name)})`)
			continue
		end

		local property = properties[name]
		if property == nil then
			local valid = sortedNames(properties)
			if #valid == 0 then
				table.insert(problems, `unknown param "{name}" — this action takes no params`)
			else
				table.insert(problems, `unknown param "{name}" — valid params: {table.concat(valid, ", ")}`)
			end
			continue
		end

		if not typeMatches(value, property.type) then
			table.insert(
				problems,
				`param "{name}" must be {withArticle(property.type)}, got {type(value)}{describeProperty(property)}`
			)
			continue
		end

		if property.enum ~= nil then
			local allowed = false
			for _, enumValue in property.enum do
				if value == enumValue then
					allowed = true
					break
				end
			end
			if not allowed then
				local labels = {}
				for _, enumValue in property.enum do
					table.insert(labels, quoted(enumValue))
				end
				table.insert(
					problems,
					`param "{name}" must be one of {table.concat(labels, ", ")}, got {quoted(value)}`
				)
			end
		end
	end

	if #problems > 0 then
		table.sort(problems)
		return nil, `invalid params for {actionName}: {table.concat(problems, "; ")}`
	end

	return fields, nil
end

return validateParams
