#!/bin/bash

# Glossary App Deployment Script
# This script builds, tags, pushes to ECR, and deploys to AWS ECS

set -e  # Exit on any error

# Configuration
ECR_REGISTRY="729973546399.dkr.ecr.us-east-1.amazonaws.com"
ECR_REPO="glossary-generator"
CLUSTER_NAME="glossary-cluster"
SERVICE_NAME="glossary-service"
TASK_FAMILY="glossary-task"
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

# Step 5: Update ECS service
echo "🔄 Updating ECS service..."

# Get current task definition
TASK_DEF=$(aws ecs describe-task-definition --task-definition ${TASK_FAMILY} --region ${REGION} --query 'taskDefinition' --output json)

# Create new task definition with updated image
NEW_TASK_DEF=$(echo $TASK_DEF | jq --arg IMAGE "$IMAGE_TAG" '.containerDefinitions[0].image = $IMAGE | del(.taskDefinitionArn) | del(.revision) | del(.status) | del(.requiresAttributes) | del(.placementConstraints) | del(.compatibilities) | del(.registeredAt) | del(.registeredBy)')

# Register new task definition
echo "📝 Registering new task definition..."
NEW_REVISION=$(aws ecs register-task-definition --region ${REGION} --cli-input-json "$NEW_TASK_DEF" --query 'taskDefinition.revision' --output text)

# Update service to use new task definition
echo "🔄 Updating service to use revision ${NEW_REVISION}..."
aws ecs update-service --region ${REGION} --cluster ${CLUSTER_NAME} --service ${SERVICE_NAME} --task-definition ${TASK_FAMILY}:${NEW_REVISION}

# Wait for deployment to complete
echo "⏳ Waiting for deployment to complete..."
aws ecs wait services-stable --region ${REGION} --cluster ${CLUSTER_NAME} --services ${SERVICE_NAME}

# Get service status
SERVICE_STATUS=$(aws ecs describe-services --region ${REGION} --cluster ${CLUSTER_NAME} --services ${SERVICE_NAME} --query 'services[0].deployments[0].status' --output text)

if [ "$SERVICE_STATUS" = "PRIMARY" ]; then
    echo "✅ Deployment successful!"
    
    # Get the public IP
    TASK_ARN=$(aws ecs list-tasks --region ${REGION} --cluster ${CLUSTER_NAME} --service-name ${SERVICE_NAME} --query 'taskArns[0]' --output text)
    
    if [ "$TASK_ARN" != "None" ] && [ "$TASK_ARN" != "" ]; then
        PUBLIC_IP=$(aws ecs describe-tasks --region ${REGION} --cluster ${CLUSTER_NAME} --tasks ${TASK_ARN} --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text | xargs -I {} aws ec2 describe-network-interfaces --region ${REGION} --network-interface-ids {} --query 'NetworkInterfaces[0].Association.PublicIp' --output text)
        
        if [ "$PUBLIC_IP" != "None" ] && [ "$PUBLIC_IP" != "" ]; then
            echo "🌐 Service available at: http://${PUBLIC_IP}:5000"
            echo "📚 API Documentation: http://${PUBLIC_IP}:5000/docs"
            echo "❤️  Health Check: http://${PUBLIC_IP}:5000/health"
        fi
    fi
    
    echo "🏷️  Deployed version: ${VERSION}"
    echo "🆔 Task definition: ${TASK_FAMILY}:${NEW_REVISION}"
else
    echo "❌ Deployment failed! Status: $SERVICE_STATUS"
    exit 1
fi

echo "🎉 Deployment complete!"
