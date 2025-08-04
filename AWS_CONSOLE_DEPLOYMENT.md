# AWS Console Manual Deployment Guide

This guide walks you through deploying your Database Schema Glossary Generator to AWS using the web console interface.

## Prerequisites

1. AWS Account with appropriate permissions
2. Your application files ready (they are!)
3. Docker Desktop installed locally (for building the image)

## Deployment Options

We'll cover two main approaches:
1. **AWS App Runner** (Recommended - Easiest)
2. **Amazon ECS with Fargate** (More control)

---

## Option 1: AWS App Runner (Recommended)

App Runner is the simplest way to deploy containerized applications. It handles load balancing, auto-scaling, and SSL certificates automatically.

### Step 1: Prepare Your Application

Your app is already prepared! You have:
- ✅ `app.py` - Flask application
- ✅ `requirements.txt` - Dependencies
- ✅ `Dockerfile` - Container definition
- ✅ `config.json` - Default configuration

### Step 2: Create ECR Repository (Container Registry)

1. **Go to Amazon ECR Console**:
   - Navigate to: https://console.aws.amazon.com/ecr/
   - Click "Create repository"

2. **Repository Settings**:
   - Repository name: `glossary-generator`
   - Visibility: Private
   - Click "Create repository"

3. **Get Push Commands**:
   - Click on your new repository
   - Click "View push commands"
   - **Keep this tab open** - you'll need these commands

### Step 3: Build and Push Your Docker Image

Open Terminal in your project directory and run these commands (replace with your actual ECR URI):

```bash
# Navigate to your project
cd "/Users/khaas/Library/Mobile Documents/com~apple~CloudDocs/Personal/Projects/glossary"

# Build your Docker image
docker build -t glossary-generator .

# Get login token (replace REGION and ACCOUNT_ID)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Tag your image (replace with your ECR URI)
docker tag glossary-generator:latest ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/glossary-generator:latest

# Push to ECR (replace with your ECR URI)
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/glossary-generator:latest
```

### Step 4: Create App Runner Service

1. **Go to AWS App Runner Console**:
   - Navigate to: https://console.aws.amazon.com/apprunner/
   - Click "Create service"

2. **Source Configuration**:
   - Source: "Container registry"
   - Provider: "Amazon ECR"
   - Container image URI: Paste your ECR image URI
   - Deployment trigger: "Manual" (or "Automatic" for auto-deploy)
   - Click "Next"

3. **Service Configuration**:
   - Service name: `glossary-generator-service`
   - Virtual CPU: 1 vCPU
   - Memory: 2 GB
   - Port: 5000
   - Click "Next"

4. **Environment Variables** (Important!):
   Click "Add environment variable" for each:
   ```
   DATABASE_URL = postgresql://user:password@host:port/database
   API_BASE_URL = your-api-endpoint.com
   API_KEY = your-api-key
   DATABASE_SCHEMA = public
   ```

5. **Review and Create**:
   - Review all settings
   - Click "Create & deploy"

### Step 5: Access Your Service

1. **Wait for deployment** (5-10 minutes)
2. **Get service URL**: Copy the App Runner service URL
3. **Test endpoints**:
   - Health check: `https://your-service-url.region.awsapprunner.com/health`
   - Documentation: `https://your-service-url.region.awsapprunner.com/docs`

---

## Option 2: Amazon ECS with Fargate

For more control over your deployment, use ECS Fargate.

### Step 1: Create ECS Cluster

1. **Go to Amazon ECS Console**:
   - Navigate to: https://console.aws.amazon.com/ecs/
   - Click "Create Cluster"

2. **Cluster Configuration**:
   - Cluster name: `glossary-cluster`
   - Infrastructure: AWS Fargate (serverless)
   - Click "Create"

### Step 2: Create Task Definition

1. **Go to Task Definitions**:
   - Click "Create new task definition"

2. **Task Definition Configuration**:
   - Family name: `glossary-task`
   - Launch type: AWS Fargate
   - CPU: 1 vCPU
   - Memory: 2 GB

3. **Container Definition**:
   - Container name: `glossary-container`
   - Image URI: Your ECR image URI
   - Port mappings: Host port 80, Container port 5000, Protocol TCP

4. **Environment Variables**:
   Add the same environment variables as App Runner

5. **Create Task Definition**

### Step 3: Create ECS Service

1. **Go to your cluster**:
   - Click on `glossary-cluster`
   - Go to "Services" tab
   - Click "Create"

2. **Service Configuration**:
   - Launch type: Fargate
   - Task Definition: `glossary-task`
   - Service name: `glossary-service`
   - Desired tasks: 1

3. **Network Configuration**:
   - VPC: Default VPC
   - Subnets: Select public subnets
   - Security Group: Create new or use existing (allow port 80)
   - Auto-assign public IP: Enabled

4. **Load Balancer** (Optional but recommended):
   - Create Application Load Balancer
   - Target group: Create new
   - Health check path: `/health`

---

## Environment Variables Reference

Set these in either App Runner or ECS:

| Variable | Example | Required |
|----------|---------|----------|
| `DATABASE_URL` | `postgresql://user:pass@host:5432/db` | Yes* |
| `DATABASE_SCHEMA` | `public` | No |
| `API_BASE_URL` | `your-api-endpoint.com` | Yes* |
| `API_KEY` | `your-api-key` | Yes* |
| `API_MAX_RETRIES` | `3` | No |
| `API_MAX_TOKENS` | `8192` | No |
| `API_TEMPERATURE` | `0.7` | No |

*Required if not set in config.json

---

## Monitoring and Troubleshooting

### App Runner Monitoring
- **Service Dashboard**: View metrics, logs, and activity
- **Logs**: CloudWatch logs are automatically configured
- **Metrics**: Request count, response time, error rate

### ECS Monitoring
- **Service Metrics**: Task count, resource utilization
- **CloudWatch Logs**: Configure log group for container logs
- **Task Health**: Monitor task status and health checks

### Common Issues

1. **Service won't start**:
   - Check environment variables
   - Verify ECR image exists and is accessible
   - Check CloudWatch logs

2. **Database connection fails**:
   - Verify DATABASE_URL format
   - Ensure database is accessible from AWS
   - Check security groups and network configuration

3. **API calls fail**:
   - Verify API_KEY and API_BASE_URL
   - Check API endpoint accessibility

---

## Cost Estimates

### App Runner
- **Development**: ~$7-15/month (minimal traffic)
- **Production**: $25-50/month (moderate traffic)

### ECS Fargate
- **Development**: ~$15-25/month (1 task, minimal resources)
- **Production**: $30-60/month (with load balancer)

---

## Security Best Practices

1. **Use Environment Variables**: Never hardcode credentials
2. **VPC Configuration**: Deploy in private subnets when possible
3. **Security Groups**: Restrict access to necessary ports only
4. **IAM Roles**: Use least-privilege access
5. **SSL/TLS**: App Runner provides automatic HTTPS

---

## Next Steps After Deployment

1. **Test all endpoints**: Verify functionality
2. **Set up monitoring**: CloudWatch alarms for errors
3. **Configure scaling**: Auto-scaling policies
4. **Set up CI/CD**: Automate future deployments
5. **Custom domain**: Add your own domain name

Would you like me to help you with any specific step?
