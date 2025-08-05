#!/bin/bash

# Update ECS Services to use NLB Target Groups
# This connects your existing ECS services to the Network Load Balancer

set -e

# Configuration
AWS_REGION="us-east-1"

# Check if AWS profile argument is needed
if [ -n "$AWS_PROFILE" ]; then
    AWS_PROFILE_ARG="--profile $AWS_PROFILE"
else
    AWS_PROFILE_ARG=""
fi

# Load NLB configuration
if [ ! -f "deploy/nlb-config.env" ]; then
    echo "❌ NLB configuration not found. Run ./deploy/setup-nlb-static-ips.sh first"
    exit 1
fi

source deploy/nlb-config.env

echo "🔗 Updating ECS services to use NLB target groups..."
echo "Region: ${AWS_REGION}"
echo ""

# Create listeners if they don't exist
echo "👂 Ensuring NLB listeners are created..."

# Production listener (port 80 -> port 5000)
PROD_LISTENER_ARN=$(aws elbv2 describe-listeners \
    --load-balancer-arn ${NLB_ARN} \
    --query 'Listeners[?Port==`80`].ListenerArn' \
    --output text \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} 2>/dev/null || echo "None")

if [ "$PROD_LISTENER_ARN" = "None" ] || [ -z "$PROD_LISTENER_ARN" ]; then
    echo "Creating production listener (port 80)..."
    PROD_LISTENER_ARN=$(aws elbv2 create-listener \
        --load-balancer-arn ${NLB_ARN} \
        --protocol TCP \
        --port 80 \
        --default-actions Type=forward,TargetGroupArn=${PROD_TG_ARN} \
        --query 'Listeners[0].ListenerArn' \
        --output text \
        --region ${AWS_REGION} \
        ${AWS_PROFILE_ARG})
    echo "✅ Created production listener: ${PROD_LISTENER_ARN}"
else
    echo "✅ Using existing production listener: ${PROD_LISTENER_ARN}"
fi

# Test listener (port 8080 -> port 5000)
TEST_LISTENER_ARN=$(aws elbv2 describe-listeners \
    --load-balancer-arn ${NLB_ARN} \
    --query 'Listeners[?Port==`8080`].ListenerArn' \
    --output text \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} 2>/dev/null || echo "None")

if [ "$TEST_LISTENER_ARN" = "None" ] || [ -z "$TEST_LISTENER_ARN" ]; then
    echo "Creating test listener (port 8080)..."
    TEST_LISTENER_ARN=$(aws elbv2 create-listener \
        --load-balancer-arn ${NLB_ARN} \
        --protocol TCP \
        --port 8080 \
        --default-actions Type=forward,TargetGroupArn=${TEST_TG_ARN} \
        --query 'Listeners[0].ListenerArn' \
        --output text \
        --region ${AWS_REGION} \
        ${AWS_PROFILE_ARG})
    echo "✅ Created test listener: ${TEST_LISTENER_ARN}"
else
    echo "✅ Using existing test listener: ${TEST_LISTENER_ARN}"
fi

# Function to update ECS service with NLB target group
update_ecs_service_nlb() {
    local environment=$1
    local target_group_arn=$2
    local service_name="glossary-service"
    local cluster_name="glossary-cluster"
    
    if [ "$environment" = "test" ]; then
        service_name="glossary-service-test"
    fi
    
    echo ""
    echo "🔄 Updating ${environment} service: ${service_name}"
    
    # Force a new deployment with NLB target group
    aws ecs update-service \
        --cluster ${cluster_name} \
        --service ${service_name} \
        --force-new-deployment \
        --load-balancers targetGroupArn=${target_group_arn},containerName=glossary-container,containerPort=5000 \
        --region ${AWS_REGION} \
        ${AWS_PROFILE_ARG} > /dev/null
    
    echo "✅ Updated ${environment} service to use NLB"
    
    # Wait for service to stabilize
    echo "   ⏳ Waiting for service to stabilize..."
    aws ecs wait services-stable \
        --cluster ${cluster_name} \
        --services ${service_name} \
        --region ${AWS_REGION} \
        ${AWS_PROFILE_ARG}
    
    echo "   ✅ ${environment} service is stable"
    
    return 0
}

# Update production service
echo "🏭 Updating Production Environment:"
if update_ecs_service_nlb "production" "${PROD_TG_ARN}"; then
    echo "✅ Production service updated successfully"
else
    echo "❌ Failed to update production service"
fi

# Update test service  
echo ""
echo "🧪 Updating Test Environment:"
if update_ecs_service_nlb "test" "${TEST_TG_ARN}"; then
    echo "✅ Test service updated successfully"
else
    echo "❌ Failed to update test service"
fi

echo ""
echo "⏳ Waiting for NLB to register targets..."
sleep 30

# Check target group health
echo ""
echo "🎯 Checking target group health..."

echo "Production targets:"
aws elbv2 describe-target-health \
    --target-group-arn ${PROD_TG_ARN} \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} \
    --query 'TargetHealthDescriptions[].{IP:Target.Id,Port:Target.Port,Health:TargetHealth.State}' \
    --output table

echo ""
echo "Test targets:"
aws elbv2 describe-target-health \
    --target-group-arn ${TEST_TG_ARN} \
    --region ${AWS_REGION} \
    ${AWS_PROFILE_ARG} \
    --query 'TargetHealthDescriptions[].{IP:Target.Id,Port:Target.Port,Health:TargetHealth.State}' \
    --output table

# Test the static IP endpoints
echo ""
echo "🧪 Testing static IP endpoints..."

echo "Testing production endpoint (${EIP1_IP})..."
if curl -s --connect-timeout 10 "http://${EIP1_IP}/health" > /dev/null 2>&1; then
    echo "✅ Production static IP responding: http://${EIP1_IP}"
    curl -s "http://${EIP1_IP}/health" | jq .
else
    echo "⚠️ Production static IP not ready yet: http://${EIP1_IP}"
fi

echo ""
echo "Testing production endpoint (${EIP2_IP})..."
if curl -s --connect-timeout 10 "http://${EIP2_IP}/health" > /dev/null 2>&1; then
    echo "✅ Production static IP responding: http://${EIP2_IP}"
    curl -s "http://${EIP2_IP}/health" | jq .
else
    echo "⚠️ Production static IP not ready yet: http://${EIP2_IP}"
fi

echo ""
echo "Testing test endpoint (${EIP1_IP}:8080)..."
if curl -s --connect-timeout 10 "http://${EIP1_IP}:8080/health" > /dev/null 2>&1; then
    echo "✅ Test static IP responding: http://${EIP1_IP}:8080"
    curl -s "http://${EIP1_IP}:8080/health" | jq .
else
    echo "⚠️ Test static IP not ready yet: http://${EIP1_IP}:8080"
fi

echo ""
echo "🎉 NLB Integration Complete!"
echo ""
echo "🌐 YOUR STATIC IP ENDPOINTS:"
echo "   Production: http://${EIP1_IP} and http://${EIP2_IP}"
echo "   Test:       http://${EIP1_IP}:8080 and http://${EIP2_IP}:8080"
echo ""
echo "📋 Endpoint Details:"
echo "   • Production health: http://${EIP1_IP}/health"
echo "   • Production config: http://${EIP1_IP}/config"
echo "   • Test health:       http://${EIP1_IP}:8080/health"
echo "   • Test config:       http://${EIP1_IP}:8080/config"
echo ""
echo "💡 These IPs will NEVER change!"

# Create static IP access scripts
echo ""
echo "📝 Creating static IP access scripts..."

# Create access script for production static IPs
cat > deploy/access-prod-static.sh << EOF
#!/bin/bash
# Static IP access for production environment

export STATIC_IP1="${EIP1_IP}"
export STATIC_IP2="${EIP2_IP}"
export PRIMARY_URL="http://\${STATIC_IP1}"
export SECONDARY_URL="http://\${STATIC_IP2}"

echo "🏭 Production Environment (STATIC IPs) - NEVER CHANGE"
echo "Primary:   \${PRIMARY_URL}"
echo "Secondary: \${SECONDARY_URL}"
echo ""

case "\$1" in
    "open")
        echo "Opening production environment in browser..."
        open \${PRIMARY_URL}
        ;;
    "health")
        echo "Checking health via static IP..."
        curl -s \${PRIMARY_URL}/health | jq . || echo "Primary failed, trying secondary..." && curl -s \${SECONDARY_URL}/health | jq .
        ;;
    "config")
        echo "Getting config via static IP..."
        curl -s \${PRIMARY_URL}/config | head -10
        ;;
    "test")
        echo "Running quick API test via static IP..."
        curl -s \${PRIMARY_URL}/prompts | head -5
        ;;
    *)
        echo "Usage: \$0 [open|health|config|test]"
        echo "   open   - Open in browser"
        echo "   health - Check health"
        echo "   config - Show config"
        echo "   test   - Quick API test"
        echo ""
        echo "🌐 Static URLs:"
        echo "   Primary:   \${PRIMARY_URL}"
        echo "   Secondary: \${SECONDARY_URL}"
        ;;
esac
EOF

# Create access script for test static IPs
cat > deploy/access-test-static.sh << EOF
#!/bin/bash
# Static IP access for test environment

export STATIC_IP1="${EIP1_IP}"
export STATIC_IP2="${EIP2_IP}"
export PRIMARY_URL="http://\${STATIC_IP1}:8080"
export SECONDARY_URL="http://\${STATIC_IP2}:8080"

echo "🧪 Test Environment (STATIC IPs) - NEVER CHANGE"
echo "Primary:   \${PRIMARY_URL}"
echo "Secondary: \${SECONDARY_URL}"
echo ""

case "\$1" in
    "open")
        echo "Opening test environment in browser..."
        open \${PRIMARY_URL}
        ;;
    "health")
        echo "Checking health via static IP..."
        curl -s \${PRIMARY_URL}/health | jq . || echo "Primary failed, trying secondary..." && curl -s \${SECONDARY_URL}/health | jq .
        ;;
    "config")
        echo "Getting config via static IP..."
        curl -s \${PRIMARY_URL}/config | head -10
        ;;
    "test")
        echo "Running quick API test via static IP..."
        curl -s \${PRIMARY_URL}/prompts | head -5
        ;;
    *)
        echo "Usage: \$0 [open|health|config|test]"
        echo "   open   - Open in browser"
        echo "   health - Check health"
        echo "   config - Show config"
        echo "   test   - Quick API test"
        echo ""
        echo "🌐 Static URLs:"
        echo "   Primary:   \${PRIMARY_URL}"
        echo "   Secondary: \${SECONDARY_URL}"
        ;;
esac
EOF

chmod +x deploy/access-prod-static.sh
chmod +x deploy/access-test-static.sh

echo "✅ Created static IP access scripts:"
echo "   ./deploy/access-prod-static.sh"
echo "   ./deploy/access-test-static.sh"
