#!/bin/bash

# Script to monitor target group health for watch command
# Usage: ./watch-target-health.sh [test|prod]

TARGET_GROUP=${1:-test}

if [ "$TARGET_GROUP" = "test" ]; then
    TG_ARN="arn:aws:elasticloadbalancing:us-east-1:729973546399:targetgroup/glossary-nlb-test-tg/34e7583daa2debe3"
    echo "=== Test Environment Target Group Health ==="
elif [ "$TARGET_GROUP" = "prod" ]; then
    TG_ARN="arn:aws:elasticloadbalancing:us-east-1:729973546399:targetgroup/glossary-nlb-prod-tg/cbff6d8a86d3550b"
    echo "=== Production Environment Target Group Health ==="
else
    echo "Usage: $0 [test|prod]"
    exit 1
fi

# Use withokta with correct syntax
/Users/khaas/.okta/bin/withokta "/opt/homebrew/bin/aws --profile khaas elbv2 describe-target-health --target-group-arn $TG_ARN --region us-east-1 --query 'TargetHealthDescriptions[].{IP:Target.Id,Port:Target.Port,Health:TargetHealth.State,Description:TargetHealth.Description}' --output table"

echo ""
echo "Last updated: $(date)"
