#!/bin/bash

# Check status of all deployment environments
# Shows which services are running and their health status

set -e

echo "📊 Deployment Status - All Environments"
echo "========================================"

AWS_REGION="us-east-1"
CLUSTER_NAME="glossary-cluster"

# AWS Profile Configuration
AWS_PROFILE="khaas"
AWS_PROFILE_ARG=""
if [ ! -z "${AWS_PROFILE}" ]; then
  AWS_PROFILE_ARG="--profile ${AWS_PROFILE}"
  echo "Using AWS Profile: ${AWS_PROFILE}"
else
  AWS_PROFILE_ARG=""
  echo "Using default AWS credentials"
fi
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

check_ecs_service() {
  local env=$1
  local service_name=$2
  
  echo -e "\n${BLUE}🔍 ECS ${env} Environment:${NC}"
  echo "   Service: ${service_name}"
  
  # Check if service exists
  local service_status=$(aws ecs describe-services \
    --cluster ${CLUSTER_NAME} \
    --services ${service_name} \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} \
    --query 'services[0].status' --output text 2>/dev/null || echo "NotFound")
  
  if [ "${service_status}" = "NotFound" ] || [ "${service_status}" = "None" ]; then
    echo -e "   Status: ${RED}❌ NOT DEPLOYED${NC}"
    return
  fi
  
  local running_count=$(aws ecs describe-services \
    --cluster ${CLUSTER_NAME} \
    --services ${service_name} \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} \
    --query 'services[0].runningCount' --output text 2>/dev/null || echo "0")
  
  local desired_count=$(aws ecs describe-services \
    --cluster ${CLUSTER_NAME} \
    --services ${service_name} \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} \
    --query 'services[0].desiredCount' --output text 2>/dev/null || echo "0")
  
  if [ "${running_count}" = "${desired_count}" ] && [ "${running_count}" != "0" ]; then
    echo -e "   Status: ${GREEN}✅ RUNNING${NC} (${running_count}/${desired_count} tasks)"
    
    # Try to get public IP and test health
    local task_arn=$(aws ecs list-tasks \
      --cluster ${CLUSTER_NAME} \
      --service-name ${service_name} \
      --query 'taskArns[0]' --output text --region ${AWS_REGION} \
      ${AWS_PROFILE_ARG} 2>/dev/null || echo "")
    
    if [ -n "${task_arn}" ] && [ "${task_arn}" != "None" ]; then
      local eni_id=$(aws ecs describe-tasks \
        --cluster ${CLUSTER_NAME} \
        --tasks ${task_arn} \
        --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text --region ${AWS_REGION} \
        ${AWS_PROFILE_ARG} 2>/dev/null || echo "")
      
      if [ -n "${eni_id}" ] && [ "${eni_id}" != "None" ]; then
        local public_ip=$(aws ec2 describe-network-interfaces \
          --network-interface-ids ${eni_id} \
          --query 'NetworkInterfaces[0].Association.PublicIp' --output text --region ${AWS_REGION} \
          ${AWS_PROFILE_ARG} 2>/dev/null || echo "")
        
        if [ -n "${public_ip}" ] && [ "${public_ip}" != "None" ]; then
          echo "   Public IP: ${public_ip}"
          
          # Test health endpoint
          if curl -s -f "http://${public_ip}:5000/health" > /dev/null 2>&1; then
            echo -e "   Health: ${GREEN}✅ HEALTHY${NC}"
            echo "   URLs: http://${public_ip}:5000/health | http://${public_ip}:5000/config"
          else
            echo -e "   Health: ${YELLOW}⚠️  NOT RESPONDING${NC}"
          fi
        fi
      fi
    fi
  else
    echo -e "   Status: ${YELLOW}⚠️  STARTING/UPDATING${NC} (${running_count}/${desired_count} tasks)"
  fi
}

check_apprunner_service() {
  local env=$1
  local service_name=$2
  
  echo -e "\n${BLUE}🔍 App Runner ${env} Environment:${NC}"
  echo "   Service: ${service_name}"
  
  # Check if service exists
  local service_arn=$(aws apprunner list-services \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} \
    --query "ServiceSummaryList[?ServiceName=='${service_name}'].ServiceArn" --output text 2>/dev/null || echo "")
  
  if [ -z "${service_arn}" ] || [ "${service_arn}" = "" ]; then
    echo -e "   Status: ${RED}❌ NOT DEPLOYED${NC}"
    return
  fi
  
  local service_status=$(aws apprunner describe-service \
    --service-arn ${service_arn} \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} \
    --query 'Service.Status' --output text 2>/dev/null || echo "UNKNOWN")
  
  case "${service_status}" in
    "RUNNING")
      echo -e "   Status: ${GREEN}✅ RUNNING${NC}"
      
      local service_url=$(aws apprunner describe-service \
        --service-arn ${service_arn} \
        --region ${AWS_REGION} \
        ${AWS_PROFILE_ARG} \
        --query 'Service.ServiceUrl' --output text 2>/dev/null || echo "")
      
      if [ -n "${service_url}" ]; then
        echo "   Service URL: ${service_url}"
        
        # Test health endpoint
        if curl -s -f "https://${service_url}/health" > /dev/null 2>&1; then
          echo -e "   Health: ${GREEN}✅ HEALTHY${NC}"
          echo "   URLs: https://${service_url}/health | https://${service_url}/config"
        else
          echo -e "   Health: ${YELLOW}⚠️  NOT RESPONDING${NC}"
        fi
      fi
      ;;
    "CREATE_IN_PROGRESS"|"UPDATE_IN_PROGRESS")
      echo -e "   Status: ${YELLOW}⚠️  DEPLOYING${NC}"
      ;;
    "CREATE_FAILED"|"UPDATE_FAILED")
      echo -e "   Status: ${RED}❌ FAILED${NC}"
      ;;
    *)
      echo -e "   Status: ${YELLOW}⚠️  ${service_status}${NC}"
      ;;
  esac
}

# Check all environments
echo ""

# Production
echo -e "${GREEN}📦 PRODUCTION ENVIRONMENT${NC}"
check_ecs_service "Production" "glossary-service"
check_apprunner_service "Production" "glossary-apprunner"

# Test
echo -e "\n${YELLOW}🧪 TEST ENVIRONMENT${NC}"
check_ecs_service "Test" "glossary-service-test"
check_apprunner_service "Test" "glossary-apprunner-test"

echo ""
echo "========================================"
echo "💡 To deploy to an environment:"
echo "   Test: ./deploy/04-deploy-to-test.sh"
echo "   Prod: ./deploy/04-deploy-to-production.sh"
echo ""
