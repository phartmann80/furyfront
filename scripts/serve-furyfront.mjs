#!/usr/bin/env node
/**
 * Fury Front unified server — site + Godot web game + health.
 * Production target: our own HTTPS infrastructure at furyfront.app.
 * Not Vercel/Netlify-dependent.
 */
import { createReadStream, existsSync, readFileSync, statSync } from "node:fs";
import { createServer } from "node:http";
import { extname, join, normalize } from "node:path";
import { fileURLToPath } from "node:url";
import { createGzip } from "node:zlib";

const root = join(fileURLToPath(new URL("..", import.meta.url)), "dist", "furyfront");
const port = Number(process.env.PORT || 8080);
const host = process.env.HOST || "127.0.0.1";

const types = {
  ".html": "text/html; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".png": "image/png",
  ".webp": "image/webp",
  ".svg": "image/svg+xml",
  ".json": "application/json",
  ".css": "text/css; charset=utf-8",
  ".mp4": "video/mp4",
  ".MP4": "video/mp4",
};

const gzipExts = new Set([".js", ".wasm", ".css", ".html", ".json", ".svg"]);

function securityHeaders(extra = {}) {
  return {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "SAMEORIGIN",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
    "X-FuryFront-Threads": "off",
    ...extra,
  };
}

function cacheFor(ext, rel, basename) {
  if (rel === "/health" || rel === "/version.json" || rel === "/manifest.json") {
    return "no-cache, must-revalidate";
  }
  if (ext === ".html") return "no-cache, must-revalidate";
  // Commit-versioned Godot engine bundle — safe to cache immutably
  if (/^index\.[0-9a-f]+\.(wasm|js|pck)$/i.test(basename)) {
    return "public, max-age=31536000, immutable";
  }
  if (rel.startsWith("/media/")) {
    return "public, max-age=31536000, immutable";
  }
  if (rel.startsWith("/css/") || rel.startsWith("/js/")) {
    return "public, max-age=3600, must-revalidate";
  }
  if (rel.startsWith("/play/")) {
    return "public, max-age=0, must-revalidate";
  }
  return "public, max-age=3600, must-revalidate";
}

function resolveFile(urlPath) {
  let rel = decodeURIComponent(urlPath);
  if (rel.endsWith("/")) rel += "index.html";
  if (rel === "/") rel = "/index.html";

  const file = join(root, normalize(rel).replace(/^(\.\.[/\\])+/, ""));
  if (!file.startsWith(root) || !existsSync(file) || statSync(file).isDirectory()) {
    return null;
  }
  return file;
}

function sendFile(req, res, file) {
  const ext = extname(file);
  const rel = req.url?.split("?")[0] || "/";
  const basename = file.split(/[/\\]/).pop() || "";
  const stat = statSync(file);
  const headers = securityHeaders({
    "Content-Type": types[ext] || "application/octet-stream",
    "Cache-Control": cacheFor(ext, rel, basename),
    "Accept-Ranges": "bytes",
  });

  const range = req.headers.range;
  if (range && stat.size > 0) {
    const match = /^bytes=(\d*)-(\d*)$/.exec(range);
    if (match) {
      const start = match[1] ? parseInt(match[1], 10) : 0;
      const end = match[2] ? parseInt(match[2], 10) : stat.size - 1;
      if (start <= end && end < stat.size) {
        res.writeHead(206, {
          ...headers,
          "Content-Range": `bytes ${start}-${end}/${stat.size}`,
          "Content-Length": end - start + 1,
        });
        createReadStream(file, { start, end }).pipe(res);
        return;
      }
    }
  }

  const accept = req.headers["accept-encoding"] || "";
  const canGzip = accept.includes("gzip") && gzipExts.has(ext) && stat.size > 512;

  if (canGzip) {
    res.writeHead(200, { ...headers, "Content-Encoding": "gzip", "Vary": "Accept-Encoding" });
    createReadStream(file).pipe(createGzip()).pipe(res);
    return;
  }

  res.writeHead(200, { ...headers, "Content-Length": stat.size });
  createReadStream(file).pipe(res);
}

const server = createServer((req, res) => {
  const url = new URL(req.url || "/", `http://${host}`);

  if (url.pathname === "/health") {
    let payload = {};
    try {
      payload = JSON.parse(readFileSync(join(root, "health.json"), "utf8"));
    } catch {
      try {
        payload = JSON.parse(readFileSync(join(root, "version.json"), "utf8"));
      } catch {
        payload = { status: "error", commit: "unknown" };
      }
    }
    const body = JSON.stringify({ ...payload, uptime_s: Math.floor(process.uptime()) });
    res.writeHead(200, securityHeaders({
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-cache, must-revalidate",
    }));
    res.end(body);
    return;
  }

  const file = resolveFile(url.pathname);
  if (!file) {
    res.writeHead(404, securityHeaders());
    res.end("not found");
    return;
  }

  sendFile(req, res, file);
});

server.listen(port, host, () => {
  if (!existsSync(join(root, "index.html"))) {
    console.warn("dist/furyfront missing — run: node scripts/build-deploy.mjs");
  }
  console.log(`Fury Front  http://${host}:${port}/`);
  console.log(`  Play       http://${host}:${port}/play/`);
  console.log(`  Health     http://${host}:${port}/health`);
});
