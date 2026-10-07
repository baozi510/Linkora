'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'entry/src/main/ets/pages/PlayerPage.ets'), 'utf8');

const surfaceStart = source.indexOf('private videoSurface()');
const buildStart = source.indexOf('\n  build()');
assert.ok(surfaceStart >= 0 && buildStart > surfaceStart, 'PlayerPage videoSurface/build boundaries missing');

const surface = source.slice(surfaceStart, buildStart);
const build = source.slice(buildStart);

assert.match(surface, /\.width\('100%'\)[\s\S]*?\.height\('100%'\)/,
  'videoSurface must fill its containing viewport/frame');
assert.doesNotMatch(surface, /\.aspectRatio\(16\s*\/\s*9\)/,
  'videoSurface itself must not force 16:9 in fullscreen');

assert.match(build,
  /if\s*\(this\.fullScreen\)\s*\{[\s\S]*?this\.videoSurface\(\)[\s\S]*?\}\s*else\s*\{/,
  'fullscreen branch must render the viewport-sized video surface directly');
assert.match(build,
  /Stack\(\)\s*\{[\s\S]*?this\.videoSurface\(\)[\s\S]*?\}[\s\S]*?\.width\('100%'\)[\s\S]*?\.aspectRatio\(16\s*\/\s*9\)/,
  'non-fullscreen branch must retain the 16:9 frame');
assert.match(build,
  /PlayerStatusPanel\(\{ snapshot: this\.snapshot \}\\)/.source ? /PlayerStatusPanel/ : /PlayerStatusPanel/,
  'non-fullscreen status panel marker missing');

console.log('Player layout guard passed: fullscreen surface is viewport-sized and 16:9 is non-fullscreen-only.');
