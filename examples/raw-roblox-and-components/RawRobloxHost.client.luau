--!strict
-- Raw Roblox Luau example: @3xjn/roblox-css + @3xjn/roblox-tailwind + @3xjn/roblox-primitives
-- directly on a ScreenGui without React.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Css = require(ReplicatedStorage.Packages.Css)
local Tailwind = require(ReplicatedStorage.Packages.Tailwind)
local Primitives = require(ReplicatedStorage.Packages.Primitives)
local Stylesheet = require(ReplicatedStorage.Generated.Stylesheet)
local ClassMerge = require(ReplicatedStorage.Generated.ClassMerge)

local cn = Tailwind.createClassMerger(ClassMerge)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TailwindRawRobloxDemo"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local mount = Instance.new("Frame")
mount.BackgroundTransparency = 1
mount.Size = UDim2.fromOffset(360, 220)
mount.Position = UDim2.fromOffset(24, 24)
mount.Parent = screenGui

local host = Css.createHost(mount, Stylesheet, { nativeTextLine = true })
local input = Primitives.createScope()

local card = host:add({
	tag = "div",
	className = "flex flex-col gap-3 rounded-xl border border-zinc-800 bg-zinc-950 p-5",
})

local header = host:add({
	tag = "div",
	className = "flex items-center justify-between gap-2",
}, card)

host:add({
	tag = "span",
	className = "text-base font-semibold text-zinc-50",
	text = "Raw Roblox + Tailwind",
}, header)

local online = true
local badge = host:add({
	tag = "span",
	className = cn("rounded-md px-2 py-1 text-xs font-medium", "bg-emerald-500/15 text-emerald-300"),
	text = "Online",
}, header)

host:add({
	tag = "p",
	className = "text-sm text-zinc-400",
	text = "Styled with compiled Tailwind utilities directly through Css.createHost.",
}, card)

local button = host:add({
	tag = "button",
	className = "flex items-center justify-center rounded-lg bg-zinc-100 px-4 py-2 text-sm font-medium text-zinc-950 hover:bg-zinc-200 active:bg-zinc-300",
	text = "Toggle status",
}, card)

host:flushSync()

local buttonGui = host:getGuiObject(button)
if buttonGui and buttonGui:IsA("GuiButton") then
	input.bindButton(buttonGui, {
		onState = function(state)
			host:setState(button, "hover", state.hovered)
			host:setState(button, "active", state.pressed)
			host:setState(button, "focus-visible", state.focusVisible)
		end,
		onActivated = function()
			online = not online
			host:update(badge, {
				className = cn(
					"rounded-md px-2 py-1 text-xs font-medium",
					if online then "bg-emerald-500/15 text-emerald-300" else "bg-amber-500/15 text-amber-300"
				),
				text = if online then "Online" else "Away",
			})
		end,
	})
end

screenGui.Destroying:Connect(function()
	input.destroy()
	host:destroy()
end)
