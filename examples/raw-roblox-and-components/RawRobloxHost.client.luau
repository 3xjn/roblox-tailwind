--!strict
-- Clean raw Roblox Luau + Tailwind example (no React, no manual createHost/flushSync).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tailwind = require(ReplicatedStorage.Packages.Tailwind)
local tw = Tailwind.create({
	stylesheet = require(ReplicatedStorage.Generated.Stylesheet),
	classMerge = require(ReplicatedStorage.Generated.ClassMerge),
})

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TailwindRawRobloxDemo"
screenGui.ResetOnSpawn = false
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local online = true
local clicks = 0

local badge = tw.span("rounded-md px-2 py-1 text-xs font-medium bg-emerald-500/15 text-emerald-300", "Online")
local counter = tw.span("rounded-md bg-zinc-800 px-2 py-1 text-xs font-medium text-zinc-100", "Clicks: 0")

tw.div("flex flex-col gap-3 rounded-xl border border-zinc-800 bg-zinc-950 p-5", {
	Parent = screenGui,
	tw.div("flex items-center justify-between gap-2", {
		tw.span("text-base font-semibold text-zinc-50", "Raw Roblox + Tailwind"),
		badge,
	}),
	tw.p("text-sm text-zinc-400", "Styled with compiled Tailwind utilities in raw Luau — no React or manual host setup."),
	tw.div("flex items-center gap-2", {
		tw.button(
			"flex items-center justify-center rounded-lg bg-zinc-100 px-4 py-2 text-sm font-medium text-zinc-950 hover:bg-zinc-200 active:bg-zinc-300",
			{
				text = "Toggle status",
				onActivated = function()
					online = not online
					tw(badge, {
						className = if online
							then "bg-emerald-500/15 text-emerald-300"
							else "bg-amber-500/15 text-amber-300",
						text = if online then "Online" else "Away",
					})
				end,
			}
		),
		tw.button(
			"flex items-center justify-center rounded-lg border border-zinc-700 bg-transparent px-4 py-2 text-sm font-medium text-zinc-100 hover:bg-zinc-900",
			{
				text = "Count",
				onActivated = function()
					clicks += 1
					tw(counter, { text = `Clicks: {clicks}` })
				end,
			}
		),
		counter,
	}),
})
