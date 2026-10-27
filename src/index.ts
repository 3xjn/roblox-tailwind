import { compile } from '@tailwindcss/node';
import { Scanner } from '@tailwindcss/oxide';
import { compileCss, inventoryStylesheet } from '@3xjn/roblox-css-compiler';
import { compileClassMerge, stylesheetClasses, type ClassMergeEngine } from './class-merge.js';
export { compileClassMerge } from './class-merge.js';
export type { ClassMergeMetadata, ClassMergeEngine } from './class-merge.js';

export interface TailwindOptions {
  css: string;
  base: string;
  /** Source name assigned to the generated CSS diagnostics. */
  from?: string;
  candidates?: string[];
  sources?: { content: string; extension: string }[];
  /** Defaults to true. Uses Oxide for Tailwind's automatic sources and @source. */
  scanFilesystem?: boolean;
  /** Called by Tailwind for dependencies such as imported theme files. */
  onDependency?: (file: string) => void;
  /** Generate runtime class composition for the compiled candidate scope. */
  classMerge?: { classLists?: readonly string[]; merge?: ClassMergeEngine };
}

/** Source discovery and class parsing both belong to the official Tailwind tools. */
export async function compileTailwind(options: TailwindOptions) {
  const dependencies = new Set<string>();
  const compiler = await compile(options.css, {
    base: options.base,
    onDependency(file) {
      dependencies.add(file);
      options.onDependency?.(file);
    },
  });
  const roots = compiler.root === 'none' ? [] : [compiler.root ?? { base: options.base, pattern: '**/*' }];
  const discoveredSources = [...roots.map(root => ({ ...root, negated: false })), ...compiler.sources];
  const scanner = new Scanner({ sources: options.scanFilesystem === false ? [] : discoveredSources });
  const candidates = new Set(options.candidates ?? []);
  if (options.scanFilesystem !== false) {
    for (const candidate of scanner.scan()) candidates.add(candidate);
  }
  for (const source of options.sources ?? []) {
    for (const occurrence of scanner.getCandidatesWithPositions(source)) candidates.add(occurrence.candidate);
  }
  const css = compiler.build([...candidates]);
  const stylesheet = await compileCss(css, { from: options.from ?? `${options.base}/tailwind.css` });
  return {
    css, stylesheet, inventory: inventoryStylesheet(stylesheet),
    candidates: [...candidates].sort(), dependencies: [...dependencies].sort(),
    sourceDirectives: compiler.sources, sourceRoot: compiler.root,
    scannedFiles: scanner.files,
    ...(options.classMerge ? { classMerge: compileClassMerge([
      ...candidates, ...stylesheetClasses(stylesheet), ...(options.classMerge.classLists ?? []),
    ], options.classMerge.merge) } : {}),
  };
}
