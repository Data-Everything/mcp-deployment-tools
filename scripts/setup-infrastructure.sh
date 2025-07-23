#!/bin/bash

# MCP Platform Infrastructure Setup Script
# Sets up the infrastructure needed for MCP server deployments

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
SETUP_TYPE="docker"
REGISTRY_URL=""
NAMESPACE="mcp-platform"

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --type TYPE         Setup type: docker, kubernetes (default: docker)"
    echo "  -r, --registry URL      Container registry URL"
    echo "  -n, --namespace NAME    Kubernetes namespace (default: mcp-platform)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --type docker"
    echo "  $0 --type kubernetes --namespace my-mcp --registry my-registry.com"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            SETUP_TYPE="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY_URL="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
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

echo "🛠️  Setting up MCP Platform infrastructure..."
echo "   Type: $SETUP_TYPE"
echo "   Namespace: $NAMESPACE"
echo ""

case "$SETUP_TYPE" in
    "docker")
        echo "📦 Setting up Docker environment..."
        
        # Create Docker network for MCP servers
        if ! docker network ls | grep -q mcp-network; then
            docker network create mcp-network
            echo "✅ Created Docker network: mcp-network"
        else
            echo "ℹ️  Docker network already exists: mcp-network"
        fi
        
        # Pull base images if registry is specified
        if [ -n "$REGISTRY_URL" ]; then
            echo "📥 Pulling base images from registry..."
            docker pull "$REGISTRY_URL/mcp-platform/base:latest" || echo "⚠️  Base image not found in registry"
        fi
        
        echo "✅ Docker environment ready!"
        ;;
        
    "kubernetes")
        echo "☸️  Setting up Kubernetes environment..."
        
        # Create namespace
        if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
            kubectl create namespace "$NAMESPACE"
            echo "✅ Created namespace: $NAMESPACE"
        else
            echo "ℹ️  Namespace already exists: $NAMESPACE"
        fi
        
        # Set up RBAC
        cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mcp-server-sa
  namespace: $NAMESPACE
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: mcp-server-role
  namespace: $NAMESPACE
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: mcp-server-binding
  namespace: $NAMESPACE
subjects:
- kind: ServiceAccount
  name: mcp-server-sa
  namespace: $NAMESPACE
roleRef:
  kind: Role
  name: mcp-server-role
  apiGroup: rbac.authorization.k8s.io
EOF
        
        echo "✅ RBAC configured"
        
        # Set up registry secret if provided
        if [ -n "$REGISTRY_URL" ]; then
            echo "🔐 Setting up registry access..."
            echo "Please provide registry credentials when prompted"
            kubectl create secret docker-registry mcp-registry-secret \
                --docker-server="$REGISTRY_URL" \
                --docker-username="$REGISTRY_USERNAME" \
                --docker-password="$REGISTRY_PASSWORD" \
                --namespace="$NAMESPACE" \
                --dry-run=client -o yaml | kubectl apply -f - || echo "⚠️  Registry secret setup skipped"
        fi
        
        echo "✅ Kubernetes environment ready!"
        ;;
        
    *)
        echo "Error: Unknown setup type: $SETUP_TYPE"
        exit 1
        ;;
esac

echo ""
echo "🎉 Infrastructure setup complete!"
echo ""
echo "Next steps:"
case "$SETUP_TYPE" in
    "docker")
        echo "  1. Deploy MCP servers using: ./deploy.sh --type docker --template <template-id> --name <server-name>"
        echo "  2. Monitor servers with: docker ps"
        echo "  3. View logs with: docker logs <server-name>"
        ;;
    "kubernetes")
        echo "  1. Deploy MCP servers using: ./deploy.sh --type kubernetes --template <template-id> --name <server-name>"
        echo "  2. Monitor deployments with: kubectl get deployments -n $NAMESPACE"
        echo "  3. View logs with: kubectl logs -n $NAMESPACE deployment/<server-name>"
        ;;
esac
