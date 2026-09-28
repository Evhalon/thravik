// Downloads Chrome's DevTools frontend at one pinned revision into
// Sources/RedentEngine/DevToolsFrontend, the copy Redent shows docked under a
// page. Google serves the built frontend per revision but publishes no
// archive, so this walks it from its entry page, following every module,
// style sheet, image and data file a file refers to.
//
//   node Tools/devtools-frontend/fetch.mjs [revision]
//
// Commit the result with the revision below. The frontend is Chromium's
// (BSD-3-Clause); its LICENSE is fetched alongside it.
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const REVISION = process.argv[2] ?? "ab3ecba863fd7852cc9b0fe5736187e19ed52a1c";
const BASE = `https://chrome-devtools-frontend.appspot.com/serve_rev/@${REVISION}/`;
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../Sources/RedentEngine/DevToolsFrontend");
const ENTRY = "devtools_app.html";
// Built from a template at run time, so no file names them: the English
// strings — Redent ships English only, and sets DevTools to it on first run —
// and the icons, whose names are listed in the frontend's own repository.
const ICONS = "https://api.github.com/repos/ChromeDevTools/devtools-frontend/contents/front_end/Images/src";

async function extraFiles() {
  const icons = await (await fetch(ICONS)).json();
  return ["core/i18n/locales/en-US.json", ...icons.map((icon) => `Images/${icon.name}`)];
}
const LICENSE = "https://chromium.googlesource.com/devtools/devtools-frontend/+/refs/heads/main/LICENSE?format=TEXT";
const REFERENCE = /(?:["'`])((?:\.{1,2}\/|[\w@-]+\/)[\w@./-]*\.(?:js|css|svg|png|avif|json|html|wasm|woff2|txt))(?:["'`?#])/g;
const CSS_URL = /url\(\s*["']?([^"')]+?)["']?\s*\)/g;

const seen = new Set();
const missing = [];

function resolve(from, reference) {
  if (/^(data|https?|blob|devtools|chrome):/.test(reference)) return null;
  const url = new URL(reference, BASE + from);
  if (!url.href.startsWith(BASE)) return null;
  return decodeURIComponent(url.pathname.slice(new URL(BASE).pathname.length));
}

async function fetchFile(file) {
  const response = await fetch(BASE + file, { signal: AbortSignal.timeout(30_000) }).catch(() => null);
  if (!response?.ok) {
    missing.push(file);
    return null;
  }
  const bytes = Buffer.from(await response.arrayBuffer());
  await fs.mkdir(path.join(ROOT, path.dirname(file)), { recursive: true });
  await fs.writeFile(path.join(ROOT, file), bytes);
  return bytes;
}

function references(file, text) {
  const found = [];
  for (const match of text.matchAll(REFERENCE)) found.push(match[1]);
  if (file.endsWith(".css") || file.endsWith(".js")) for (const match of text.matchAll(CSS_URL)) found.push(match[1]);
  return found.map((ref) => resolve(file, ref)).filter(Boolean);
}

async function walk() {
  const queue = [ENTRY, ...(await extraFiles())];
  while (queue.length) {
    const batch = queue.splice(0, 48).filter((file) => !seen.has(file));
    batch.forEach((file) => seen.add(file));
    const results = await Promise.all(batch.map(async (file) => [file, await fetchFile(file)]));
    process.stderr.write(`\r${seen.size} seen, ${queue.length} queued, ${missing.length} missing`);
    for (const [file, bytes] of results) {
      if (!bytes || !/\.(js|css|html|json)$/.test(file)) continue;
      for (const next of references(file, bytes.toString("utf8"))) if (!seen.has(next)) queue.push(next);
    }
  }
}

await fs.rm(ROOT, { recursive: true, force: true });
await walk();
const license = await fetch(LICENSE);
if (license.ok) await fs.writeFile(path.join(ROOT, "LICENSE"), Buffer.from(await license.text(), "base64"));
await fs.writeFile(path.join(ROOT, "REVISION"), REVISION + "\n");
console.log(`${seen.size - missing.length} files, ${missing.length} not found`);
if (missing.length) console.log(missing.slice(0, 20).join("\n"));
