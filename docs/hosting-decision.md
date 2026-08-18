# Hosting Decision: Static Web Apps Free

## Decision

The portfolio frontend is hosted on Azure Static Web Apps Free. The Node.js backend remains available and fully tested in the local development environment.

## Reason

The Azure free-trial subscription exposes an App Service B1 VM quota of zero in East US. The quota adjustment route redirected to subscription-upgrade documentation, so the B1 App Service deployment was not pursued to avoid enabling pay-as-you-go billing.

## Evidence

- Bicep network foundation deployed successfully: VNet, two NSGs, and three subnets.
- Local Node.js frontend and backend tested successfully at `localhost:3000` and `localhost:3001`.
- App Service Bicep template was validated and a what-if preview showed the intended hosting resources.
- Actual App Service deployment was blocked before resource creation by the B1 VM quota.

## Limitation

The public Static Web Apps frontend does not call the local backend because an Azure-hosted browser cannot reach a developer laptop at `localhost`. The frontend therefore displays the architecture and deployment status when hosted, while retaining live backend connectivity during local development.
