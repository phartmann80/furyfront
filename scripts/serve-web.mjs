import { createReadStream, existsSync, statSync } from "node:fs";
import { createServer } from "node:http";
import { extname, join, normalize } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(fileURLToPath(new URL("..", import.meta.url)), "export", "web");
const port = Number(process.env.PORT || 8088);

const types = {
  ".html": "text/html; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".json": "application/json",
  ".css": "text/css; charset=utf-8",
};

const server = createServer((req, res) => {
  const url = new URL(req.url || "/", "http://127.0.0.1");
  let rel = decodeURIComponent(url.pathname);
  if (rel === "/") rel = "/index.html";
  const file = join(root, normalize(rel).replace(/^(\.\.[/\\])+/, ""));
  if (!file.startsWith(root) || !existsSync(file) || statSync(file).isDirectory()) {
    res.writeHead(404);
    res.end("not found");
    return;
  }
  const ext = extname(file);
  const headers = {
    "Content-Type": types[ext] || "application/octet-stream",
    "Cache-Control": ext === ".html" ? "no-cache" : "public, max-age=3600",
    "X-FuryFront-Threads": "off",
  };
  res.writeHead(200, headers);
  createReadStream(file).pipe(res);
});

server.listen(port, "127.0.0.1", () => {
  if (!existsSync(join(root, "index.html"))) {
    console.warn("export/web/index.html missing — run Godot Web export first");
  }
  console.log(`Fury Front web  http://127.0.0.1:${port}/`);
});
