import assert from "node:assert/strict";
import http from "node:http";
import { spawn } from "node:child_process";

const server = spawn(process.execPath, ["local-server.js"], {
  stdio: ["ignore", "pipe", "pipe"],
});

function waitForServer() {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error("local server did not start")), 5000);
    server.stdout.on("data", (chunk) => {
      if (chunk.toString().includes("Managed API prototype listening")) {
        clearTimeout(timer);
        resolve();
      }
    });
    server.once("error", reject);
  });
}

function request(path) {
  return new Promise((resolve, reject) => {
    const req = http.get(`http://localhost:4280${path}`, (res) => {
      let body = "";
      res.setEncoding("utf8");
      res.on("data", (chunk) => { body += chunk; });
      res.on("end", () => resolve({ status: res.statusCode, headers: res.headers, body }));
    });
    req.on("error", reject);
  });
}

try {
  await waitForServer();
  const health = await request("/api/health");
  assert.equal(health.status, 200);
  assert.equal(JSON.parse(health.body).status, "healthy");
  assert.ok(health.headers["x-request-id"]);

  const status = await request("/api/status");
  assert.equal(status.status, 200);
  assert.equal(JSON.parse(status.body).service, "managed-api");

  const items = await request("/api/items");
  assert.equal(items.status, 200);
  assert.equal(JSON.parse(items.body).items.length, 3);

  const frontend = await request("/");
  assert.equal(frontend.status, 200);
  assert.match(frontend.body, /fetch\("\/api\/health"\)/);

  console.log("PASS /api/health -> 200 with request ID");
  console.log("PASS /api/status -> 200");
  console.log("PASS /api/items -> 200 with three controls");
  console.log("PASS / -> 200 and same-origin API calls are wired");
} finally {
  server.kill();
}
