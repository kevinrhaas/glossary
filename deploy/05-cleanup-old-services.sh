#!/bin/bash

# Step 5: Cleanup Old Services (Legacy)
# This script is mainly for cleaning up old v2 services from the original deployment scripts
# With smart deployment, this is rarely needed

set -e

echo "🧹 Cleaning up legacy services..."

# Configuration
AWS_REGION="us-east-1"
LEGACY_ECS_SERVICES=("glossary-service-v2")  # Old test services
CLUSTER_NAME="glossary-cluster"

echo "ℹ️  This script cleans up legacy services from old deployment scripts."
echo "With smart deployment, services are updated in place, so cleanup is rarely needed."
echo ""

# Check for legacy ECS services
for SERVICE in "${LEGACY_ECS_SERVICES[@]}"; do
  echo "🔍 Checking for legacy ECS service: ${SERVICE}..."
  
  if aws ecs describe-services 
    --cluster ${CLUSTER_NAME} 
    --services ${SERVICE} 
    --region ${AWS_REGION} 
    --query 'services[0].serviceName' --output text 2>/dev/null | grep -q ${SERVICE}; then
    
    echo "Found legacy service: ${SERVICE}"
    
    # Confirm cleanup
    echo ""
    echo "⚠️  This will remove the legacy service: ${SERVICE}"
    read -p "Continue with cleanup? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Cleanup cancelled for ${SERVICE}."
      continue
    fi
    
    # Scale down to 0
    echo "📉 Scaling down legacy service to 0 tasks..."
    aws ecs update-service 
      --cluster ${CLUSTER_NAME} 
      --service ${SERVICE} 
      --desired-count 0 
      --region ${AWS_REGION}
    
    # Wait for tasks to stop
    echo "⏳ Waiting for tasks to stop..."
    aws ecs wait services-stable 
      --cluster ${CLUSTER_NAME} 
      --services ${SERVICE} 
      --region ${AWS_REGION}
    
    # Delete the service
    echo "🗑️  Deleting legacy service..."
    aws ecs delete-service 
      --cluster ${CLUSTER_NAME} 
      --service ${SERVICE} 
      --region ${AWS_REGION}
    
    echo "✅ Legacy ECS service removed: ${SERVICE}"
  else
    echo "ℹ️  Legacy ECS service not found: ${SERVICE}"
  fi
done

# Check for legacy App Runner services
echo ""
echo "🔍 Checking for legacy App Runner services..."
LEGACY_APPRUNNER_SERVICES=$(aws apprunner list-services 
  --region ${AWS_REGION} 
  --query "ServiceSummaryList[?contains(ServiceName, 'v2')].{Name:ServiceName,Arn:ServiceArn}" --output table 2>/dev/null || echo "")

if [ -n "${LEGACY_APPRUNNER_SERVICES}" ]; then
  echo "Found legacy App Runner services:"
  echo "${LEGACY_APPRUNNER_SERVICES}"
  echo ""
  echo "To clean up App Runner services manually:"
  echo "   aws apprunner delete-service --service-arn <service-arn> --region ${AWS_REGION}"
else
  echo "ℹ️  No legacy App Runner services found"
fi

# List old task definitions for manual cleanup
echo ""
echo "📋 Old task definitions (manual cleanup if needed):"
aws ecs list-task-definitions 
  --family-prefix glossary-task-v2 
  --status ACTIVE 
  --region ${AWS_REGION} 
  --query 'taskDefinitionArns[]' --output table 2>/dev/null || echo "None found"

echo ""
echo "🧹 To clean up old task definitions manually:"
echo "   aws ecs deregister-task-definition --task-definition <task-definition-arn> --region ${AWS_REGION}"

echo ""
echo "✅ Step 5 Complete: Legacy services cleanup"
echo ""
echo "ℹ️  Note: With smart deployment, services are updated in place."
echo "This cleanup is mainly for removing old test services from previous deployments."