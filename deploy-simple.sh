#!/bin/bash

# Simple Glossary App Deployment Script
# This script builds, tags, and pushes to ECR, then provides manual ECS update instructions

set -e  # Exit on any error

# Configuration
ECR_REGISTRY="729973546399.dkr.ecr.us-east-1.amazonaws.com"
ECR_REPO="glossary-generator"
REGION="us-east-1"

# Get version from command line or use timestamp
VERSION=${1:-$(date +%Y%m%d-%H%M%S)}
IMAGE_TAG="${ECR_REGISTRY}/${ECR_REPO}:${VERSION}"
LATEST_TAG="${ECR_REGISTRY}/${ECR_REPO}:latest"

echo "🚀 Starting deployment of glossary-app version: ${VERSION}"

# Step 1: Build Docker image
echo "📦 Building Docker image..."
docker build --platform linux/amd64 -t glossary-app:${VERSION} .

# Step 2: Tag for ECR
echo "🏷️  Tagging image for ECR..."
docker tag glossary-app:${VERSION} ${IMAGE_TAG}
docker tag glossary-app:${VERSION} ${LATEST_TAG}

# Step 3: Authenticate with ECR
echo "🔐 Authenticating with ECR..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Step 4: Push to ECR
echo "⬆️  Pushing image to ECR..."
docker push ${IMAGE_TAG}
docker push ${LATEST_TAG}

echo "✅ Image pushed successfully!"
echo "🏷️  Image URI: ${IMAGE_TAG}"
echo "📋 Next steps:"
echo "   1. Go to AWS ECS Console"
echo "   2. Update your task definition with the new image URI: ${IMAGE_TAG}"
echo "   3. Update your ECS service to use the new task definition"
echo ""
echo "🌐 Once deployed, test with:"
echo "   curl http://YOUR_SERVICE_IP:5000/health"
echo "   curl http://YOUR_SERVICE_IP:5000/docs"

echo "🎉 Build and push complete!"
