# Roblox Tailwind

Compile Tailwind sources into the shared Roblox CSS runtime's data format.
Source discovery and utility generation use Tailwind's official compiler and
Oxide scanner. This package does not compile React component behavior.

```ts
import { compileTailwind } from '@3xjn/roblox-tailwind';

const build = await compileTailwind({
  css: '@import "tailwindcss";',
  base: process.cwd(),
  candidates: ['p-2', 'p-4'],
  scanFilesystem: false,
  classMerge: {},
});
```

Save `build.stylesheet` and optional `build.classMerge` as runtime data. Real
projects can provide source text through `sources` or enable filesystem scanning.
The Coss demo build shows the existing Rojo data-module setup.

## Class composition

The Roblox model includes a `Tailwind` module. Create one merger from the
generated metadata and share it with your components:

```luau
local merge = Tailwind.createClassMerger(classMergeMetadata)
assert(merge("p-2", "p-4") == "p-4")
```

The build derives directional conflicts from `tailwind-merge`; the client uses
that data and a bounded cache. No JavaScript or Tailwind grammar runs in Roblox.
Only classes in the compiled scope are accepted. Include dynamic alternatives
in `candidates` or `classMerge.classLists`; unknown tokens fail explicitly.
Opaque marker classes retain the merge engine's behavior, including duplicates.

For a prefix or custom merge groups, pass a configured `tailwind-merge` function
as `classMerge.merge`. `compileClassMerge(classLists, merger)` is also available
when composing the build stages separately. Matching the merge configuration to
your theme is the caller's responsibility.

Conflict compilation compares class pairs, so its build cost grows quadratically
with the scoped class count. It is opt-in and runs outside Roblox. The default
runtime cache holds fewer than 1,000 entries; `cacheSize = 0` disables it.
Class composition does not establish support for the resulting CSS or component
behavior. Those still pass through the compiler, runtime and native adapters.

## Repository setup

This repository contains the `@3xjn/roblox-tailwind` package. It is in active development and has not been published to npm.

Related packages:

- [@3xjn/roblox-css-compiler](https://github.com/3xjn/roblox-css-compiler)

Authenticate Git with GitHub before running `npm install`; development dependencies use the related private GitHub repositories.

Run `npm install` and `npm run build` to compile the TypeScript package. Git installations build its compiled JavaScript through the `prepare` script.

The development gallery and cross-package tests remain in the private [roblox-styling workspace](https://github.com/3xjn/roblox-styling).
