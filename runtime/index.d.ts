export interface ClassMergeMetadata {
  readonly version: number;
  readonly classes: readonly string[];
  readonly conflicts: readonly (readonly number[])[];
}
export type ClassMerger = (...classes: (string | undefined)[]) => string;
/** Compiled-scope class composition; unknown classes fail explicitly. */
export declare function createClassMerger(metadata: ClassMergeMetadata, options?: { readonly cacheSize?: number }): ClassMerger;
