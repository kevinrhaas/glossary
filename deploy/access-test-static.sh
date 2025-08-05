#!/bin/bash
# Static IP access for test environment

export STATIC_IP1="98.82.64.9"
export STATIC_IP2="3.212.111.131"
export PRIMARY_URL="http://${STATIC_IP1}:8080"
export SECONDARY_URL="http://${STATIC_IP2}:8080"

echo "🧪 Test Environment (STATIC IPs) - NEVER CHANGE"
echo "Primary:   ${PRIMARY_URL}"
echo "Secondary: ${SECONDARY_URL}"
echo ""

case "$1" in
    "open")
        echo "Opening test environment in browser..."
        open ${PRIMARY_URL}
        ;;
    "health")
        echo "Checking health via static IP..."
        echo "Testing primary IP..."
        curl -s ${PRIMARY_URL}/health | jq . || (echo "Primary failed, trying secondary..." && curl -s ${SECONDARY_URL}/health | jq .)
        ;;
    "config")
        echo "Getting config via static IP..."
        curl -s ${PRIMARY_URL}/config | head -10
        ;;
    "test")
        echo "Running quick API test via static IP..."
        curl -s ${PRIMARY_URL}/prompts | head -5
        ;;
    *)
        echo "Usage: $0 [open|health|config|test]"
        echo "   open   - Open in browser"
        echo "   health - Check health"
        echo "   config - Show config"
        echo "   test   - Quick API test"
        echo ""
        echo "🌐 Static URLs:"
        echo "   Primary:   ${PRIMARY_URL}"
        echo "   Secondary: ${SECONDARY_URL}"
        ;;
esac
