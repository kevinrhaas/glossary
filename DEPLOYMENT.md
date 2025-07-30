# AWS Deployment Guide

This guide covers the most straightforward ways to deploy your Database Schema Glossary Generator microservice on AWS.

## Option 1: AWS App Runner (Recommended - Simplest)

AWS App Runner is the easiest way to deploy containerized applications.

### Prerequisites
- AWS CLI installed and configured
- Docker installed locally

### Steps

1. **Build and push to ECR:**
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
          "DATABASE_URL": "your-database-url",
          "API_BASE_URL": "your-api-endpoint",
          "API_KEY": "your-api-key"
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
      "DATABASE_URL": "your-database-url",
      "API_BASE_URL": "your-api-endpoint", 
      "API_KEY": "your-api-key"
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

Your application supports these environment variables:

### Required
- `DATABASE_URL` - Database connection string
- `API_BASE_URL` - AI API endpoint
- `API_KEY` - AI API key

### Optional
- `DATABASE_SCHEMA` - Database schema name
- `API_DEPLOYMENT_ID` - API deployment ID (default: model-router)
- `API_VERSION` - API version (default: 2025-01-01-preview)
- `API_MAX_TOKENS` - Max response tokens (default: 8192)
- `API_TEMPERATURE` - AI temperature (default: 0.7)
- `API_MAX_RETRIES` - Max retry attempts (default: 3)
- `PORT` - Server port (default: 5000)

---

## Security Best Practices

1. **Use AWS Systems Manager Parameter Store** for secrets
2. **Enable VPC** for database connections
3. **Use IAM roles** instead of access keys where possible
4. **Enable CloudWatch logging** for monitoring
5. **Set up health checks** for high availability

---

## Monitoring

Your service includes:
- `/health` endpoint for health checks
- Built-in logging
- CloudWatch integration (when deployed on AWS)

## Recommendation

**Start with AWS App Runner** - it's the simplest option and handles most of the infrastructure automatically. You can always migrate to ECS or Lambda later if you need more control or different pricing models.
