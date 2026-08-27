const express = require("express");
const crypto = require("crypto");
const cors = require("cors");

const app = express();
const port = process.env.PORT || 3001;

const localOrigins = ["http://localhost:3000", "http://127.0.0.1:3000"];
const configuredOrigins = (process.env.ALLOWED_ORIGINS || "")
  .split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);
const allowedOrigins = new Set([...localOrigins, ...configuredOrigins]);

app.disable("x-powered-by");
app.enable("trust proxy");
app.use(express.json({ limit: "32kb" }));
app.use(cors({
  origin(origin, callback) {
    if (!origin || allowedOrigins.has(origin)) {
      return callback(null, true);
    }

    return callback(new Error("Origin is not permitted by the API CORS policy."));
  },
  methods: ["GET", "OPTIONS"],
  allowedHeaders: ["Content-Type", "X-Request-ID"],
  maxAge: 86400
}));

app.use((req, res, next) => {
  const requestId = crypto.randomUUID();
  const startedAt = Date.now();

  res.setHeader("X-Request-ID", requestId);
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("Referrer-Policy", "no-referrer");
  res.setHeader("Cache-Control", "no-store");

  res.on("finish", () => {
    console.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      requestId,
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      durationMs: Date.now() - startedAt,
      deployment: process.env.WEBSITE_SITE_NAME ? "azure-app-service" : "local"
    }));
  });

  next();
});

app.get("/health", (req, res) => {
  res.status(200).json({
    status: "healthy",
    service: "secure-azure-backend",
    deployment: process.env.WEBSITE_SITE_NAME ? "azure-app-service" : "local"
  });
});

app.get("/api/status", (req, res) => {
  res.status(200).json({
    service: "backend-api",
    environment: process.env.NODE_ENV || "development",
    deployment: process.env.WEBSITE_SITE_NAME ? "azure-app-service" : "local",
    timestamp: new Date().toISOString()
  });
});

app.get("/api/items", (req, res) => {
  res.status(200).json({
    source: "local-static-data",
    items: [
      { id: 1, name: "Network segmentation" },
      { id: 2, name: "Least-privilege access" },
      { id: 3, name: "Threat detection" }
    ]
  });
});

app.use((error, req, res, next) => {
  if (error?.message === "Origin is not permitted by the API CORS policy.") {
    return res.status(403).json({ error: "Origin is not permitted." });
  }

  return next(error);
});

app.use((req, res) => {
  res.status(404).json({ error: "Route not found" });
});

app.listen(port, () => {
  console.log(`Backend API listening on port ${port}`);
});
