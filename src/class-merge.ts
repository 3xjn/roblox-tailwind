import { twMerge } from 'tailwind-merge';
import type { Stylesheet } from '@3xjn/roblox-css-compiler';

/** One-based class indices, ready for Luau/JSON. No Tailwind grammar in the client. */
export interface ClassMergeMetadata {
  version: 1;
  classes: string[];
  conflicts: number[][];
}

export type ClassMergeEngine = (...classes: string[]) => string;

/**
 * Compile the directional conflicts of a configured tailwind-merge instance.
 * Its right-to-left algorithm only lets retained classes block earlier ones.
 * Unknown runtime classes are outside this compiled scope, not guessed utilities.
 */
export function compileClassMerge(classLists: Iterable<string>, merge: ClassMergeEngine = twMerge): ClassMergeMetadata {
  const classes = [...new Set([...classLists].flatMap(value => value.trim().split(/\s+/)).filter(Boolean))].sort();
  const conflicts = classes.map(later => {
    const blocked: number[] = [];
    classes.forEach((earlier, index) => {
      const output = merge(earlier, later);
      if (output === later) blocked.push(index + 1);
      else if (output !== `${earlier} ${later}`)
        throw new Error('The class merge engine changed its binary retention contract.');
    });
    return blocked;
  });
  return { version: 1, classes, conflicts };
}

/** Include custom CSS marker classes, not just generated utility subjects. */
export function stylesheetClasses(stylesheet: Stylesheet): string[] {
  const names = new Set<string>();
  const tokens = (items: readonly Record<string, unknown>[]) => {
    for (const item of items) {
      if (item.kind === 'class' && typeof item.value === 'string') names.add(item.value);
      if (Array.isArray(item.children)) tokens(item.children);
      const nth = item.nth as { of?: Record<string, unknown>[] } | undefined;
      if (nth?.of) tokens(nth.of);
    }
  };
  const nodes = (items: typeof stylesheet.nodes) => {
    for (const node of items) {
      if (node.kind === 'rule') for (const selector of node.selectors)
        tokens(selector.tokens as unknown as Record<string, unknown>[]);
      if ('children' in node) nodes(node.children);
    }
  };
  nodes(stylesheet.nodes);
  return [...names].sort();
}
