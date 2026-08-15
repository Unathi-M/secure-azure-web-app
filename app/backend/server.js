const express = require("express");
const crypto = require("crypto");
const cors = require("cors");

const app = express();
const port = process.env.PORT || 3001;

app.use(express.json());
app.use(cors());

app.use((req, res, next) => {
  const requestId = crypto.randomUUID();
  const startedAt = Date.now();

  res.setHeader("X-Request-ID", requestId);

  res.on("finish", () => {
    const durationMs = Date.now() - startedAt;
    console.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      requestId,
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      durationMs
    }));
  });

  next();
});

app.get("/health", (req, res) => {
  res.status(200).json({
    status: "healthy",
    service: "secure-azure-backend"
  });
});

app.get("/api/status", (req, res) => {
  res.status(200).json({
    service: "backend-api",
    environment: process.env.NODE_ENV || "development",
    timestamp: new Date().toISOString()
  });
});

app.get("/api/items", (req, res) => {
  res.status(200).json({
    items: [
      { id: 1, name: "Network segmentation" },
      { id: 2, name: "Least-privilege access" },
      { id: 3, name: "Threat detection" }
    ]
  });
});

app.use((req, res) => {
  res.status(404).json({ error: "Route not found" });
});

app.listen(port, () => {
  console.log(`Backend API listening on http://localhost:${port}` );
});
