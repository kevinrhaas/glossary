#!/bin/bash

# Interactive Deployment Pipeline
# This script runs the complete deployment process with user prompts and choices

set -e

echo "🚀 Starting INTERACTIVE deployment pipeline..."
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

# Choose deployment target
echo ""
echo "Choose deployment target:"
echo "1) AWS ECS Fargate (more control, manual scaling)"
echo "2) AWS App Runner (simpler, auto-scaling)"
read -p "Enter choice (1 or 2): " -n 1 -r
echo

case $REPLY in
  1)
    DEPLOYMENT_TYPE="ecs"
    echo "Selected: AWS ECS Fargate"
    ;;
  2)
    DEPLOYMENT_TYPE="apprunner" 
    echo "Selected: AWS App Runner"
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

echo ""
echo "🏁 Starting deployment pipeline..."

# Step 1: Build and test locally
echo ""
echo "========================================="
echo "Step 1: Building and testing locally"
echo "========================================="
chmod +x deploy/01-build-and-test.sh
./deploy/01-build-and-test.sh

# Ask to continue
echo ""
read -p "Continue to push to ECR? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
  echo "Deployment stopped at user request"
  exit 0
fi

# Step 2: Push to ECR
echo ""
echo "========================================="
echo "Step 2: Pushing to AWS ECR"
echo "========================================="
chmod +x deploy/02-push-to-ecr.sh
./deploy/02-push-to-ecr.sh

# Ask to continue
echo ""
read -p "Continue to deploy to AWS? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
  echo "Deployment stopped at user request"
  exit 0
fi

# Step 3: Deploy to chosen target
echo ""
echo "========================================="
echo "Step 3: Deploying to AWS ${DEPLOYMENT_TYPE^^}"
echo "========================================="

if [ "${DEPLOYMENT_TYPE}" = "ecs" ]; then
  chmod +x deploy/03-deploy-to-ecs.sh
  ./deploy/03-deploy-to-ecs.sh production
else
  chmod +x deploy/03-deploy-to-apprunner.sh
  ./deploy/03-deploy-to-apprunner.sh production
fi

# Step 4: Check deployment status
echo ""
echo "========================================="
echo "Step 4: Checking deployment status"
echo "========================================="
chmod +x deploy/check-status.sh
./deploy/check-status.sh

# Optional Step 5: Cleanup old services
if [ "${DEPLOYMENT_TYPE}" = "ecs" ]; then
  echo ""
  echo "ℹ️  Legacy cleanup scripts have been archived."
  echo "Manual cleanup via AWS CLI if needed for old resources."
fi

echo ""
echo "🎉 Deployment pipeline completed successfully!"
echo ""
echo "📊 Summary:"
if [ -f deploy/deployment-info-production.env ]; then
  source deploy/deployment-info-production.env
  echo "   Deployment: AWS ECS Fargate (Production)"
  echo "   Service: ${ECS_SERVICE_NAME}"
  echo "   URL: http://${ECS_PUBLIC_IP}:5000"
elif [ -f deploy/apprunner-deployment-info-production.env ]; then
  source deploy/apprunner-deployment-info-production.env
  echo "   Deployment: AWS App Runner (Production)"
  echo "   URL: https://${APPRUNNER_SERVICE_URL}"
fi

echo ""
echo "✅ Your application is now running in production!"
