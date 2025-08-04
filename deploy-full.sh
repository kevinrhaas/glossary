#!/bin/bash

# Complete ECS Deployment Script
# This script handles everything: ECR push, task definition, service creation/update

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

echo "🚀 Starting complete deployment of glossary-app version: ${VERSION}"

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

# Step 5: Create CloudWatch log group if it doesn't exist
echo "📋 Ensuring CloudWatch log group exists..."
aws logs create-log-group --log-group-name "/ecs/glossary-task" --region ${REGION} 2>/dev/null || echo "Log group already exists"

# Step 6: Update task definition with new image
echo "📝 Updating task definition..."
UPDATED_TASK_DEF=$(cat ecs-task-definition.json | jq --arg IMAGE "$IMAGE_TAG" '.containerDefinitions[0].image = $IMAGE')

# Write updated task definition to temp file
echo "$UPDATED_TASK_DEF" > /tmp/updated-task-def.json

# Register new task definition
NEW_REVISION=$(aws ecs register-task-definition --region ${REGION} --cli-input-json file:///tmp/updated-task-def.json --query 'taskDefinition.revision' --output text)
echo "📝 Registered task definition revision: ${NEW_REVISION}"

# Step 7: Check if cluster exists, create if not
echo "🔍 Checking ECS cluster..."
if ! aws ecs describe-clusters --region ${REGION} --clusters ${CLUSTER_NAME} --query 'clusters[?status==`ACTIVE`]' --output text | grep -q ${CLUSTER_NAME}; then
    echo "🏗️  Creating ECS cluster..."
    aws ecs create-cluster --region ${REGION} --cluster-name ${CLUSTER_NAME}
    echo "✅ Cluster created"
else
    echo "✅ Cluster exists"
fi

# Step 8: Get default VPC and subnets for Fargate
echo "🌐 Getting VPC configuration..."
VPC_ID=$(aws ec2 describe-vpcs --region ${REGION} --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text)
SUBNET_IDS=$(aws ec2 describe-subnets --region ${REGION} --filters "Name=vpc-id,Values=${VPC_ID}" --query 'Subnets[*].SubnetId' --output text | tr '\t' ',')
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --region ${REGION} --filters "Name=vpc-id,Values=${VPC_ID}" "Name=group-name,Values=default" --query 'SecurityGroups[0].GroupId' --output text)

echo "📋 VPC ID: ${VPC_ID}"
echo "📋 Subnets: ${SUBNET_IDS}"
echo "📋 Security Group: ${SECURITY_GROUP_ID}"

# Step 9: Check if service exists
echo "🔍 Checking if ECS service exists..."
if aws ecs describe-services --region ${REGION} --cluster ${CLUSTER_NAME} --services ${SERVICE_NAME} --query 'services[?status==`ACTIVE`]' --output text | grep -q ${SERVICE_NAME}; then
    echo "🔄 Updating existing service..."
    aws ecs update-service --region ${REGION} --cluster ${CLUSTER_NAME} --service ${SERVICE_NAME} --task-definition ${TASK_FAMILY}:${NEW_REVISION}
else
    echo "🏗️  Creating new ECS service..."
    aws ecs create-service --region ${REGION} \
        --cluster ${CLUSTER_NAME} \
        --service-name ${SERVICE_NAME} \
        --task-definition ${TASK_FAMILY}:${NEW_REVISION} \
        --desired-count 1 \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_IDS}],securityGroups=[${SECURITY_GROUP_ID}],assignPublicIp=ENABLED}"
    echo "✅ Service created"
fi

# Step 10: Wait for deployment to complete
echo "⏳ Waiting for deployment to complete..."
aws ecs wait services-stable --region ${REGION} --cluster ${CLUSTER_NAME} --services ${SERVICE_NAME}

# Step 11: Get service status and public IP
echo "🔍 Getting deployment status..."
SERVICE_STATUS=$(aws ecs describe-services --region ${REGION} --cluster ${CLUSTER_NAME} --services ${SERVICE_NAME} --query 'services[0].deployments[0].status' --output text)

if [ "$SERVICE_STATUS" = "PRIMARY" ]; then
    echo "✅ Deployment successful!"
    
    # Get the public IP
    TASK_ARN=$(aws ecs list-tasks --region ${REGION} --cluster ${CLUSTER_NAME} --service-name ${SERVICE_NAME} --query 'taskArns[0]' --output text)
    
    if [ "$TASK_ARN" != "None" ] && [ "$TASK_ARN" != "" ]; then
        echo "⏳ Getting public IP..."
        sleep 10  # Wait a bit for network interface to be ready
        
        NETWORK_INTERFACE_ID=$(aws ecs describe-tasks --region ${REGION} --cluster ${CLUSTER_NAME} --tasks ${TASK_ARN} --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text)
        
        if [ "$NETWORK_INTERFACE_ID" != "None" ] && [ "$NETWORK_INTERFACE_ID" != "" ]; then
            PUBLIC_IP=$(aws ec2 describe-network-interfaces --region ${REGION} --network-interface-ids ${NETWORK_INTERFACE_ID} --query 'NetworkInterfaces[0].Association.PublicIp' --output text)
            
            if [ "$PUBLIC_IP" != "None" ] && [ "$PUBLIC_IP" != "" ]; then
                echo ""
                echo "🎉 DEPLOYMENT COMPLETE!"
                echo "🌐 Service available at: http://${PUBLIC_IP}:5000"
                echo "📚 API Documentation: http://${PUBLIC_IP}:5000/docs"
                echo "❤️  Health Check: http://${PUBLIC_IP}:5000/health"
                echo ""
                echo "🧪 Test the service:"
                echo "   curl http://${PUBLIC_IP}:5000/health"
                echo "   curl http://${PUBLIC_IP}:5000/docs"
                echo ""
            else
                echo "⚠️  Could not retrieve public IP, but service is running"
            fi
        else
            echo "⚠️  Could not retrieve network interface, but service is running"
        fi
    else
        echo "⚠️  Could not retrieve task ARN, but service should be running"
    fi
    
    echo "🏷️  Deployed version: ${VERSION}"
    echo "🆔 Task definition: ${TASK_FAMILY}:${NEW_REVISION}"
else
    echo "❌ Deployment failed! Status: $SERVICE_STATUS"
    exit 1
fi

echo "🎉 Complete deployment finished!"
