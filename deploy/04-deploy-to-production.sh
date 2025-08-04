#!/bin/bash

# Deploy to PRODUCTION environment
# This is a convenience script for production deployments

set -e

echo "📦 Deploying to PRODUCTION environment..."
echo ""
echo "⚠️  WARNING: This will deploy to live production services!"
echo "   ECS Service: glossary-service"
echo "   App Runner: glossary-apprunner"
echo ""

# Safety check - recommend testing first
if [ ! -f deploy/deployment-info-test.env ] && [ ! -f deploy/apprunner-deployment-info-test.env ]; then
  echo "⚠️  No test deployment found."
  echo "💡 Consider testing first with: ./deploy/04-deploy-to-test.sh"
  echo ""
fi

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
    echo "📦 Deploying to ECS production environment..."
    ./deploy/03-deploy-to-ecs.sh production
    ;;
  2)
    echo ""
    echo "📦 Deploying to App Runner production environment..."
    ./deploy/03-deploy-to-apprunner.sh production
    ;;
  *)
    echo "❌ Invalid choice. Exiting."
    exit 1
    ;;
esac

echo ""
echo "🎉 Production deployment complete!"
echo ""
echo "💡 Monitor your application and check logs to ensure everything is working properly."
