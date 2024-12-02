# Azure Zero Trust Network Infrastructure

This repository contains Bicep templates that deploy basic application landing zone, including:

- Virtual Network with segregated subnets
- Application Gateway
- App Service with VNet integration
- Azure SQL Server with private endpoint
- Storage Account with private endpoint for SQL backups
- Network Security Groups with zero trust rules
- Application Security Groups
- Route Tables with custom routing
- Private DNS Zones (optional)

## Architecture

The infrastructure follows zero trust principles with:
- Isolated network segments
- Explicit allow rules using ASGs
- Private endpoints for PaaS services
- Custom routing for network traffic control
- Application Gateway as secure entry point
- Secure storage for SQL backups with private endpoint

## Prerequisites

- Azure subscription
- Azure CLI or PowerShell with Azure modules
- Contributor access to the target subscription/resource group

## Quick Deploy

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FYOURNAME%2FREPONAME%2Fmain%2Fmain.json)

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| environment | string | Environment name (dev/qa/prod) |
| location | string | Azure region for deployment |
| prefix | string | Prefix for resource names |
| sqlAdminPassword | securestring | SQL Server administrator password |
| appServiceSku | string | App Service Plan SKU (P1v2/P2v2/P3v2) |
| defaultRouteNextHopIp | string | Next hop IP for default route |
| tags | object | Resource tags |

## Manual Deployment

1. Clone the repository
2. Login to Azure CLI:
   ```bash
   az login
   ```
3. Set your subscription:
   ```bash
   az account set --subscription <subscription-id>
   ```
4. Create a resource group:
   ```bash
   az group create --name <resource-group-name> --location <location>
   ```
5. Deploy the Bicep template:
   ```bash
   az deployment group create \
     --resource-group <resource-group-name> \
     --template-file main.bicep \
     --parameters @parameters.json
   ```
6. Verify deployment:
   ```bash
   az deployment group show \
     --resource-group <resource-group-name> \
     --name <deployment-name>
   ```
