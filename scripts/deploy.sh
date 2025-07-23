#!/bin/bash

# MCP Platform Deployment Script
# Deploys MCP servers using Docker or Kubernetes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
DEPLOYMENT_TYPE="docker"
CONFIG_FILE=""
TEMPLATE_ID=""
SERVER_NAME=""
ENVIRONMENT="production"

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --type TYPE         Deployment type: docker, kubernetes (default: docker)"
    echo "  -c, --config FILE       Configuration file path"
    echo "  -i, --template ID       Template ID to deploy"
    echo "  -n, --name NAME         Server name"
    echo "  -e, --env ENV           Environment: dev, staging, production (default: production)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --type docker --template file-server --name my-files --config config.json"
    echo "  $0 --type kubernetes --template database --name db-server"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            DEPLOYMENT_TYPE="$2"
            shift 2
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -i|--template)
            TEMPLATE_ID="$2"
            shift 2
            ;;
        -n|--name)
            SERVER_NAME="$2"
            shift 2
            ;;
        -e|--env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$TEMPLATE_ID" ]; then
    echo "Error: Template ID is required"
    usage
    exit 1
fi

if [ -z "$SERVER_NAME" ]; then
    echo "Error: Server name is required"
    usage
    exit 1
fi

echo "🚀 Deploying MCP Server..."
echo "   Template: $TEMPLATE_ID"
echo "   Name: $SERVER_NAME"
echo "   Type: $DEPLOYMENT_TYPE"
echo "   Environment: $ENVIRONMENT"
echo ""

# Deploy based on type
case "$DEPLOYMENT_TYPE" in
    "docker")
        echo "📦 Deploying with Docker..."
        
        if [ -n "$CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
            docker run -d \
                --name "$SERVER_NAME" \
                --restart unless-stopped \
                -v "$CONFIG_FILE":/app/config.json:ro \
                -p 3000:3000 \
                "mcp-platform/$TEMPLATE_ID:latest"
        else
            docker run -d \
                --name "$SERVER_NAME" \
                --restart unless-stopped \
                -p 3000:3000 \
                "mcp-platform/$TEMPLATE_ID:latest"
        fi
        
        echo "✅ Server deployed successfully!"
        echo "   Container: $SERVER_NAME"
        echo "   Port: 3000"
        ;;
        
    "kubernetes")
        echo "☸️  Deploying with Kubernetes..."
        
        # Generate Kubernetes manifests
        TEMP_DIR=$(mktemp -d)
        
        # Create deployment manifest
        cat > "$TEMP_DIR/deployment.yaml" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $SERVER_NAME
  labels:
    app: $SERVER_NAME
    template: $TEMPLATE_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $SERVER_NAME
  template:
    metadata:
      labels:
        app: $SERVER_NAME
        template: $TEMPLATE_ID
    spec:
      containers:
      - name: mcp-server
        image: mcp-platform/$TEMPLATE_ID:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "$ENVIRONMENT"
EOF

        # Create service manifest
        cat > "$TEMP_DIR/service.yaml" << EOF
apiVersion: v1
kind: Service
metadata:
  name: $SERVER_NAME-service
spec:
  selector:
    app: $SERVER_NAME
  ports:
  - port: 80
    targetPort: 3000
  type: ClusterIP
EOF

        # Apply manifests
        kubectl apply -f "$TEMP_DIR/deployment.yaml"
        kubectl apply -f "$TEMP_DIR/service.yaml"
        
        # Clean up
        rm -rf "$TEMP_DIR"
        
        echo "✅ Server deployed successfully!"
        echo "   Deployment: $SERVER_NAME"
        echo "   Service: $SERVER_NAME-service"
        ;;
        
    *)
        echo "Error: Unknown deployment type: $DEPLOYMENT_TYPE"
        exit 1
        ;;
esac

echo ""
echo "🎉 Deployment complete!"
