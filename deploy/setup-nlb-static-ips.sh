#!/bin/bash

# Network Load Balancer with Static IPs
# This appr    # Allocate new EIP
    EIP1_RESULT=$(aws ec2 allocate-address \
        --domain vpc \
        --region ${AWS_REGION} \
        ${AWS_PROFILE_ARG} \
        --query '{AllocationId:AllocationId,PublicIp:PublicIp}' \
        --output json)
    
    EIP1=$(echo ${EIP1_RESULT} | jq -r '.AllocationId')
    EIP1_IP=$(echo ${EIP1_RESULT} | jq -r '.PublicIp')
    
    # Tag the EIP
    aws ec2 create-tags \
        --resources ${EIP1} \
        --tags Key=Name,Value=${EIP1_TAG} Key=Project,Value=${PROJECT_NAME} \
        --region ${AWS_REGION} \
        ${AWS_PROFILE_ARG}
    
    echo "✅ Created EIP 1: ${EIP1_IP} (${EIP1})" CAN have static Elastic IPs assigned
# and doesn't require the association permissions you're missing

set -e

# Configuration
AWS_REGION="us-east-1"
PROJECT_NAME="glossary"

# Check if AWS profile argument is needed
if [ -n "$AWS_PROFILE" ]; then
    AWS_PROFILE_ARG="--profile $AWS_PROFILE"
else
    AWS_PROFILE_ARG=""
fi

echo "🔗 Setting up Network Load Balancer with Static IPs..."
echo "Region: ${AWS_REGION}"
echo ""

# Get VPC and subnets
echo "🔍 Finding VPC and subnets..."
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=is-default,Values=true" \
    --query 'Vpcs[0].VpcId' \
    --output text \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG})

SUBNET_IDS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=${VPC_ID}" "Name=default-for-az,Values=true" \
    --query 'Subnets[].SubnetId' \
    --output text \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG})

# Convert to array for individual subnet handling
SUBNET_ARRAY=($SUBNET_IDS)
SUBNET1=${SUBNET_ARRAY[0]}
SUBNET2=${SUBNET_ARRAY[1]}

echo "✅ VPC: $VPC_ID"
echo "✅ Subnet 1: $SUBNET1"
echo "✅ Subnet 2: $SUBNET2"

# Allocate Elastic IPs for NLB
echo ""
echo "💰 Allocating Elastic IPs for NLB..."

# Check for existing EIPs
EIP1_TAG="glossary-nlb-eip-1"
EIP2_TAG="glossary-nlb-eip-2"

EIP1=$(aws ec2 describe-addresses \
    --filters "Name=tag:Name,Values=${EIP1_TAG}" \
    --query 'Addresses[0].AllocationId' \
    --output text \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} 2>/dev/null || echo "None")

if [ "$EIP1" = "None" ]; then
    echo "Creating first Elastic IP..."
    EIP1_RESULT=$(aws ec2 allocate-address \
        --domain vpc \
        --region ${AWS_REGION} \
        ${AWS_PROFILE_ARG} \
        --query '{AllocationId:AllocationId,PublicIp:PublicIp}' \
        --output text)
    
    EIP1=$(echo ${EIP1_RESULT} | cut -f1)
    EIP1_IP=$(echo ${EIP1_RESULT} | cut -f2)
    
    # Tag the EIP
    aws ec2 create-tags \
        --resources ${EIP1} \
        --tags Key=Name,Value=${EIP1_TAG} Key=Project,Value=${PROJECT_NAME} \
        --region ${AWS_REGION} \
        ${AWS_PROFILE_ARG}
    
    echo "✅ Created EIP 1: ${EIP1_IP} (${EIP1})"
else
    EIP1_IP=$(aws ec2 describe-addresses \
        --allocation-ids ${EIP1} \
        --query 'Addresses[0].PublicIp' \
        --output text \
        --region ${AWS_REGION} \
        ${AWS_PROFILE_ARG})
    echo "✅ Using existing EIP 1: ${EIP1_IP} (${EIP1})"
fi

# Second EIP (for high availability)
EIP2=$(aws ec2 describe-addresses \
    --filters "Name=tag:Name,Values=${EIP2_TAG}" \
    --query 'Addresses[0].AllocationId' \
    --output text \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} 2>/dev/null || echo "None")

if [ "$EIP2" = "None" ]; then
    echo "Creating second Elastic IP..."
    EIP2_RESULT=$(aws ec2 allocate-address \
        --domain vpc \
        --region ${AWS_REGION} \
        ${AWS_PROFILE_ARG} \
        --query '{AllocationId:AllocationId,PublicIp:PublicIp}' \
        --output json)
    
    EIP2=$(echo ${EIP2_RESULT} | jq -r '.AllocationId')
    EIP2_IP=$(echo ${EIP2_RESULT} | jq -r '.PublicIp')
    
    # Tag the EIP
    aws ec2 create-tags \
        --resources ${EIP2} \
        --tags Key=Name,Value=${EIP2_TAG} Key=Project,Value=${PROJECT_NAME} \
        --region ${AWS_REGION} \
        ${AWS_PROFILE_ARG}
    
    echo "✅ Created EIP 2: ${EIP2_IP} (${EIP2})"
else
    EIP2_IP=$(aws ec2 describe-addresses \
        --allocation-ids ${EIP2} \
        --query 'Addresses[0].PublicIp' \
        --output text \
        --region ${AWS_REGION} \
        ${AWS_PROFILE_ARG})
    echo "✅ Using existing EIP 2: ${EIP2_IP} (${EIP2})"
fi

# Create Network Load Balancer
echo ""
echo "🌐 Creating Network Load Balancer..."
NLB_NAME="${PROJECT_NAME}-nlb"

NLB_ARN=$(aws elbv2 describe-load-balancers \
    --names ${NLB_NAME} \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} 2>/dev/null || echo "None")

if [ "$NLB_ARN" = "None" ]; then
    echo "Creating new NLB with static IPs..."
    NLB_ARN=$(aws elbv2 create-load-balancer \
        --name ${NLB_NAME} \
        --scheme internet-facing \
        --type network \
        --subnet-mappings SubnetId=${SUBNET1},AllocationId=${EIP1} SubnetId=${SUBNET2},AllocationId=${EIP2} \
        --tags Key=Name,Value=${NLB_NAME} Key=Project,Value=${PROJECT_NAME} \
        --query 'LoadBalancers[0].LoadBalancerArn' \
        --output text \
        --region ${AWS_REGION} \
        ${AWS_PROFILE_ARG})
    
    echo "✅ Created NLB: ${NLB_ARN}"
else
    echo "✅ Using existing NLB: ${NLB_ARN}"
fi

# Get NLB DNS name
NLB_DNS=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns ${NLB_ARN} \
    --query 'LoadBalancers[0].DNSName' \
    --output text \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG})

echo "🌐 NLB DNS: ${NLB_DNS}"

# Create Target Groups
echo ""
echo "🎯 Creating target groups..."

# Production Target Group
PROD_TG_NAME="${PROJECT_NAME}-nlb-prod-tg"
PROD_TG_ARN=$(aws elbv2 describe-target-groups \
    --names ${PROD_TG_NAME} \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} 2>/dev/null || echo "None")

if [ "$PROD_TG_ARN" = "None" ]; then
    PROD_TG_ARN=$(aws elbv2 create-target-group \
        --name ${PROD_TG_NAME} \
        --protocol TCP \
        --port 5000 \
        --vpc-id ${VPC_ID} \
        --target-type ip \
        --health-check-protocol HTTP \
        --health-check-path /health \
        --health-check-interval-seconds 30 \
        --healthy-threshold-count 2 \
        --unhealthy-threshold-count 2 \
        --tags Key=Name,Value=${PROD_TG_NAME} Key=Environment,Value=production Key=Project,Value=${PROJECT_NAME} \
        --query 'TargetGroups[0].TargetGroupArn' \
        --output text \
        --region ${AWS_REGION} \
        ${AWS_PROFILE_ARG})
    echo "✅ Created production target group: ${PROD_TG_ARN}"
else
    echo "✅ Using existing production target group: ${PROD_TG_ARN}"
fi

# Test Target Group  
TEST_TG_NAME="${PROJECT_NAME}-nlb-test-tg"
TEST_TG_ARN=$(aws elbv2 describe-target-groups \
    --names ${TEST_TG_NAME} \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} 2>/dev/null || echo "None")

if [ "$TEST_TG_ARN" = "None" ]; then
    TEST_TG_ARN=$(aws elbv2 create-target-group \
        --name ${TEST_TG_NAME} \
        --protocol TCP \
        --port 5001 \
        --vpc-id ${VPC_ID} \
        --target-type ip \
        --health-check-protocol HTTP \
        --health-check-path /health \
        --health-check-interval-seconds 30 \
        --healthy-threshold-count 2 \
        --unhealthy-threshold-count 2 \
        --tags Key=Name,Value=${TEST_TG_NAME} Key=Environment,Value=test Key=Project,Value=${PROJECT_NAME} \
        --query 'TargetGroups[0].TargetGroupArn' \
        --output text \
        --region ${AWS_REGION} \
        ${AWS_PROFILE_ARG})
    echo "✅ Created test target group: ${TEST_TG_ARN}"
else
    echo "✅ Using existing test target group: ${TEST_TG_ARN}"
fi

# Create Listeners
echo ""
echo "👂 Creating listeners..."

# Production listener (port 80)
PROD_LISTENER_ARN=$(aws elbv2 describe-listeners \
    --load-balancer-arn ${NLB_ARN} \
    --query 'Listeners[?Port==`80`].ListenerArn' \
    --output text \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} 2>/dev/null || echo "None")

if [ "$PROD_LISTENER_ARN" = "None" ]; then
    PROD_LISTENER_ARN=$(aws elbv2 create-listener \
        --load-balancer-arn ${NLB_ARN} \
        --protocol TCP \
        --port 80 \
        --default-actions Type=forward,TargetGroupArn=${PROD_TG_ARN} \
        --query 'Listeners[0].ListenerArn' \
        --output text \
        --region ${AWS_REGION} \
        ${AWS_PROFILE_ARG})
    echo "✅ Created production listener (port 80): ${PROD_LISTENER_ARN}"
else
    echo "✅ Using existing production listener: ${PROD_LISTENER_ARN}"
fi

# Test listener (port 8080)
TEST_LISTENER_ARN=$(aws elbv2 describe-listeners \
    --load-balancer-arn ${NLB_ARN} \
    --query 'Listeners[?Port==`8080`].ListenerArn' \
    --output text \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} 2>/dev/null || echo "None")

if [ "$TEST_LISTENER_ARN" = "None" ]; then
    TEST_LISTENER_ARN=$(aws elbv2 create-listener \
        --load-balancer-arn ${NLB_ARN} \
        --protocol TCP \
        --port 8080 \
        --default-actions Type=forward,TargetGroupArn=${TEST_TG_ARN} \
        --query 'Listeners[0].ListenerArn' \
        --output text \
        --region ${AWS_REGION} \
        ${AWS_PROFILE_ARG})
    echo "✅ Created test listener (port 8080): ${TEST_LISTENER_ARN}"
else
    echo "✅ Using existing test listener: ${TEST_LISTENER_ARN}"
fi

# Save configuration
echo ""
echo "💾 Saving NLB configuration..."
cat > deploy/nlb-config.env << EOF
# NLB Configuration
export NLB_ARN="${NLB_ARN}"
export NLB_DNS="${NLB_DNS}"
export EIP1="${EIP1}"
export EIP1_IP="${EIP1_IP}"
export EIP2="${EIP2}"
export EIP2_IP="${EIP2_IP}"
export PROD_TG_ARN="${PROD_TG_ARN}"
export TEST_TG_ARN="${TEST_TG_ARN}"
export VPC_ID="${VPC_ID}"

# Static IP URLs
export PROD_URL_IP1="http://${EIP1_IP}"
export PROD_URL_IP2="http://${EIP2_IP}"
export TEST_URL_IP1="http://${EIP1_IP}:8080"
export TEST_URL_IP2="http://${EIP2_IP}:8080"
export PROD_URL_DNS="http://${NLB_DNS}"
export TEST_URL_DNS="http://${NLB_DNS}:8080"
EOF

echo ""
echo "🎉 Network Load Balancer with Static IPs Complete!"
echo ""
echo "🌐 STATIC IP ENDPOINTS:"
echo "   Primary Static IP:   ${EIP1_IP}"
echo "   Secondary Static IP: ${EIP2_IP}"
echo ""
echo "🔗 ACCESS URLS:"
echo "   Production (static):  http://${EIP1_IP} or http://${EIP2_IP}"
echo "   Test (static):        http://${EIP1_IP}:8080 or http://${EIP2_IP}:8080"
echo "   Production (DNS):     http://${NLB_DNS}"
echo "   Test (DNS):           http://${NLB_DNS}:8080"
echo ""
echo "💡 Benefits:"
echo "   ✅ TRUE static IPs that never change"
echo "   ✅ No association permissions needed (NLB owns the IPs)"
echo "   ✅ High availability across AZs"
echo "   ✅ Layer 4 load balancing"
echo "   ✅ Works with any application protocol"
echo ""
echo "📋 Next Steps:"
echo "   1. Update ECS services to register with target groups"
echo "   2. Test the static IP endpoints"
echo ""
echo "🔧 Configuration saved to: deploy/nlb-config.env"
