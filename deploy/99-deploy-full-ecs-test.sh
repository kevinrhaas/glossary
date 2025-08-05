#!/bin/bash

# Full Automated ECS Test Deployment
# This script runs the complete deployment process automatically to ECS test environment

set -e

echo "🚀 Starting AUTOMATED ECS Test deployment..."
echo ""
echo "🧪 Deploying to TEST environment for validation"
echo ""

# Check if .env file exists for local development
if [ ! -f .env ]; then
  echo "❌ .env file not found"
  echo "Please copy .env.example to .env and configure your values:"
  echo "   cp .env.example .env"
  echo "   # Edit .env with your actual values"
  exit 1
fi

# Load environment variables
echo "📋 Loading environment variables from .env..."
source .env

# Check required environment variables
required_vars=("DATABASE_URL" "API_BASE_URL" "API_KEY")
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "❌ Required environment variable not set: ${var}"
    echo "Please check your .env file"
    exit 1
  fi
done

echo "✅ Environment variables loaded"

# Set deployment type
DEPLOYMENT_TYPE="ecs"
ENVIRONMENT="test"
echo "🎯 Deployment target: AWS ECS Fargate (Test)"

echo ""
echo "🏁 Starting automated deployment pipeline..."

# Step 1: Build and test locally
echo ""
echo "========================================="
echo "Step 1: Building and testing locally"
echo "========================================="
chmod +x deploy/01-build-and-test.sh
./deploy/01-build-and-test.sh

# Step 2: Push to ECR
echo ""
echo "========================================="
echo "Step 2: Pushing to AWS ECR"
echo "========================================="
chmod +x deploy/02-push-to-ecr.sh
./deploy/02-push-to-ecr.sh

# Step 3: Deploy to ECS Test
echo ""
echo "========================================="
echo "Step 3: Deploying to AWS ECS (Test)"
echo "========================================="
chmod +x deploy/03-deploy-to-ecs.sh
./deploy/03-deploy-to-ecs.sh test

# Step 4: Check deployment status
echo ""
echo "========================================="
echo "Step 4: Checking deployment status"
echo "========================================="
chmod +x deploy/check-status.sh
./deploy/check-status.sh

echo ""
echo "🎉 Test deployment pipeline completed successfully!"
echo ""
echo "📊 Summary:"
if [ -f deploy/deployment-info-test.env ]; then
  source deploy/deployment-info-test.env
  echo "   Deployment: AWS ECS Fargate (Test)"
  echo "   Service: ${ECS_SERVICE_NAME}"
  echo "   URL: http://${ECS_PUBLIC_IP}:5000"
  echo "   Environment: TEST"
fi

echo ""
echo "✅ Your application is now running in TEST!"
echo "🧪 Test your changes at the URL above"
echo "📝 If everything looks good, run deploy-full-ecs-production.sh for production deployment"
