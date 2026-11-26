# Tailwind with raw Roblox Luau and React components

This example shows how to compile Tailwind utilities once on Node.js with `@3xjn/roblox-tailwind` and consume the generated stylesheet and class merger in two ways:

1. **[RawRobloxHost.client.luau](RawRobloxHost.client.luau)** — Pure Roblox Luau using `@3xjn/roblox-css` (`Css.createHost`) directly on a `ScreenGui` with no React dependency.
2. **[Components.luau](Components.luau)** — Reusable React Luau components (`Badge`, `Button`, `StatusCard`) with variant maps and `className` override merging via `Tailwind.createClassMerger`.

## Build the stylesheet and class-merge data

From the `roblox-tailwind` repository root:

```sh
npm run build
node --experimental-strip-types examples/raw-roblox-and-components/build.ts
```

This scans both Luau files with Tailwind's Oxide scanner, compiles the generated CSS into the Roblox CSS stylesheet format, and writes `generated/Stylesheet.json` and `generated/ClassMerge.json` (which Rojo maps directly into Luau `ModuleScript`s).
