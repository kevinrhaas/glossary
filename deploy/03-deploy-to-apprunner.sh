#!/bin/bash

# Smart Deploy to App Runner - Updates existing service or c# Ask for confirmation
echo ""
if [ "${DEPLOYMENT_TYPE}" = "update" ]; then
  echo "⚠️  This will update the existing ${ENVIRONMENT} App Runner service with a new image."
  echo "App Runner will perform a rolling deployment (no downtime)."
else
  echo "🆕 This will create a new ${ENVIRONMENT} App Runner service: ${SERVICE_NAME}"
fi
echo ""
read -p "Continue with ${ENVIRONMENT} deployment? (y/N): " -n 1 -r one
# This script intelligently handles both first deployments and updates
# Supports multiple environments: production, test, staging

set -e

# Environment parameter (default to production)
ENVIRONMENT=${1:-production}

echo "🚀 Smart Deploy to AWS App Runner..."
echo "🎯 Target Environment: ${ENVIRONMENT}"

# Environment-specific configuration
AWS_REGION="us-east-1" 

case "${ENVIRONMENT}" in
  "production"|"prod")
    SERVICE_NAME="glossary-apprunner"
    echo "📦 Deploying to PRODUCTION environment"
    ;;
  "test"|"testing")
    SERVICE_NAME="glossary-apprunner-test"
    echo "🧪 Deploying to TEST environment"
    ;;
  *)
    echo "❌ Invalid environment: ${ENVIRONMENT}"
    echo "Valid options: production, test"
    exit 1
    ;;
esac

# Load image info from previous step
if [ ! -f deploy/image-info.env ]; then
  echo "❌ Image info not found. Please run './deploy/02-push-to-ecr.sh' first"
  exit 1
fi

source deploy/image-info.env

echo "Deploying image: ${ECR_IMAGE_URI}"
echo "Service name: ${SERVICE_NAME}"

# Check required environment variables
if [ -z "${DATABASE_URL}" ] || [ -z "${API_BASE_URL}" ] || [ -z "${API_KEY}" ]; then
  echo "❌ Required environment variables not set:"
  echo "   DATABASE_URL, API_BASE_URL, API_KEY"
  echo "Please set them in your environment or .env file"
  exit 1
fi

# Check if service already exists
echo "🔍 Checking if App Runner service already exists..."
EXISTING_SERVICE_ARN=$(aws apprunner list-services \
  --region ${AWS_REGION} \
  --query "ServiceSummaryList[?ServiceName=='${SERVICE_NAME}'].ServiceArn" --output text 2>/dev/null || echo "")

if [ -n "${EXISTING_SERVICE_ARN}" ] && [ "${EXISTING_SERVICE_ARN}" != "" ]; then
  DEPLOYMENT_TYPE="update"
  echo "✅ Found existing service: ${SERVICE_NAME}"
  echo "📦 This will be an UPDATE deployment"
  echo "Service ARN: ${EXISTING_SERVICE_ARN}"
else
  DEPLOYMENT_TYPE="create"
  echo "ℹ️  No existing service found"
  echo "🆕 This will be a CREATE deployment"
fi

# Ask for confirmation
echo ""
if [ "${DEPLOYMENT_TYPE}" = "update" ]; then
  echo "⚠️  This will update the existing App Runner service with a new image."
  echo "App Runner will perform a rolling deployment (no downtime)."
else
  echo "🆕 This will create a new App Runner service: ${SERVICE_NAME}"
fi
echo ""
read -p "Continue? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
  echo "Deployment cancelled."
  exit 0
fi

if [ "${DEPLOYMENT_TYPE}" = "update" ]; then
  echo ""
  echo "========================================="
  echo "UPDATING EXISTING SERVICE"
  echo "========================================="
  
  # Start deployment with new image
  echo "🔄 Starting deployment with new image..."
  OPERATION_ID=$(aws apprunner start-deployment \
    --service-arn ${EXISTING_SERVICE_ARN} \
    --region ${AWS_REGION} \
    --query 'OperationId' --output text)
  
  echo "✅ Deployment started with Operation ID: ${OPERATION_ID}"
  
  # We need to update the service configuration with the new image
  # First, get current service configuration
  echo "📝 Updating service configuration with new image..."
  
  # Create updated configuration
  cat > /tmp/apprunner-update-config.json << EOF
{
  "SourceConfiguration": {
    "ImageRepository": {
      "ImageIdentifier": "${ECR_IMAGE_URI}",
      "ImageConfiguration": {
        "Port": "5000",
        "RuntimeEnvironmentVariables": {
          "DATABASE_URL": "${DATABASE_URL}",
          "API_BASE_URL": "${API_BASE_URL}",
          "API_KEY": "${API_KEY}",
          "DATABASE_SCHEMA": "${DATABASE_SCHEMA:-}"
        }
      },
      "ImageRepositoryType": "ECR"
    },
    "AutoDeploymentsEnabled": false
  }
}
EOF

  # Update the service
  aws apprunner update-service \
    --service-arn ${EXISTING_SERVICE_ARN} \
    --cli-input-json file:///tmp/apprunner-update-config.json \
    --region ${AWS_REGION}
  
  echo "⏳ Waiting for service update to complete..."
  
else
  echo ""
  echo "========================================="
  echo "CREATING NEW SERVICE"
  echo "========================================="
  
  # Create App Runner service configuration
  echo "📝 Creating App Runner service configuration..."
  cat > /tmp/apprunner-config.json << EOF
{
  "ServiceName": "${SERVICE_NAME}",
  "SourceConfiguration": {
    "ImageRepository": {
      "ImageIdentifier": "${ECR_IMAGE_URI}",
      "ImageConfiguration": {
        "Port": "5000",
        "RuntimeEnvironmentVariables": {
          "DATABASE_URL": "${DATABASE_URL}",
          "API_BASE_URL": "${API_BASE_URL}",
          "API_KEY": "${API_KEY}",
          "DATABASE_SCHEMA": "${DATABASE_SCHEMA:-}"
        }
      },
      "ImageRepositoryType": "ECR"
    },
    "AutoDeploymentsEnabled": false
  },
  "InstanceConfiguration": {
    "Cpu": "0.25 vCPU",
    "Memory": "0.5 GB"
  },
  "HealthCheckConfiguration": {
    "Protocol": "HTTP",
    "Path": "/health",
    "Interval": 10,
    "Timeout": 5,
    "HealthyThreshold": 1,
    "UnhealthyThreshold": 5
  }
}
EOF

  # Create the service
  echo "🚀 Creating App Runner service..."
  EXISTING_SERVICE_ARN=$(aws apprunner create-service \
    --cli-input-json file:///tmp/apprunner-config.json \
    --region ${AWS_REGION} \
    --query 'Service.ServiceArn' --output text)

  echo "✅ App Runner service created: ${EXISTING_SERVICE_ARN}"
fi

# Wait for service to be running
echo "⏳ Waiting for service to be running..."
while true; do
  STATUS=$(aws apprunner describe-service \
    --service-arn ${EXISTING_SERVICE_ARN} \
    --region ${AWS_REGION} \
    --query 'Service.Status' --output text)
  
  echo "Current status: ${STATUS}"
  
  if [ "${STATUS}" = "RUNNING" ]; then
    break
  elif [ "${STATUS}" = "CREATE_FAILED" ] || [ "${STATUS}" = "UPDATE_FAILED" ]; then
    echo "❌ Service deployment failed"
    exit 1
  fi
  
  sleep 30
done

# Get service URL
SERVICE_URL=$(aws apprunner describe-service \
  --service-arn ${EXISTING_SERVICE_ARN} \
  --region ${AWS_REGION} \
  --query 'Service.ServiceUrl' --output text)

echo ""
echo "✅ Deployment successful!"
echo "🌐 Service URL: https://${SERVICE_URL}"
echo "🔗 Health check: https://${SERVICE_URL}/health"
echo "⚙️  Config: https://${SERVICE_URL}/config"
echo ""
echo "📊 Service details:"
echo "   Service ARN: ${EXISTING_SERVICE_ARN}"
echo "   Service URL: ${SERVICE_URL}"
echo "   Environment: ${ENVIRONMENT}"
echo "   Deployment Type: ${DEPLOYMENT_TYPE}"
echo ""
if [ "${DEPLOYMENT_TYPE}" = "create" ]; then
  echo "✅ New ${ENVIRONMENT} App Runner service created successfully!"
else
  echo "✅ ${ENVIRONMENT} App Runner service updated successfully with rolling deployment!"
fi
echo "Note: App Runner automatically handles scaling, load balancing, and HTTPS"

# Save deployment info with environment suffix
DEPLOYMENT_INFO_FILE="deploy/apprunner-deployment-info-${ENVIRONMENT}.env"
echo "export APPRUNNER_SERVICE_ARN=\"${EXISTING_SERVICE_ARN}\"" > ${DEPLOYMENT_INFO_FILE}
echo "export APPRUNNER_SERVICE_URL=\"${SERVICE_URL}\"" >> ${DEPLOYMENT_INFO_FILE}
echo "export DEPLOYMENT_TYPE=\"${DEPLOYMENT_TYPE}\"" >> ${DEPLOYMENT_INFO_FILE}
echo "export ENVIRONMENT=\"${ENVIRONMENT}\"" >> ${DEPLOYMENT_INFO_FILE}
