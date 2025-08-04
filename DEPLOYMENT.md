# AWS Deployment Guide

**🎯 For bulletproof deployment, use the automated deployment scripts in the `deploy/` directory.**

## Quick Deployment

```bash
# 1. Set up environment
cp .env.example .env
# Edit .env with your values

# 2. Run full deployment pipeline
./deploy/deploy-full.sh
```

This runs a complete, tested deployment process with safety checks and rollback capability.

See `deploy/README.md` for detailed documentation.

## Manual Deployment Steps

If you prefer manual deployment, follow the individual steps below.

## Option 1: AWS App Runner (Recommended - Simplest)

AWS App Runner is the easiest way to deploy containerized applications.

### Prerequisites
- AWS CLI installed and configured
- Docker installed locally
- AWS credentials configured (see AWS Configuration section below)

## AWS Configuration

### Option A: gimme-aws-creds with Okta (Recommended for Hitachi Vantara)

This is the best solution for your Hitachi Vantara Okta setup:

1. **Configure gimme-aws-creds:**
```bash
gimme-aws-creds --action-configure
```

When prompted, enter:
- **Okta organization URL**: `hitachivantara.okta.com`
- **Okta username**: `kevin.haas@hitachivantara.com`
- **Okta app URL**: `https://hitachivantara.okta.com/home/amazon_aws/0oa155ztg8DWyKy732p7/272`
- **AWS profile name**: `hitachi-vantara` (or your preference)

2. **Get AWS credentials:**
```bash
gimme-aws-creds --profile hitachi-vantara
```

This will prompt for your Okta password and MFA, then automatically set up your AWS credentials.

3. **Test the configuration:**
```bash
aws sts get-caller-identity --profile hitachi-vantara
```

### Option B: Manual Temporary Credentials (Alternative)

If gimme-aws-creds doesn't work:

1. **Get temporary credentials from Okta:**
   - Go to: `https://hitachivantara.okta.com/home/amazon_aws/0oa155ztg8DWyKy732p7/272`
   - Click on your AWS account role
   - Copy the temporary credentials

2. **Set environment variables:**
```bash
export AWS_ACCESS_KEY_ID="your-temp-access-key"
export AWS_SECRET_ACCESS_KEY="your-temp-secret-key" 
export AWS_SESSION_TOKEN="your-temp-session-token"
export AWS_DEFAULT_REGION="us-east-1"
```

### Verify Configuration

```bash
aws sts get-caller-identity
```

This should return your account information: `729973546399`

### Steps

1. **Build and push to ECR:**

**If using AWS SSO/Okta:**
```bash
# Login to your SSO session first
aws sso login --profile default

# Create ECR repository
aws ecr create-repository --repository-name glossary-generator

# Get your account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)

# Get login token (works with SSO)
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build and tag image
docker build -t glossary-generator .
docker tag glossary-generator:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/glossary-generator:latest

# Push image
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/glossary-generator:latest
```

**If using IAM access keys:**
```bash
# Create ECR repository
aws ecr create-repository --repository-name glossary-generator

# Get login token
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

# Build and tag image
docker build -t glossary-generator .
docker tag glossary-generator:latest YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/glossary-generator:latest

# Push image
docker push YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/glossary-generator:latest
```

2. **Create App Runner service:**
```bash
# Using AWS Console (easier):
# 1. Go to AWS App Runner console
# 2. Create service
# 3. Choose "Container registry" -> ECR
# 4. Select your image
# 5. Set environment variables:
#    - DATABASE_URL
#    - API_BASE_URL  
#    - API_KEY
# 6. Deploy

# OR using CLI:
aws apprunner create-service \
  --service-name glossary-generator \
  --source-configuration '{
    "ImageRepository": {
      "ImageIdentifier": "YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/glossary-generator:latest",
      "ImageConfiguration": {
        "Port": "5000",
        "RuntimeEnvironmentVariables": {
          "DATABASE_URL": "postgresql://user:pass@host:5432/db?sslmode=require",
          "API_BASE_URL": "your-endpoint.azure-api.net/openai-presales",
          "API_KEY": "your-api-key",
          "DATABASE_SCHEMA": "your-schema-name"
        }
      },
      "ImageRepositoryType": "ECR"
    },
    "AutoDeploymentsEnabled": false
  }' \
  --instance-configuration '{
    "Cpu": "0.25 vCPU",
    "Memory": "0.5 GB"
  }'
```

### Costs
- ~$7-15/month for small workloads
- Pay only for what you use
- Automatic scaling

---

## Option 2: AWS ECS Fargate

More control and configuration options.

### Steps

1. **Push image to ECR** (same as Option 1)

2. **Create ECS Cluster:**
```bash
aws ecs create-cluster --cluster-name glossary-cluster --capacity-providers FARGATE
```

3. **Store secrets in Parameter Store:**
```bash
aws ssm put-parameter --name "/glossary/database-url" --value "your-database-url" --type "SecureString"
aws ssm put-parameter --name "/glossary/api-key" --value "your-api-key" --type "SecureString"  
aws ssm put-parameter --name "/glossary/api-base-url" --value "your-api-endpoint" --type "String"
```

4. **Update task definition:**
- Edit `ecs-task-definition.json`
- Replace `YOUR_ACCOUNT` with your AWS account ID
- Replace `YOUR_ECR_REPO_URI` with your ECR repository URI

5. **Register task definition and create service:**
```bash
aws ecs register-task-definition --cli-input-json file://ecs-task-definition.json

aws ecs create-service \
  --cluster glossary-cluster \
  --service-name glossary-service \
  --task-definition glossary-generator:1 \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}"
```

### Costs
- ~$15-30/month for always-on service
- More predictable pricing

---

## Option 3: AWS Lambda + API Gateway (Serverless)

For sporadic usage patterns.

### Prerequisites
```bash
pip install zappa
```

### Steps

1. **Create zappa_settings.json:**
```json
{
  "production": {
    "app_function": "app.app",
    "aws_region": "us-east-1",
    "runtime": "python3.9",
    "environment_variables": {
      "DATABASE_URL": "postgresql://user:pass@host:5432/db?sslmode=require",
      "API_BASE_URL": "your-endpoint.azure-api.net/openai-presales", 
      "API_KEY": "your-api-key",
      "DATABASE_SCHEMA": "your-schema-name"
    }
  }
}
```

2. **Deploy:**
```bash
zappa deploy production
```

### Costs
- Pay per request (~$0.20 per 1M requests)
- Best for infrequent usage

---

## Environment Variables

Your application uses environment variables for all configuration (12-Factor App compliant):

### Required Environment Variables
- `DATABASE_URL` - PostgreSQL connection string
- `API_BASE_URL` - AI API endpoint  
- `API_KEY` - AI API authentication key

### Optional Environment Variables (with defaults)
- `DATABASE_SCHEMA` - Database schema name
- `API_DEPLOYMENT_ID` - API deployment ID (default: "model-router")
- `API_VERSION` - API version (default: "2025-01-01-preview")
- `API_MAX_TOKENS` - Max response tokens (default: 8192)
- `API_TEMPERATURE` - AI temperature (default: 0.7)
- `API_TIMEOUT` - Request timeout in seconds (default: 60.0)
- `API_MAX_RETRIES` - Max retry attempts (default: 3)
- `API_PROMPT_TEMPLATE` - Custom AI prompt template
- `PORT` - Server port (default: 5000)

### Local Development Setup

1. **Copy the environment template:**
```bash
cp .env.example .env
```

2. **Edit `.env` with your actual values:**
```bash
# Example .env file
DATABASE_URL=postgresql://user:pass@host:5432/dbname?sslmode=require
DATABASE_SCHEMA=your_schema
API_BASE_URL=your-endpoint.azure-api.net/openai-presales  
API_KEY=your-actual-api-key
```

3. **The app automatically loads `.env` for local development**

### Production Deployment

**Never commit `.env` files or `config.json` files with real credentials to git.**

For production, set environment variables directly in your deployment platform:

---

## Security Best Practices

1. **Use AWS Systems Manager Parameter Store** for secrets
2. **Enable VPC** for database connections
3. **Use IAM roles** instead of access keys where possible
4. **Enable CloudWatch logging** for monitoring
5. **Set up health checks** for high availability

---

## Monitoring

Your service includes these endpoints:
- `/health` - Health check with database connectivity
- `/config` - Complete configuration showing sources (environment variables vs defaults)  
- `/analyze` - POST endpoint for AI-powered glossary generation
- `/docs` - API documentation

The `/config` endpoint shows:
- Which settings come from environment variables vs defaults
- Masked sensitive values for security  
- Setup help and required variables
- Summary of configuration sources

## Recommendation

**Start with AWS App Runner** - it's the simplest option and handles most of the infrastructure automatically. You can always migrate to ECS or Lambda later if you need more control or different pricing models.
