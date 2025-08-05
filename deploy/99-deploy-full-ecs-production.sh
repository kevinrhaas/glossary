#!/bin/bash

# Full Automated ECS Production Deployment
# This script runs the complete deployment process automatically to ECS production

set -e

echo "🚀 Starting AUTOMATED ECS Production deployment..."
echo ""
echo "⚠️  WARNING: This will deploy to PRODUCTION environment!"
echo "   Make sure you've tested in the test environment first."
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
ENVIRONMENT="production"
echo "🎯 Deployment target: AWS ECS Fargate (Production)"

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

# Step 3: Deploy to ECS Production
echo ""
echo "========================================="
echo "Step 3: Deploying to AWS ECS (Production)"
echo "========================================="
chmod +x deploy/03-deploy-to-ecs.sh
./deploy/03-deploy-to-ecs.sh production

# Step 4: Check deployment status
echo ""
echo "========================================="
echo "Step 4: Checking deployment status"
echo "========================================="
chmod +x deploy/check-status.sh
./deploy/check-status.sh

echo ""
echo "🎉 Production deployment pipeline completed successfully!"
echo ""
echo "📊 Summary:"
if [ -f deploy/deployment-info-production.env ]; then
  source deploy/deployment-info-production.env
  echo "   Deployment: AWS ECS Fargate (Production)"
  echo "   Service: ${ECS_SERVICE_NAME}"
  echo "   URL: http://${ECS_PUBLIC_IP}:5000"
  echo "   Environment: PRODUCTION"
fi

echo ""
echo "✅ Your application is now running in PRODUCTION!"
echo "🔗 Access your application at the URL above"
