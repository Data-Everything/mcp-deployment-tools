#!/bin/bash

# Test deployment script for MCP Platform

set -e

BACKEND_URL=${BACKEND_URL:-"http://localhost:8000"}
TEMPLATE_ID=${1:-"file-server"}

echo "🧪 Testing MCP Platform Deployment"
echo "Backend URL: $BACKEND_URL"
echo "Template ID: $TEMPLATE_ID"

# Test configuration
CONFIG='{
  "configuration": {
    "allowed_directories": ["/tmp/mcp-files", "/data"],
    "read_only_mode": false,
    "enable_symlinks": true,
    "max_file_size": 100,
    "exclude_patterns": ["**/.git/**", "**/node_modules/**", "**/.env*"]
  }
}'

echo ""
echo "📋 Configuration:"
echo "$CONFIG" | jq .

echo ""
echo "🚀 Deploying template..."

# Deploy the template
RESPONSE=$(curl -s -X POST \
  "$BACKEND_URL/api/templates/deploy/$TEMPLATE_ID/" \
  -H "Content-Type: application/json" \
  -d "$CONFIG")

echo "📄 Response:"
echo "$RESPONSE" | jq .

# Extract deployment name if successful
DEPLOYMENT_NAME=$(echo "$RESPONSE" | jq -r '.deployment.deployment_name // empty')

if [[ -n "$DEPLOYMENT_NAME" ]]; then
    echo ""
    echo "✅ Deployment successful!"
    echo "Deployment Name: $DEPLOYMENT_NAME"
    
    echo ""
    echo "📊 Checking deployment status..."
    sleep 2
    
    # Check deployment status
    STATUS_RESPONSE=$(curl -s "$BACKEND_URL/api/templates/deployments/$DEPLOYMENT_NAME/")
    echo "$STATUS_RESPONSE" | jq .
    
    echo ""
    echo "📋 Listing all deployments..."
    curl -s "$BACKEND_URL/api/templates/deployments/" | jq .
    
    echo ""
    echo "🧹 To delete this deployment later, run:"
    echo "  curl -X DELETE $BACKEND_URL/api/templates/deployments/$DEPLOYMENT_NAME/delete/"
    
else
    echo ""
    echo "❌ Deployment failed!"
    exit 1
fi
