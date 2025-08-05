#!/bin/bash
# Master quick access script for all environments

echo "🚀 Glossary Service Quick Access (Static IPs)"
echo "============================================="
echo ""

echo "🧪 Test Environment (Static IP):"
echo "   URL: http://98.82.64.9:8080"
echo "   Quick access: ./deploy/access-test-static.sh"

echo ""

echo "🏭 Production Environment (Static IP):"
echo "   URL: http://98.82.64.9:80 or http://3.212.111.131:80"
echo "   Quick access: ./deploy/access-prod-static.sh"

echo ""
echo "🔧 Management:"
echo "   ./deploy/99-deploy-full-ecs-test.sh - Deploy test"
echo "   ./deploy/99-deploy-full-ecs-production.sh - Deploy production"
echo ""
echo "🏗️ Infrastructure (one-time setup - already completed):"
echo "   ./deploy/setup-nlb-static-ips.sh - Setup NLB with static IPs"
echo "   ./deploy/update-ecs-for-nlb.sh - Connect ECS services to NLB"
