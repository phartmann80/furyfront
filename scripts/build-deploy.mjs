#!/usr/bin/env node
/**
 * Assemble Fury Front deploy bundle:
 *   web/site       → dist root (landing)
 *   assets         → media (hero video + poster — single copy each)
 *   export/web     → play/ (Godot build, commit-versioned filenames)
 *
 * Godot wasm/pck/js are renamed to index.<commit>.* so immutable caching
 * cannot serve mismatched engine artifacts across deployments.
 */
import {
  cpSync,
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  renameSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { execSync } from "node:child_process";

const root = join(fileURLToPath(new URL("..", import.meta.url)));
const out = join(root, "dist", "furyfront");
const site = join(root, "web", "site");
const gameExport = join(root, "export", "web");
const heroSrc = join(root, "assets", "hero-video", "hero.MP4");
const posterSrc = join(root, "assets", "breached_entrance.webp");

const SKIP_EXPORT = process.argv.includes("--skip-export");
const SKIP_VALIDATE = process.argv.includes("--skip-validate");

function gitSha(full = false) {
  try {
    const flag = full ? "" : "--short";
    return execSync(`git rev-parse ${flag} HEAD`, { cwd: root, encoding: "utf8" }).trim();
  } catch {
    return full ? "unknown" : "unknown";
  }
}

function gitBranch() {
  try {
    return execSync("git rev-parse --abbrev-ref HEAD", { cwd: root, encoding: "utf8" }).trim();
  } catch {
    return "unknown";
  }
}

function requirePath(path, label) {
  if (!existsSync(path)) {
    console.error(`Missing ${label}: ${path}`);
    process.exit(1);
  }
}

function runValidate() {
  console.log("→ validate");
  execSync("node scripts/validate.mjs", { cwd: root, stdio: "inherit" });
}

function runGodotExport() {
  console.log("→ Godot Web export");
  execSync('godot --headless --path game --export-release Web export/web/index.html', {
    cwd: root,
    stdio: "inherit",
  });
}

function copyGodotExport(playOut) {
  mkdirSync(playOut, { recursive: true });
  for (const name of readdirSync(gameExport)) {
    if (name.startsWith("playwright-") || name.endsWith(".png") && name.startsWith("playwright")) continue;
    if (/screenshot\.png$/i.test(name)) continue;
    cpSync(join(gameExport, name), join(playOut, name), { recursive: true });
  }
}

function versionGodotPlay(playDir, commit) {
  const slug = `index.${commit}`;
  const pairs = [
    ["index.wasm", `${slug}.wasm`],
    ["index.pck", `${slug}.pck`],
    ["index.js", `${slug}.js`],
  ];

  for (const [from, to] of pairs) {
    const src = join(playDir, from);
    if (!existsSync(src)) {
      console.error(`Missing Godot artifact: ${from}`);
      process.exit(1);
    }
    renameSync(src, join(playDir, to));
  }

  const htmlPath = join(playDir, "index.html");
  let html = readFileSync(htmlPath, "utf8");
  const configMatch = html.match(/const GODOT_CONFIG = (\{[\s\S]*?\});/);
  if (!configMatch) {
    console.error("Could not parse GODOT_CONFIG in play/index.html");
    process.exit(1);
  }

  const config = JSON.parse(configMatch[1]);
  const oldExe = config.executable || "index";
  config.executable = slug;

  const nextSizes = {};
  for (const [key, value] of Object.entries(config.fileSizes || {})) {
    nextSizes[key.replace(oldExe, slug)] = value;
  }
  config.fileSizes = nextSizes;

  html = html.replace(
    /const GODOT_CONFIG = \{[\s\S]*?\};/,
    `const GODOT_CONFIG = ${JSON.stringify(config)};`,
  );
  html = html.replace('src="index.js"', `src="${slug}.js"`);
  writeFileSync(htmlPath, html);

  return slug;
}

function stampSiteAssets(outDir, commit) {
  let html = readFileSync(join(outDir, "index.html"), "utf8");
  html = html.replace('href="/css/site.css"', `href="/css/site.css?v=${commit}"`);
  html = html.replace('src="/js/site.js"', `src="/js/site.js?v=${commit}"`);
  writeFileSync(join(outDir, "index.html"), html);
}

function dirBytes(dir) {
  let total = 0;
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const p = join(dir, entry.name);
    if (entry.isDirectory()) total += dirBytes(p);
    else total += statSync(p).size;
  }
  return total;
}

function fileManifest(baseDir, rel = "") {
  const manifest = {};
  for (const entry of readdirSync(baseDir, { withFileTypes: true })) {
    const relPath = rel ? `${rel}/${entry.name}` : entry.name;
    const abs = join(baseDir, entry.name);
    if (entry.isDirectory()) Object.assign(manifest, fileManifest(abs, relPath));
    else manifest[relPath.replace(/\\/g, "/")] = statSync(abs).size;
  }
  return manifest;
}

if (!SKIP_VALIDATE) runValidate();
if (!SKIP_EXPORT) runGodotExport();

requirePath(site, "site source");
requirePath(join(site, "index.html"), "site index.html");
requirePath(heroSrc, "hero video (assets/hero-video/hero.MP4)");
requirePath(posterSrc, "hero poster (assets/breached_entrance.webp)");
requirePath(gameExport, "Godot export directory");
requirePath(join(gameExport, "index.html"), "Godot export index.html");

const commit = gitSha();
const commitFull = gitSha(true);

rmSync(out, { recursive: true, force: true });
mkdirSync(join(out, "media"), { recursive: true });

cpSync(site, out, { recursive: true });
const playOut = join(out, "play");
copyGodotExport(playOut);
cpSync(heroSrc, join(out, "media", "hero.MP4"));
cpSync(posterSrc, join(out, "media", "hero-poster.webp"));

const godotSlug = versionGodotPlay(playOut, commit);
stampSiteAssets(out, commit);

const builtAt = new Date().toISOString();
const version = {
  status: "ok",
  service: "furyfront-web",
  version: "0.1.0",
  commit,
  commitFull,
  branch: gitBranch(),
  builtAt,
  deployedAt: null,
  domain: "furyfront.app",
  godotExecutable: godotSlug,
  threading: "off",
  paths: { site: "/", game: "/play/", health: "/health" },
};

writeFileSync(join(out, "version.json"), JSON.stringify(version, null, 2));
writeFileSync(join(out, "health.json"), JSON.stringify(version, null, 2));

const manifest = {
  commit,
  builtAt,
  files: fileManifest(out),
  sizes: {
    landingBytes: dirBytes(out) - dirBytes(playOut),
    playBytes: dirBytes(playOut),
    totalBytes: dirBytes(out),
  },
};
writeFileSync(join(out, "manifest.json"), JSON.stringify(manifest, null, 2));

console.log(`Fury Front deploy bundle → ${out}`);
console.log(`  commit ${commit}  branch ${version.branch}`);
console.log(`  Godot slug ${godotSlug}`);
console.log(`  landing ~${(manifest.sizes.landingBytes / 1024 / 1024).toFixed(2)} MB`);
console.log(`  /play/  ~${(manifest.sizes.playBytes / 1024 / 1024).toFixed(2)} MB`);
console.log(`  total   ~${(manifest.sizes.totalBytes / 1024 / 1024).toFixed(2)} MB`);
