--!strict

export type Metadata = { version: number, classes: { string }, conflicts: { { number } } }
export type Options = { cacheSize: number? }
export type Merger = (...string?) -> string

local function dense(values: { any }, label: string): number
	local count = 0
	for key in values do
		assert(type(key) == "number" and key % 1 == 0 and key >= 1 and key <= #values, label .. " must be a dense array")
		count += 1
	end
	assert(count == #values, label .. " must be a dense array")
	return count
end

local function whitespace(codepoint: number): boolean
	return (codepoint >= 9 and codepoint <= 13) or codepoint == 32 or codepoint == 0xA0
		or codepoint == 0x1680 or (codepoint >= 0x2000 and codepoint <= 0x200A)
		or codepoint == 0x2028 or codepoint == 0x2029 or codepoint == 0x202F
		or codepoint == 0x205F or codepoint == 0x3000 or codepoint == 0xFEFF
end

local function words(value: string): { string }
	local result = {}
	if not value:find("[\128-\255]") then
		for word in value:gmatch("%S+") do
			table.insert(result, word)
		end
		return result
	end
	assert(utf8.len(value), "Class names require valid UTF-8")
	local start: number? = nil
	for offset, codepoint in utf8.codes(value) do
		if whitespace(codepoint) then
			if start then
				table.insert(result, value:sub(start, offset - 1))
				start = nil
			end
		elseif not start then
			start = offset
		end
	end
	if start then
		table.insert(result, value:sub(start))
	end
	return result
end

-- Metadata comes from tailwind-merge at build time. Keep a private snapshot;
-- caller mutation cannot alter the meaning of an already-created merger.
local function createClassMerger(metadata: Metadata, options: Options?): Merger
	assert(metadata.version == 1, "Unsupported class merge metadata version")
	local count = dense(metadata.classes, "classes")
	assert(dense(metadata.conflicts, "conflicts") == count, "Every class requires a conflict list")
	local names: { [string]: number } = {}
	local conflicts: { { number } } = {}
	for index, name in metadata.classes do
		assert(type(name) == "string" and name ~= "" and utf8.len(name), "Invalid compiled class name")
		local tokens = words(name)
		assert(#tokens == 1 and tokens[1] == name and names[name] == nil, "Compiled class names must be unique single tokens")
		names[name] = index
		local source = metadata.conflicts[index]
		dense(source, "class conflicts")
		local copied, seen = {}, {}
		for _, id in source do
			assert(type(id) == "number" and id % 1 == 0 and id >= 1 and id <= count and not seen[id], "Invalid class conflict index")
			seen[id] = true
			table.insert(copied, id)
		end
		conflicts[index] = copied
	end
	local maximum = if options and options.cacheSize ~= nil then options.cacheSize else 500
	assert(maximum >= 0 and maximum < math.huge and maximum % 1 == 0, "cacheSize must be a nonnegative integer")
	local current, previous = {}, {}
	local entries = 0
	local function remember(key: string, value: string)
		if maximum == 0 then
			return
		end
		if current[key] == nil then
			entries += 1
		end
		current[key] = value
		if entries >= maximum then
			previous, current, entries = current, {}, 0
		end
	end
	return function(...: string?): string
		local parts = {}
		for index = 1, select("#", ...) do
			local value = select(index, ...)
			assert(value == nil or type(value) == "string", "Class composition accepts strings or nil")
			if value and value ~= "" then
				table.insert(parts, value)
			end
		end
		local key = table.concat(parts, " ")
		local cached = current[key]
		if cached ~= nil then
			return cached
		end
		cached = previous[key]
		if cached ~= nil then
			remember(key, cached)
			return cached
		end
		local tokens = words(key)
		local ids = {}
		for index, name in tokens do
			local id = names[name]
			assert(id, `Class merge metadata does not include '{name}'; include it in the Tailwind build`)
			ids[index] = id
		end
		local blocked, retained = {}, {}
		for index = #tokens, 1, -1 do
			local id = ids[index]
			if not blocked[id] then
				table.insert(retained, tokens[index])
				for _, conflict in conflicts[id] do
					blocked[conflict] = true
				end
			end
		end
		local ordered = table.create(#retained)
		for index, token in retained do
			ordered[#retained - index + 1] = token
		end
		local result = table.concat(ordered, " ")
		remember(key, result)
		return result
	end
end

return { createClassMerger = createClassMerger }
