#!/bin/bash

# Step 2: Push Docker Image to AWS ECR
# This script pushes the tested Docker image to AWS ECR

set -e

echo "📤 Pushing Docker image to AWS ECR..."

# AWS Profile Configuration
AWS_PROFILE="khaas"
AWS_PROFILE_ARG=""
if [ ! -z "${AWS_PROFILE}" ]; then
  AWS_PROFILE_ARG="--profile ${AWS_PROFILE}"
fi

# Configuration
AWS_ACCOUNT_ID="729973546399"
AWS_REGION="us-east-1"
ECR_REPO="glossary-generator"
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"
LOCAL_IMAGE="glossary-generator:local-test"

# Get version tag (timestamp or provided argument)
VERSION=${1:-$(date +%Y%m%d-%H%M%S)}
VERSIONED_TAG="${ECR_URI}:${VERSION}"
LATEST_TAG="${ECR_URI}:latest"

echo "Version: ${VERSION}"
echo "ECR Repository: ${ECR_URI}"

# Check if local image exists
if ! docker image inspect ${LOCAL_IMAGE} > /dev/null 2>&1; then
  echo "❌ Local image '${LOCAL_IMAGE}' not found"
  echo "Please run './deploy/01-build-and-test.sh' first"
  exit 1
fi

# Check AWS credentials
echo "🔐 Checking AWS credentials..."
if ! aws sts get-caller-identity ${AWS_PROFILE_ARG} > /dev/null 2>&1; then
  echo "❌ AWS credentials not configured"
  echo "Please configure AWS credentials:"
  echo "   aws configure"
  echo "   OR"
  echo "   gimme-aws-creds --profile your-profile"
  exit 1
fi

ACCOUNT_CHECK=$(aws sts get-caller-identity --query Account --output text ${AWS_PROFILE_ARG})
if [ "${ACCOUNT_CHECK}" != "${AWS_ACCOUNT_ID}" ]; then
  echo "⚠️  Warning: AWS account mismatch"
  echo "   Expected: ${AWS_ACCOUNT_ID}"
  echo "   Current:  ${ACCOUNT_CHECK}"
  read -p "Continue anyway? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Create ECR repository if it doesn't exist
echo "📋 Checking ECR repository..."
if ! aws ecr describe-repositories --repository-names ${ECR_REPO} --region ${AWS_REGION} ${AWS_PROFILE_ARG} > /dev/null 2>&1; then
  echo "Creating ECR repository: ${ECR_REPO}"
  aws ecr create-repository \
    --repository-name ${ECR_REPO} \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} \
    --image-scanning-configuration scanOnPush=true
else
  echo "✅ ECR repository exists: ${ECR_REPO}"
fi

# Login to ECR
echo "🔑 Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} ${AWS_PROFILE_ARG} | \
  docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Tag the image
echo "🏷️  Tagging image..."
docker tag ${LOCAL_IMAGE} ${VERSIONED_TAG}
docker tag ${LOCAL_IMAGE} ${LATEST_TAG}

# Push the image
echo "📤 Pushing image to ECR..."
docker push ${VERSIONED_TAG}
docker push ${LATEST_TAG}

echo "✅ Successfully pushed to ECR:"
echo "   Versioned: ${VERSIONED_TAG}"
echo "   Latest:    ${LATEST_TAG}"

# Save the image info for next steps
echo "export ECR_IMAGE_URI=\"${VERSIONED_TAG}\"" > deploy/image-info.env
echo "export ECR_LATEST_URI=\"${LATEST_TAG}\"" >> deploy/image-info.env
echo "export IMAGE_VERSION=\"${VERSION}\"" >> deploy/image-info.env

echo ""
echo "✅ Step 2 Complete: Image pushed to ECR"
echo "Next: Run './deploy/03-deploy-to-ecs.sh' to deploy to ECS"
echo "Or:   Run './deploy/03-deploy-to-apprunner.sh' to deploy to App Runner"
