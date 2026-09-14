# Secure Azure Managed API Prototype

This is an isolated, local-only prototype for evaluating an Azure Static Web Apps managed API. It is not connected to the user’s repository, GitHub remote, Azure subscription, deployment token, or live Static Web Apps site.

## Layout

| Path | Purpose |
|---|---|
| `api/handlers.js` | Reusable API behavior for health, status, and security-control items. |
| `api/src/functions/api.js` | Azure Functions v4 registrations used by the managed API model. |
| `public/index.html` | Static frontend using same-origin `/api/...` calls. |
| `public/staticwebapp.config.json` | Static Web Apps security and navigation configuration. |
| `.github/workflows/managed-api-preview.yml` | Non-deploying workflow preview that only validates paths and syntax. |
| `local-server.js` | Dependency-free local server emulating same-origin `/api` routing. |
| `test-local.js` | Local route and frontend compatibility tests. |

## Local validation

From this directory run:

```powershell
npm test
npm start
```

Then browse to `http://localhost:4280`. The browser page should load the frontend and call `/api/health`, `/api/status`, and `/api/items` on the same origin.

## Important boundary

This prototype intentionally does not include Azure SQL, a private endpoint, VNet integration, managed identity, provider registration, a deployment token, or an Azure deployment command. The original Express backend and full private-cloud Bicep designs remain separate in the real project.

The prototype answers one narrow question: can the current small API be reshaped into the `/api` handler model expected by Static Web Apps without App Service? It does not prove the full private database architecture.
