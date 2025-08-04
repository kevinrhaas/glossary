#!/bin/bash

# Step 1: Build and Test Docker Image Locally
# This script builds the Docker image and tests it locally before deployment

set -e

echo "🏗️  Building Docker image locally..."

# Configuration
IMAGE_NAME="glossary-generator"
LOCAL_TAG="local-test"

# Build the image
echo "Building Docker image for x86_64 platform (AWS Fargate)..."
docker build --platform linux/amd64 -t ${IMAGE_NAME}:${LOCAL_TAG} .

echo "✅ Docker image built successfully: ${IMAGE_NAME}:${LOCAL_TAG}"

# Test the image locally
echo "🧪 Testing Docker image locally..."
echo "Starting container on port 5001 (to avoid conflicts)..."

# Stop any existing test container
docker stop glossary-test 2>/dev/null || true
docker rm glossary-test 2>/dev/null || true

# Start container with environment variables
docker run -d \
  --name glossary-test \
  -p 5001:5000 \
  -e DATABASE_URL="${DATABASE_URL}" \
  -e API_BASE_URL="${API_BASE_URL}" \
  -e API_KEY="${API_KEY}" \
  -e DATABASE_SCHEMA="${DATABASE_SCHEMA}" \
  ${IMAGE_NAME}:${LOCAL_TAG}

# Wait for container to start
echo "Waiting for container to start..."
sleep 5

# Test the endpoints
echo "Testing health endpoint..."
if curl -f -s http://localhost:5001/health > /dev/null; then
  echo "✅ Health check passed"
else
  echo "❌ Health check failed"
  docker logs glossary-test
  exit 1
fi

echo "Testing config endpoint..."
if curl -f -s http://localhost:5001/config > /dev/null; then
  echo "✅ Config endpoint working"
else
  echo "❌ Config endpoint failed"
  docker logs glossary-test
  exit 1
fi

echo "✅ Local Docker test completed successfully!"
echo "📝 Container logs:"
docker logs glossary-test --tail 10

echo ""
echo "🔍 To manually test the container:"
echo "   curl http://localhost:5001/health"
echo "   curl http://localhost:5001/config"
echo ""
echo "🛑 To stop the test container:"
echo "   docker stop glossary-test && docker rm glossary-test"

echo ""
echo "✅ Step 1 Complete: Docker image built and tested locally"
echo "Next: Run './deploy/02-push-to-ecr.sh' to push to AWS ECR"
