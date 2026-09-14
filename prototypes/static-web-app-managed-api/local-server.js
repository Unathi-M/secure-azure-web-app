import http from "node:http";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { health, status, items, withRequestId } from "./api/handlers.js";

const root = path.dirname(fileURLToPath(import.meta.url));
const publicDir = path.join(root, "public");
const port = Number(process.env.PORT || 4280);

const routes = {
  "/api/health": health,
  "/api/status": status,
  "/api/items": items,
};

function writeJson(res, result) {
  const enriched = withRequestId(result);
  res.writeHead(enriched.status, enriched.headers);
  res.end(JSON.stringify(enriched.body));
}

async function serveStatic(req, res) {
  const requested = req.url === "/" ? "/index.html" : req.url;
  const safePath = path.normalize(requested).replace(/^([.][.][\\/])+/, "");
  const filePath = path.join(publicDir, safePath);

  try {
    const content = await fs.readFile(filePath);
    const contentType = filePath.endsWith(".html") ? "text/html; charset=utf-8" : "application/octet-stream";
    res.writeHead(200, {
      "content-type": contentType,
      "x-content-type-options": "nosniff",
    });
    res.end(content);
  } catch {
    res.writeHead(404, { "content-type": "application/json; charset=utf-8" });
    res.end(JSON.stringify({ error: "Not found" }));
  }
}

const server = http.createServer(async (req, res) => {
  if (req.method === "GET" && routes[req.url]) {
    writeJson(res, await routes[req.url]());
    return;
  }

  if (req.method === "GET") {
    await serveStatic(req, res);
    return;
  }

  res.writeHead(405, { "content-type": "application/json; charset=utf-8" });
  res.end(JSON.stringify({ error: "Method not allowed" }));
});

server.listen(port, () => {
  console.log(`Managed API prototype listening on http://localhost:${port}`);
});
