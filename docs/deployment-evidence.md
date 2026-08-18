# Deployment Evidence

## Public frontend

- **Hosting service:** Azure Static Web Apps Free
- **Public URL:** https://thankful-dune-09f3e2d0f.7.azurestaticapps.net
- **Deployment source:** GitHub repository `Unathi-M/secure-azure-web-app`, branch `main`
- **CI/CD workflow:** Azure Static Web Apps CI/CD via GitHub Actions
- **Verification date:** 18 August 2026

## Verification results

The public site loaded successfully over HTTPS and displayed the `Hosted frontend ready` status. GitHub Actions reported a successful Azure Static Web Apps CI/CD workflow run.

## Architecture boundary

The public frontend is hosted on Azure Static Web Apps Free. The Node.js/Express backend remains a local, validated component because the Azure free-trial subscription exposed a B1 App Service quota of zero in East US. The B1 deployment was rejected before hosting resources were created, and the project intentionally did not upgrade to pay-as-you-go billing.

## Azure resources currently retained

- Azure Static Web Apps Free frontend
- Azure Virtual Network network foundation
- Two Network Security Groups

No virtual machine, B1 App Service plan, Azure SQL database, private endpoint, Log Analytics workspace, or Microsoft Sentinel resource was created.
