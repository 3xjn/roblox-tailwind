import React from '@rbxts/react';

export interface StatusCardProps {
  title: string;
  online: boolean;
  className?: string;
  onToggle: () => void;
  cn: (...classes: (string | undefined)[]) => string;
}

export function StatusCard({ title, online, className, onToggle, cn }: StatusCardProps) {
  return (
    <div className={cn('flex flex-col gap-3 rounded-xl border border-zinc-800 bg-zinc-950 p-5', className)}>
      <div className="flex items-center justify-between gap-2">
        <span className="text-base font-semibold text-zinc-50">{title}</span>
        <span
          className={cn(
            'rounded-md px-2 py-1 text-xs font-medium',
            online ? 'bg-emerald-500/15 text-emerald-300' : 'bg-amber-500/15 text-amber-300',
          )}
        >
          {online ? 'Online' : 'Away'}
        </span>
      </div>
      <p className="text-sm text-zinc-400">
        TSX component styled with compiled Tailwind utilities and runtime class merging.
      </p>
      <div className="flex items-center gap-2">
        <button
          className={cn(
            'flex items-center justify-center rounded-lg px-4 py-2 text-sm font-medium',
            'bg-zinc-100 text-zinc-950 hover:bg-zinc-200 active:bg-zinc-300',
          )}
          onClick={onToggle}
        >
          Toggle status
        </button>
        <button className="flex items-center justify-center rounded-lg border border-zinc-700 bg-transparent px-4 py-2 text-sm font-medium text-zinc-100 hover:bg-zinc-900">
          Secondary
        </button>
      </div>
    </div>
  );
}
