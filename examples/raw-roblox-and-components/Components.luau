--!strict
-- Reusable React Luau components styled with compiled Tailwind utilities
-- and runtime conflict resolution via Tailwind.createClassMerger.

local Components = {}

export type Dependencies = {
	React: any,
	cn: (...string?) -> string,
}

local BADGE_VARIANTS = {
	default = "bg-zinc-800 text-zinc-100",
	success = "bg-emerald-500/15 text-emerald-300",
	warning = "bg-amber-500/15 text-amber-300",
}

local BUTTON_VARIANTS = {
	primary = "bg-zinc-100 text-zinc-950 hover:bg-zinc-200 active:bg-zinc-300",
	outline = "border border-zinc-700 bg-transparent text-zinc-100 hover:bg-zinc-900",
}

function Components.create(deps: Dependencies)
	local React = deps.React
	local cn = deps.cn

	local function Badge(props: { variant: string?, className: string?, text: string })
		local variant = BADGE_VARIANTS[props.variant or "default"] or BADGE_VARIANTS.default
		return React.createElement("span", {
			className = cn("rounded-md px-2 py-1 text-xs font-medium", variant, props.className),
			text = props.text,
		})
	end

	local function Button(props: {
		variant: string?,
		className: string?,
		text: string,
		onActivated: (() -> ())?,
	})
		local variant = BUTTON_VARIANTS[props.variant or "primary"] or BUTTON_VARIANTS.primary
		return React.createElement("button", {
			className = cn(
				"flex items-center justify-center rounded-lg px-4 py-2 text-sm font-medium",
				variant,
				props.className
			),
			text = props.text,
			bindTarget = function(target: GuiObject)
				if target:IsA("GuiButton") and props.onActivated then
					local conn = target.Activated:Connect(props.onActivated)
					return function()
						conn:Disconnect()
					end
				end
				return nil
			end,
		})
	end

	local function StatusCard(props: { title: string, online: boolean, onToggle: () -> () })
		return React.createElement("div", {
			className = "flex flex-col gap-3 rounded-xl border border-zinc-800 bg-zinc-950 p-5",
		}, {
			Header = React.createElement("div", {
				className = "flex items-center justify-between gap-2",
			}, {
				Title = React.createElement("span", {
					className = "text-base font-semibold text-zinc-50",
					text = props.title,
				}),
				Status = React.createElement(Badge, {
					variant = if props.online then "success" else "warning",
					text = if props.online then "Online" else "Away",
				}),
			}),
			Body = React.createElement("p", {
				className = "text-sm text-zinc-400",
				text = "Composable components sharing the same compiled Tailwind stylesheet and class merger.",
			}),
			Actions = React.createElement("div", {
				className = "flex items-center gap-2",
			}, {
				Toggle = React.createElement(Button, {
					variant = "primary",
					className = "px-5",
					text = "Toggle status",
					onActivated = props.onToggle,
				}),
				Secondary = React.createElement(Button, {
					variant = "outline",
					text = "Secondary",
				}),
			}),
		})
	end

	return {
		Badge = Badge,
		Button = Button,
		StatusCard = StatusCard,
	}
end

return Components
