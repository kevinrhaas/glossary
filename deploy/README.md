# Deployment Scripts

This directory contains bulletproof deployment scripts for the Database Schema Glossary Generator.

## 🚀 Quick Start - Automated Deployment

### **Recommended Workflow:**

1. **Test deployment first:**
   ```bash
   ./deploy/99-deploy-full-ecs-test.sh
   ```

2. **Production deployment after testing:**
   ```bash
   ./deploy/99-deploy-full-ecs-production.sh
   ```

### **Interactive deployment (legacy):**
   ```bash
   ./deploy/99-deploy-full-interactive.sh
   ```

## 🎯 Automated Full Pipeline Scripts

### `99-deploy-full-ecs-test.sh` ✅ **RECOMMENDED**
- **Purpose**: Fully automated test environment deployment
- **No prompts**: Runs straight through to completion
- **Safe**: Deploys to test environment for validation
- **Usage**: `./deploy/99-deploy-full-ecs-test.sh`

### `99-deploy-full-ecs-production.sh` ⚠️ **PRODUCTION**
- **Purpose**: Fully automated production deployment
- **No prompts**: Runs straight through to completion  
- **Warning**: Deploys directly to production
- **Usage**: `./deploy/99-deploy-full-ecs-production.sh`

### `99-deploy-full-interactive.sh` 🤔 **INTERACTIVE**
- **Purpose**: Step-by-step deployment with user prompts
- **Prompts**: Asks for deployment target and confirmation at each step
- **Flexible**: Supports both ECS and App Runner deployments
- **Usage**: `./deploy/99-deploy-full-interactive.sh`

## 🚀 Environment-Aware Deployment

## Individual Scripts

### 1. Build and Test Locally
```bash
./deploy/01-build-and-test.sh
```
- Builds Docker image locally
- Tests the container on port 5001
- Verifies health and config endpoints

### 2. Push to AWS ECR
```bash
./deploy/02-push-to-ecr.sh [version]
```
- Creates ECR repository if needed
- Pushes Docker image with version tag and latest
- Saves image info for next steps

### 3a. Deploy to AWS ECS Fargate
```bash
./deploy/03-deploy-to-ecs.sh [environment]
```
- **Smart deployment**: Creates new service on first run, updates existing service on subsequent runs
- **Environment Support**: `test` (default), `staging`, `production`
- Creates ECS cluster, security group, IAM roles (first time only)
- **Examples**:
  - `./deploy/03-deploy-to-ecs.sh` → deploys to test (safe default)
  - `./deploy/03-deploy-to-ecs.sh production` → deploys to production
- **Rolling updates**: Updates existing service with zero downtime
- Sets up CloudWatch logging
- Returns public IP for testing

### 3b. Deploy to AWS App Runner (Alternative)
```bash
./deploy/03-deploy-to-apprunner.sh [environment]
```
- **Smart deployment**: Creates new service on first run, updates existing service on subsequent runs
- **Environment Support**: `test` (default), `staging`, `production`
- **Rolling updates**: App Runner handles zero-downtime updates automatically
- Auto-scaling and HTTPS included
- **Examples**:
  - `./deploy/03-deploy-to-apprunner.sh` → deploys to test (safe default)
  - `./deploy/03-deploy-to-apprunner.sh production` → deploys to production

### 4. Test Deployment
```bash
./deploy/04-test-deployment.sh
```
- Tests all endpoints
- Verifies database connectivity
- Checks AI API configuration

### 5. Cleanup Old Services
```bash
./deploy/cleanup-old-services.sh
```
- Safely removes old ECS service after testing
- Preserves new deployment

**Recommended Workflow:**
```bash
# 1. Deploy to test environment first (safe default)
./deploy/03-deploy-to-ecs.sh

# 2. Test your application thoroughly

# 3. Deploy to production when ready
./deploy/03-deploy-to-ecs.sh production
```

### 🎯 Environment Options

**Test Environment:**
- ECS Service: `glossary-service-test`
- App Runner: `glossary-apprunner-test`
- Safe for experimentation

**Production Environment:**
- ECS Service: `glossary-service`
- App Runner: `glossary-apprunner`
- Live user-facing services

### 📋 Manual Deployment (Advanced)

```bash
# Direct deployment with environment parameter
./deploy/03-deploy-to-ecs.sh [environment]
./deploy/03-deploy-to-apprunner.sh [environment]

# Valid environments: production, test
```

## 🔧 Setup

```bash
# 1. Set up your environment
cp .env.example .env
# Edit .env with your actual values

# 2. Run the full deployment pipeline (production)
./deploy/99-deploy-full.sh
```



## Configuration

The scripts use your `.env` file for configuration. Required variables:

```bash
DATABASE_URL=postgresql://user:pass@host:port/db?sslmode=require
API_BASE_URL=your-endpoint.azure-api.net/openai-presales
API_KEY=your-api-key
DATABASE_SCHEMA=your_schema  # optional
```

## AWS Configuration

Ensure AWS credentials are configured:

```bash
# Option 1: AWS CLI
aws configure

# Option 2: Okta/SSO
gimme-aws-creds --profile your-profile

# Verify
aws sts get-caller-identity
```

## Deployment Strategy

The scripts are **smart** and handle both first deployments and updates:

### **First Deployment:**
- ECS: Creates `glossary-service` (cluster, security group, IAM roles, etc.)
- App Runner: Creates `glossary-apprunner`

### **Subsequent Deployments:**
- ECS: Updates existing `glossary-service` with **rolling deployment** (zero downtime)
- App Runner: Updates existing `glossary-apprunner` with **rolling deployment** (zero downtime)

**No more creating new services every time!** The scripts detect if a service exists and update it intelligently.

## Safety Features

- ✅ **Smart deployment** - creates new service first time, updates existing service on subsequent runs
- ✅ **Rolling updates** - zero downtime deployments for both ECS and App Runner
- ✅ **Local testing** before AWS deployment
- ✅ **Health checks** at each step
- ✅ **Environment validation** - checks required variables
- ✅ **Confirmation prompts** for all deployment actions
- ✅ **Version tracking** - each deployment tagged with timestamp

## Troubleshooting

### Build Fails
- Check Dockerfile and requirements.txt
- Ensure `.env` file has required variables

### ECR Push Fails  
- Check AWS credentials: `aws sts get-caller-identity`
- Verify region settings

### ECS Deploy Fails
- Check VPC/subnet configuration
- Verify IAM permissions
- Check CloudWatch logs: `/ecs/glossary-v2`

### App Runner Deploy Fails
- Check ECR image URI
- Verify environment variables
- Check App Runner service logs in AWS Console

## Generated Files

The scripts create these files:
- `deploy/image-info.env` - ECR image URIs and version
- `deploy/deployment-info.env` - ECS deployment details  
- `deploy/apprunner-deployment-info.env` - App Runner details

## Clean Deployment Process

1. **Test locally** with Docker
2. **Push to ECR** with versioning
3. **Deploy to AWS** with new service name
4. **Test production** endpoints
5. **Clean up old** services (optional)
