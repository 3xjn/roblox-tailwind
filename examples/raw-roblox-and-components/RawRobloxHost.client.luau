--!strict
-- Pure raw Roblox Luau example: uses @3xjn/roblox-css + @3xjn/roblox-tailwind
-- directly on a ScreenGui without React.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Css = require(ReplicatedStorage.Packages.Css)
local Tailwind = require(ReplicatedStorage.Packages.Tailwind)
local Stylesheet = require(ReplicatedStorage.Generated.Stylesheet)
local ClassMerge = require(ReplicatedStorage.Generated.ClassMerge)

local cn = Tailwind.createClassMerger(ClassMerge)

local function classesOf(value: string): { string }
	local list = {}
	for token in string.gmatch(value, "%S+") do
		table.insert(list, token)
	end
	return list
end

local player = Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TailwindRawRobloxDemo"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local mount = Instance.new("Frame")
mount.Name = "Mount"
mount.BackgroundTransparency = 1
mount.Size = UDim2.fromOffset(360, 220)
mount.Position = UDim2.fromOffset(24, 24)
mount.Parent = screenGui

local host = Css.createHost(mount, Stylesheet, {
	nativeTextLine = true,
})

local card = host:add({
	tag = "div",
	classes = classesOf("flex flex-col gap-3 rounded-xl border border-zinc-800 bg-zinc-950 p-5"),
})

local header = host:add({
	tag = "div",
	classes = classesOf("flex items-center justify-between gap-2"),
}, card)

host:add({
	tag = "span",
	classes = classesOf("text-base font-semibold text-zinc-50"),
	text = "Raw Roblox + Tailwind",
}, header)

local statusBadge = host:add({
	tag = "span",
	classes = classesOf(cn("rounded-md px-2 py-1 text-xs font-medium", "bg-emerald-500/15 text-emerald-300")),
	text = "Online",
}, header)

host:add({
	tag = "p",
	classes = classesOf("text-sm text-zinc-400"),
	text = "Styled with compiled Tailwind utilities directly through Css.createHost.",
}, card)

local online = true
local toggleButton = host:add({
	tag = "button",
	classes = classesOf(
		cn(
			"flex items-center justify-center rounded-lg px-4 py-2 text-sm font-medium",
			"bg-zinc-100 text-zinc-950 hover:bg-zinc-200 active:bg-zinc-300"
		)
	),
	text = "Toggle status",
}, card)

host:flushSync()

local buttonInstance = host:getGuiObject(toggleButton)
if buttonInstance and buttonInstance:IsA("GuiButton") then
	buttonInstance.MouseEnter:Connect(function()
		host:setState(toggleButton, "hover", true)
	end)
	buttonInstance.MouseLeave:Connect(function()
		host:setState(toggleButton, "hover", false)
		host:setState(toggleButton, "active", false)
	end)
	buttonInstance.MouseButton1Down:Connect(function()
		host:setState(toggleButton, "active", true)
	end)
	buttonInstance.MouseButton1Up:Connect(function()
		host:setState(toggleButton, "active", false)
	end)
	buttonInstance.Activated:Connect(function()
		online = not online
		host:update(statusBadge, {
			classes = classesOf(cn(
				"rounded-md px-2 py-1 text-xs font-medium",
				if online then "bg-emerald-500/15 text-emerald-300" else "bg-amber-500/15 text-amber-300"
			)),
			text = if online then "Online" else "Away",
		})
	end)
end

screenGui.Destroying:Connect(function()
	host:destroy()
end)
