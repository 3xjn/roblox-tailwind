export interface ClassMergeMetadata {
  readonly version: number;
  readonly classes: readonly string[];
  readonly conflicts: readonly (readonly number[])[];
}
export type ClassMerger = (...classes: (string | undefined)[]) => string;
/** Compiled-scope class composition; unknown classes fail explicitly. */
export declare function createClassMerger(metadata: ClassMergeMetadata, options?: { readonly cacheSize?: number }): ClassMerger;

export interface ElementProps {
  readonly text?: string;
  readonly id?: string;
  readonly attributes?: Readonly<Record<string, string>>;
  readonly states?: Readonly<Record<string, boolean>>;
  readonly Parent?: Instance;
  readonly mount?: Instance;
  readonly onActivated?: () => void;
  readonly [index: number]: ElementHandle | undefined;
}

export interface ElementHandle {
  readonly tag: string;
  readonly className: string;
  readonly text?: string;
  readonly gui: () => GuiObject | undefined;
  readonly destroy: () => void;
}

export interface ElementUpdate {
  readonly className?: string;
  readonly text?: string;
  readonly attributes?: Readonly<Record<string, string>>;
  readonly states?: Readonly<Record<string, boolean>>;
}

export interface TailwindRuntime {
  (element: ElementHandle, update: string | ElementUpdate): ElementHandle;
  readonly cn: ClassMerger;
  readonly set: (element: ElementHandle, className: string) => ElementHandle;
  readonly mount: (target: Instance | undefined, root: ElementHandle) => () => void;
  readonly el: (tag: string, className?: string, propsOrText?: string | ElementProps) => ElementHandle;
  readonly div: (className?: string, propsOrText?: string | ElementProps) => ElementHandle;
  readonly span: (className?: string, propsOrText?: string | ElementProps) => ElementHandle;
  readonly p: (className?: string, propsOrText?: string | ElementProps) => ElementHandle;
  readonly button: (className?: string, propsOrText?: string | ElementProps) => ElementHandle;
  readonly input: (className?: string, propsOrText?: string | ElementProps) => ElementHandle;
  readonly img: (className?: string, propsOrText?: string | ElementProps) => ElementHandle;
}

export interface RuntimeConfig {
  readonly stylesheet: unknown;
  readonly classMerge?: ClassMergeMetadata;
  readonly css?: unknown;
  readonly primitives?: unknown;
  readonly hostOptions?: Readonly<Record<string, unknown>>;
}

export declare function create(config: RuntimeConfig): TailwindRuntime;
