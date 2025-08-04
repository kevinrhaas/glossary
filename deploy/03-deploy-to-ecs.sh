#!/bin/bash

# Smart Deploy to ECS - Updates existing service or creates new one
# This script intelligently handles both first deployments and updates
# Supports multiple environments: production, test, staging

set -e

# Environment parameter (default to production)
ENVIRONMENT=${1:-production}

echo "🚀 Smart Deploy to AWS ECS Fargate..."
echo "🎯 Target Environment: ${ENVIRONMENT}"

# AWS Profile Configuration
AWS_PROFILE="khaas"
AWS_PROFILE_ARG=""
if [ ! -z "${AWS_PROFILE}" ]; then
  AWS_PROFILE_ARG="--profile ${AWS_PROFILE}"
fi

# Load environment variables from .env file
if [ -f .env ]; then
  echo "📝 Loading environment variables from .env file..."
  set -a  # automatically export all variables
  source .env
  set +a  # stop automatically exporting
else
  echo "⚠️  No .env file found. Environment variables may be missing."
fi

# Environment-specific configuration
AWS_REGION="us-east-1"
CLUSTER_NAME="glossary-cluster"

case "${ENVIRONMENT}" in
  "production"|"prod")
    SERVICE_NAME="glossary-service"
    TASK_FAMILY="glossary-task"
    echo "📦 Deploying to PRODUCTION environment"
    ;;
  "test"|"testing")
    SERVICE_NAME="glossary-service-test"
    TASK_FAMILY="glossary-task-test"
    echo "🧪 Deploying to TEST environment"
    ;;
  *)
    echo "❌ Invalid environment: ${ENVIRONMENT}"
    echo "Valid options: production, test"
    exit 1
    ;;
esac

CPU="256"
MEMORY="512"

# Load image info from previous step
if [ ! -f deploy/image-info.env ]; then
  echo "❌ Image info not found. Please run './deploy/02-push-to-ecr.sh' first"
  exit 1
fi

source deploy/image-info.env

echo "Deploying image: ${ECR_IMAGE_URI}"
echo "Service name: ${SERVICE_NAME}"

# Check if this is a first deployment or update
echo "🔍 Checking if service already exists..."
EXISTING_SERVICE=$(aws ecs describe-services \
  --cluster ${CLUSTER_NAME} \
  --services ${SERVICE_NAME} \
  --region ${AWS_REGION} \
  ${AWS_PROFILE_ARG} \
  --query 'services[0].serviceName' --output text 2>/dev/null || echo "None")

SERVICE_STATUS=$(aws ecs describe-services \
  --cluster ${CLUSTER_NAME} \
  --services ${SERVICE_NAME} \
  --region ${AWS_REGION} \
  ${AWS_PROFILE_ARG} \
  --query 'services[0].status' --output text 2>/dev/null || echo "None")

if [ "${EXISTING_SERVICE}" != "None" ] && [ "${EXISTING_SERVICE}" != "" ] && [ "${SERVICE_STATUS}" = "ACTIVE" ]; then
  DEPLOYMENT_TYPE="update"
  echo "✅ Found existing ACTIVE service: ${SERVICE_NAME}"
  echo "📦 This will be an UPDATE deployment"
else
  DEPLOYMENT_TYPE="create"
  if [ "${EXISTING_SERVICE}" != "None" ] && [ "${SERVICE_STATUS}" != "ACTIVE" ]; then
    echo "ℹ️  Found INACTIVE service: ${SERVICE_NAME} (status: ${SERVICE_STATUS})"
  else
    echo "ℹ️  No existing service found"
  fi
  echo "🆕 This will be a CREATE deployment"
fi

# Ask for confirmation
echo ""
if [ "${DEPLOYMENT_TYPE}" = "update" ]; then
  echo "⚠️  This will update the existing service with a new image."
  echo "The service will be updated with rolling deployment (no downtime)."
else
  echo "🆕 This will create a new service: ${SERVICE_NAME}"
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
  
  # Create new task definition revision
  echo "📝 Creating new task definition revision..."
  
  # Get the current task definition
  CURRENT_TASK_DEF=$(aws ecs describe-services \
    --cluster ${CLUSTER_NAME} \
    --services ${SERVICE_NAME} \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} \
    --query 'services[0].taskDefinition' --output text)
  
  echo "Current task definition: ${CURRENT_TASK_DEF}"
  
  # Get current task definition details
  aws ecs describe-task-definition \
    --task-definition ${CURRENT_TASK_DEF} \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} \
    --query 'taskDefinition' > /tmp/current-task-def.json
  
  # Update the image in task definition
  python3 << EOF
import json

# Read current task definition
with open('/tmp/current-task-def.json', 'r') as f:
    task_def = json.load(f)

# Update the image
for container in task_def['containerDefinitions']:
    if container['name'] == 'glossary-container':
        container['image'] = '${ECR_IMAGE_URI}'

# Remove read-only fields
fields_to_remove = ['taskDefinitionArn', 'revision', 'status', 'requiresAttributes', 'placementConstraints', 'compatibilities', 'registeredAt', 'registeredBy']
for field in fields_to_remove:
    task_def.pop(field, None)

# Write updated task definition
with open('/tmp/updated-task-def.json', 'w') as f:
    json.dump(task_def, f, indent=2)
EOF

  # Register new task definition
  NEW_TASK_DEF_ARN=$(aws ecs register-task-definition \
    --cli-input-json file:///tmp/updated-task-def.json \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} \
    --query 'taskDefinition.taskDefinitionArn' --output text)
  
  echo "✅ New task definition registered: ${NEW_TASK_DEF_ARN}"
  
  # Update the service
  echo "🔄 Updating service with new task definition..."
  aws ecs update-service \
    --cluster ${CLUSTER_NAME} \
    --service ${SERVICE_NAME} \
    --task-definition ${NEW_TASK_DEF_ARN} \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG}
  
  echo "⏳ Waiting for service update to complete..."
  aws ecs wait services-stable \
    --cluster ${CLUSTER_NAME} \
    --services ${SERVICE_NAME} \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG}
  
  echo "✅ Service updated successfully!"

else
  echo ""
  echo "========================================="
  echo "CREATING NEW SERVICE"
  echo "========================================="
  
  # Check if cluster exists
  echo "📋 Checking ECS cluster..."
  if ! aws ecs describe-clusters --clusters ${CLUSTER_NAME} --region ${AWS_REGION} ${AWS_PROFILE_ARG} > /dev/null 2>&1; then
    echo "Creating ECS cluster: ${CLUSTER_NAME}"
    aws ecs create-cluster \
      --cluster-name ${CLUSTER_NAME} \
      --capacity-providers FARGATE \
      --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 \
      --region ${AWS_REGION} \
      ${AWS_PROFILE_ARG}
  else
    echo "✅ ECS cluster exists: ${CLUSTER_NAME}"
  fi

  # Get VPC info (use default VPC for simplicity)
  echo "🌐 Getting VPC information..."
  VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text --region ${AWS_REGION} ${AWS_PROFILE_ARG})
  SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --query 'Subnets[].SubnetId' --output text --region ${AWS_REGION} ${AWS_PROFILE_ARG})
  SUBNET_ID_1=$(echo ${SUBNET_IDS} | cut -d' ' -f1)
  SUBNET_ID_2=$(echo ${SUBNET_IDS} | cut -d' ' -f2)

  echo "VPC ID: ${VPC_ID}"
  echo "Subnets: ${SUBNET_ID_1}, ${SUBNET_ID_2}"

  # Create security group if it doesn't exist
  SG_NAME="glossary-sg"
  echo "🔒 Setting up security group..."

  SG_ID=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=${SG_NAME}" "Name=vpc-id,Values=${VPC_ID}" \
    --query 'SecurityGroups[0].GroupId' --output text --region ${AWS_REGION} ${AWS_PROFILE_ARG} 2>/dev/null || echo "None")

  if [ "${SG_ID}" = "None" ] || [ "${SG_ID}" = "" ]; then
    echo "Creating security group: ${SG_NAME}"
    SG_ID=$(aws ec2 create-security-group \
      --group-name ${SG_NAME} \
      --description "Security group for Glossary Generator" \
      --vpc-id ${VPC_ID} \
      --query 'GroupId' --output text --region ${AWS_REGION} ${AWS_PROFILE_ARG})
    
    # Add inbound rule for port 5000 - OPEN TO ALL (0.0.0.0/0)
    # This allows public access to the application
    aws ec2 authorize-security-group-ingress \
      --group-id ${SG_ID} \
      --protocol tcp \
      --port 5000 \
      --cidr 0.0.0.0/0 \
      --region ${AWS_REGION} \
      ${AWS_PROFILE_ARG}
    
    echo "✅ Security group created with open access: ${SG_ID}"
  else
    echo "✅ Security group exists: ${SG_ID}"
  fi

  # Create task execution role if it doesn't exist
  ROLE_NAME="ecsTaskExecutionRole-glossary"
  echo "👤 Setting up IAM role..."

  if ! aws iam get-role --role-name ${ROLE_NAME} ${AWS_PROFILE_ARG} > /dev/null 2>&1; then
    echo "Creating IAM role: ${ROLE_NAME}"
    
    # Create trust policy
    cat > /tmp/trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    aws iam create-role \
      --role-name ${ROLE_NAME} \
      --assume-role-policy-document file:///tmp/trust-policy.json \
      ${AWS_PROFILE_ARG}

    aws iam attach-role-policy \
      --role-name ${ROLE_NAME} \
      --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy \
      ${AWS_PROFILE_ARG}

    # Wait for role to be ready
    sleep 10
  else
    echo "✅ IAM role exists: ${ROLE_NAME}"
  fi

  ROLE_ARN=$(aws iam get-role --role-name ${ROLE_NAME} --query 'Role.Arn' --output text ${AWS_PROFILE_ARG})

  # Create task definition
  echo "📝 Creating task definition..."
  cat > /tmp/task-definition.json << EOF
{
  "family": "${TASK_FAMILY}",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "${CPU}",
  "memory": "${MEMORY}",
  "executionRoleArn": "${ROLE_ARN}",
  "containerDefinitions": [
    {
      "name": "glossary-container",
      "image": "${ECR_IMAGE_URI}",
      "portMappings": [
        {
          "containerPort": 5000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "DATABASE_URL",
          "value": "${DATABASE_URL}"
        },
        {
          "name": "API_BASE_URL", 
          "value": "${API_BASE_URL}"
        },
        {
          "name": "API_KEY",
          "value": "${API_KEY}"
        },
        {
          "name": "DATABASE_SCHEMA",
          "value": "${DATABASE_SCHEMA}"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/glossary",
          "awslogs-region": "${AWS_REGION}",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
EOF

  # Create CloudWatch log group
  aws logs create-log-group --log-group-name "/ecs/glossary" --region ${AWS_REGION} ${AWS_PROFILE_ARG} 2>/dev/null || true

  # Register task definition
  TASK_DEFINITION_ARN=$(aws ecs register-task-definition \
    --cli-input-json file:///tmp/task-definition.json \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} \
    --query 'taskDefinition.taskDefinitionArn' --output text)

  echo "✅ Task definition registered: ${TASK_DEFINITION_ARN}"

  # Create service
  echo "🚀 Creating ECS service..."
  aws ecs create-service \
    --cluster ${CLUSTER_NAME} \
    --service-name ${SERVICE_NAME} \
    --task-definition ${TASK_FAMILY} \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_ID_1},${SUBNET_ID_2}],securityGroups=[${SG_ID}],assignPublicIp=ENABLED}" \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG}

  echo "⏳ Waiting for service to become stable..."
  aws ecs wait services-stable \
    --cluster ${CLUSTER_NAME} \
    --services ${SERVICE_NAME} \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG}

  echo "✅ Service created successfully!"
fi

# Get the public IP
echo "🔍 Getting service information..."
TASK_ARN=$(aws ecs list-tasks \
  --cluster ${CLUSTER_NAME} \
  --service-name ${SERVICE_NAME} \
  --query 'taskArns[0]' --output text --region ${AWS_REGION} ${AWS_PROFILE_ARG})

ENI_ID=$(aws ecs describe-tasks \
  --cluster ${CLUSTER_NAME} \
  --tasks ${TASK_ARN} \
  --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text --region ${AWS_REGION} ${AWS_PROFILE_ARG})

PUBLIC_IP=$(aws ec2 describe-network-interfaces \
  --network-interface-ids ${ENI_ID} \
  --query 'NetworkInterfaces[0].Association.PublicIp' --output text --region ${AWS_REGION} ${AWS_PROFILE_ARG})

echo ""
echo "✅ Deployment successful!"
echo "🌐 Public IP: ${PUBLIC_IP}"
echo "🔗 Health check: http://${PUBLIC_IP}:5000/health"
echo "⚙️  Config: http://${PUBLIC_IP}:5000/config"
echo ""
echo "📊 Service details:"
echo "   Cluster: ${CLUSTER_NAME}"
echo "   Service: ${SERVICE_NAME}"
echo "   Task Definition: ${TASK_FAMILY}"
echo "   Environment: ${ENVIRONMENT}"
echo "   Deployment Type: ${DEPLOYMENT_TYPE}"
echo ""
if [ "${DEPLOYMENT_TYPE}" = "create" ]; then
  echo "✅ New ${ENVIRONMENT} service created successfully!"
else
  echo "✅ ${ENVIRONMENT} service updated successfully with rolling deployment!"
fi

# Save deployment info with environment suffix
DEPLOYMENT_INFO_FILE="deploy/deployment-info-${ENVIRONMENT}.env"
echo "export ECS_CLUSTER_NAME=\"${CLUSTER_NAME}\"" > ${DEPLOYMENT_INFO_FILE}
echo "export ECS_SERVICE_NAME=\"${SERVICE_NAME}\"" >> ${DEPLOYMENT_INFO_FILE}
echo "export ECS_PUBLIC_IP=\"${PUBLIC_IP}\"" >> ${DEPLOYMENT_INFO_FILE}
echo "export DEPLOYMENT_TYPE=\"${DEPLOYMENT_TYPE}\"" >> ${DEPLOYMENT_INFO_FILE}
echo "export ENVIRONMENT=\"${ENVIRONMENT}\"" >> ${DEPLOYMENT_INFO_FILE}
