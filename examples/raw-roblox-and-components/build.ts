import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { compileTailwind } from '../../dist/index.js';

const dir = path.dirname(fileURLToPath(import.meta.url));
const css = fs.readFileSync(path.join(dir, 'styles.css'), 'utf8');
const rawHostSource = fs.readFileSync(path.join(dir, 'RawRobloxHost.client.luau'), 'utf8');
const componentsSource = fs.readFileSync(path.join(dir, 'Components.luau'), 'utf8');
const tsxSource = fs.readFileSync(path.join(dir, 'StatusCard.tsx'), 'utf8');

const build = await compileTailwind({
  css,
  base: dir,
  from: 'styles.css',
  scanFilesystem: false,
  sources: [
    { content: rawHostSource, extension: 'luau' },
    { content: componentsSource, extension: 'luau' },
    { content: tsxSource, extension: 'tsx' },
  ],
  classMerge: {},
});

const outDir = path.join(dir, 'generated');
fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(path.join(outDir, 'Stylesheet.json'), JSON.stringify(build.stylesheet, null, 2));
fs.writeFileSync(path.join(outDir, 'ClassMerge.json'), JSON.stringify(build.classMerge, null, 2));

console.log(JSON.stringify({
  candidates: build.candidates.length,
  rules: build.inventory.rules,
  declarations: build.inventory.declarations,
  mergeGroups: build.classMerge ? Object.keys(build.classMerge.conflicts).length : 0,
}));
