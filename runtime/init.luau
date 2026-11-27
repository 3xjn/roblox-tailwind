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

export type ElementProps = {
	text: string?,
	id: string?,
	attributes: { [string]: string }?,
	states: { [string]: boolean }?,
	Parent: Instance?,
	mount: Instance?,
	onActivated: (() -> ())?,
	[number]: any,
}

export type ElementHandle = {
	tag: string,
	className: string,
	text: string?,
	id: string?,
	attributes: { [string]: string }?,
	states: { [string]: boolean }?,
	onActivated: (() -> ())?,
	children: { ElementHandle },
	gui: () -> GuiObject?,
	destroy: () -> (),
}

export type RuntimeConfig = {
	stylesheet: any,
	classMerge: Metadata?,
	css: any?,
	primitives: any?,
	hostOptions: { [string]: any }?,
}

local function mergeClassStrings(merger: Merger?, current: string, incoming: string): string
	if merger then
		return merger(current, incoming)
	end
	if current == "" then
		return incoming
	end
	if incoming == "" then
		return current
	end
	return current .. " " .. incoming
end

local function create(config: RuntimeConfig)
	assert(type(config) == "table" and config.stylesheet ~= nil, "Tailwind.create requires a compiled stylesheet")
	local merger: Merger? = if config.classMerge then createClassMerger(config.classMerge) else nil
	local cssModule: any = config.css
	local primitivesModule: any = config.primitives

	local function resolveCss(): any
		if cssModule == nil then
			local parent = script.Parent
			local found = if parent then parent:FindFirstChild("Css") else nil
			assert(found, "Tailwind.create requires sibling Css module or config.css")
			cssModule = require(found :: any)
		end
		return cssModule
	end

	local function resolvePrimitives(): any
		if primitivesModule == nil then
			local parent = script.Parent
			local found = if parent then parent:FindFirstChild("Primitives") else nil
			if found then
				primitivesModule = require(found :: any)
			end
		end
		return primitivesModule
	end

	local function defaultHostOptions(Css: any): { [string]: any }
		local opts: { [string]: any } = if config.hostOptions then table.clone(config.hostOptions) else {}
		if opts.nativeTextLine == nil then
			opts.nativeTextLine = true
		end
		local styles: { [string]: any } = if opts.styles then table.clone(opts.styles) else {}
		if styles.fonts == nil and type(Css.createFontProvider) == "function" then
			local fonts = Css.createFontProvider()
			fonts:register("sans-serif", Enum.Font.BuilderSans, { ascent = 0.8, descent = 0.2 })
			fonts:register("Builder Sans", Enum.Font.BuilderSans, { ascent = 0.8, descent = 0.2 })
			fonts:register("monospace", Enum.Font.RobotoMono)
			styles.fonts = fonts
		end
		if styles.environment == nil then
			styles.environment = {
				mediaType = "screen",
				initialFontSize = 16,
				features = {
					hover = "hover",
					pointer = "fine",
					["prefers-reduced-motion"] = "no-preference",
				},
			}
		end
		opts.styles = styles
		return opts
	end

	local function mountTree(target: Instance?, rootElement: any): () -> ()
		local Css = resolveCss()
		local Primitives = resolvePrimitives()

		local ownedGui: ScreenGui? = nil
		local ownedMount: Frame? = nil
		local mountFrame: GuiObject

		if target == nil then
			local Players = game:GetService("Players")
			local gui = Instance.new("ScreenGui")
			gui.Name = "TailwindRoot"
			gui.ResetOnSpawn = false
			gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
			ownedGui = gui
			local frame = Instance.new("Frame")
			frame.Name = "TailwindMount"
			frame.BackgroundTransparency = 1
			frame.Size = UDim2.fromScale(1, 1)
			frame.Parent = gui
			ownedMount = frame
			mountFrame = frame
		elseif target:IsA("ScreenGui") then
			target.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			local frame = Instance.new("Frame")
			frame.Name = "TailwindMount"
			frame.BackgroundTransparency = 1
			frame.Size = UDim2.fromScale(1, 1)
			frame.Parent = target
			ownedMount = frame
			mountFrame = frame
		elseif target:IsA("GuiObject") then
			mountFrame = target
		else
			error("Tailwind mount target must be a ScreenGui, GuiObject, or nil", 2)
		end

		local host = Css.createHost(mountFrame, config.stylesheet, defaultHostOptions(Css))
		local scope = if Primitives and type(Primitives.createScope) == "function" then Primitives.createScope() else nil
		local buttons: { any } = {}

		local function attachNode(elem: any, parentNode: any?)
			local node = host:add({
				tag = elem.tag,
				id = elem.id,
				className = elem.className,
				attributes = elem.attributes,
				states = elem.states,
				text = elem.text,
			}, parentNode)
			elem._host = host
			elem._node = node
			if elem.tag == "button" or elem.onActivated ~= nil then
				table.insert(buttons, elem)
			end
			for _, child in elem.children do
				attachNode(child, node)
			end
		end

		attachNode(rootElement, nil)
		host:flushSync()

		for _, elem in buttons do
			local guiObj = host:getGuiObject(elem._node)
			if guiObj and guiObj:IsA("GuiButton") then
				if scope then
					scope.bindButton(guiObj, {
						onState = function(state: any)
							host:setState(elem._node, "hover", state.hovered == true)
							host:setState(elem._node, "active", state.pressed == true)
							host:setState(elem._node, "focus-visible", state.focusVisible == true)
						end,
						onActivated = elem.onActivated,
					})
				elseif elem.onActivated then
					guiObj.Activated:Connect(elem.onActivated)
				end
			end
		end

		local destroyed = false
		local function destroy()
			if destroyed then
				return
			end
			destroyed = true
			if scope then
				scope.destroy()
			end
			host:destroy()
			if ownedMount then
				ownedMount:Destroy()
			end
			if ownedGui then
				ownedGui:Destroy()
			end
		end

		rootElement._destroy = destroy
		mountFrame.Destroying:Once(destroy)
		return destroy
	end

	local function makeElement(tag: string, className: string?, propsOrText: (string | ElementProps)?): ElementHandle
		local props: ElementProps = {}
		local text: string? = nil
		if type(propsOrText) == "string" then
			text = propsOrText
		elseif type(propsOrText) == "table" then
			props = propsOrText
			text = props.text
		end

		local children: { ElementHandle } = {}
		for index = 1, #props do
			local child = props[index]
			if child ~= nil then
				table.insert(children, child)
			end
		end

		local elem: any = {
			tag = tag,
			className = className or "",
			text = text,
			id = props.id,
			attributes = props.attributes,
			states = props.states,
			onActivated = props.onActivated,
			children = children,
			_host = nil,
			_node = nil,
			_destroy = nil,
		}
		elem.gui = function(): GuiObject?
			if elem._host and elem._node then
				return elem._host:getGuiObject(elem._node)
			end
			return nil
		end
		elem.destroy = function()
			if elem._destroy then
				elem._destroy()
			end
		end

		local mountTarget = props.Parent or props.mount
		if mountTarget ~= nil then
			mountTree(mountTarget, elem)
		end

		return elem
	end

	local function updateElement(elem: any, update: string | { className: string?, text: string?, attributes: { [string]: string }?, states: { [string]: boolean }? }, replaceClasses: boolean?)
		assert(type(elem) == "table" and elem.tag ~= nil, "Expected a Tailwind element handle")
		local nextClass = elem.className
		local nextText = elem.text
		local nextAttributes = elem.attributes
		local nextStates = elem.states

		if type(update) == "string" then
			nextClass = if replaceClasses then update else mergeClassStrings(merger, elem.className, update)
		elseif type(update) == "table" then
			if update.className ~= nil then
				nextClass = if replaceClasses then update.className else mergeClassStrings(merger, elem.className, update.className)
			end
			if update.text ~= nil then
				nextText = update.text
			end
			if update.attributes ~= nil then
				nextAttributes = update.attributes
			end
			if update.states ~= nil then
				nextStates = update.states
			end
		end

		elem.className = nextClass
		elem.text = nextText
		elem.attributes = nextAttributes
		elem.states = nextStates

		if elem._host and elem._node then
			elem._host:update(elem._node, {
				tag = elem.tag,
				id = elem.id,
				className = nextClass,
				attributes = nextAttributes,
				states = nextStates,
				text = nextText,
			})
		end
		return elem
	end

	local api: any = {
		cn = function(...: string?): string
			if merger then
				return merger(...)
			end
			local parts = {}
			for index = 1, select("#", ...) do
				local value = select(index, ...)
				if type(value) == "string" and value ~= "" then
					table.insert(parts, value)
				end
			end
			return table.concat(parts, " ")
		end,
		el = makeElement,
		mount = mountTree,
		set = function(elem: any, className: string)
			return updateElement(elem, className, true)
		end,
	}

	for _, tag in { "div", "span", "p", "button", "input", "img" } do
		api[tag] = function(className: string?, propsOrText: (string | ElementProps)?)
			return makeElement(tag, className, propsOrText)
		end
	end

	return setmetatable(api, {
		__call = function(_self, elem: any, update: any)
			return updateElement(elem, update, false)
		end,
	})
end

return {
	createClassMerger = createClassMerger,
	create = create,
}
