import { app } from "@azure/functions";
import { health, status, items, withRequestId } from "../../handlers.js";

function response(result) {
  const enriched = withRequestId(result);
  return {
    status: enriched.status,
    headers: enriched.headers,
    jsonBody: enriched.body,
  };
}

app.http("health", {
  methods: ["GET"],
  authLevel: "anonymous",
  route: "health",
  handler: async () => response(await health()),
});

app.http("status", {
  methods: ["GET"],
  authLevel: "anonymous",
  route: "status",
  handler: async () => response(await status()),
});

app.http("items", {
  methods: ["GET"],
  authLevel: "anonymous",
  route: "items",
  handler: async () => response(await items()),
});
