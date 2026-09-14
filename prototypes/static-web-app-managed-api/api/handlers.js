const controls = [
  { id: 1, name: "Network segmentation" },
  { id: 2, name: "Least-privilege access" },
  { id: 3, name: "Threat detection" },
];

function requestId() {
  return crypto.randomUUID();
}

import crypto from "node:crypto";

export async function health() {
  return {
    status: 200,
    body: {
      status: "healthy",
      service: "secure-azure-managed-api",
      deployment: "local-prototype",
    },
  };
}

export async function status() {
  return {
    status: 200,
    body: {
      service: "managed-api",
      environment: process.env.NODE_ENV || "development",
      timestamp: new Date().toISOString(),
    },
  };
}

export async function items() {
  return {
    status: 200,
    body: { items: controls },
  };
}

export function withRequestId(result) {
  return {
    ...result,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "x-request-id": requestId(),
    },
  };
}
