#!/bin/bash

# Deploy to TEST environment
# This is a convenience script for deploying to test before production

set -e

echo "🧪 Deploying to TEST environment..."
echo ""
echo "This will deploy to isolated test services:"
echo "   ECS Service: glossary-service-test"
echo "   App Runner: glossary-apprunner-test"
echo ""

# Ask which platform
echo "Choose deployment platform:"
echo "1) ECS Fargate (more control, manage scaling)"
echo "2) App Runner (simpler, automatic scaling)"
echo ""
read -p "Enter choice (1 or 2): " -n 1 -r
echo

case $REPLY in
  1)
    echo ""
    echo "🚀 Deploying to ECS test environment..."
    ./deploy/03-deploy-to-ecs.sh test
    ;;
  2)
    echo ""
    echo "🚀 Deploying to App Runner test environment..."
    ./deploy/03-deploy-to-apprunner.sh test
    ;;
  *)
    echo "❌ Invalid choice. Exiting."
    exit 1
    ;;
esac

echo ""
echo "✅ Test deployment complete!"
echo ""
echo "💡 Next steps:"
echo "   1. Test your application thoroughly"
echo "   2. If everything works, deploy to production:"
echo "      ./deploy/04-deploy-to-production.sh"
