#!/bin/bash

# Setup Kubernetes environment for MCP Platform

set -e

# Configuration
NAMESPACE=${MCP_NAMESPACE:-"mcp-servers"}
KUBECONFIG=${KUBECONFIG:-"$HOME/.kube/config"}

echo "🚀 Setting up Kubernetes environment for MCP Platform"
echo "Namespace: $NAMESPACE"
echo "Kubeconfig: $KUBECONFIG"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if we can connect to Kubernetes cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

echo "✅ Connected to Kubernetes cluster"

# Create namespace if it doesn't exist
if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "✅ Namespace $NAMESPACE already exists"
else
    echo "📦 Creating namespace $NAMESPACE"
    kubectl create namespace "$NAMESPACE"
    kubectl label namespace "$NAMESPACE" managed-by=mcp-platform
    echo "✅ Created namespace $NAMESPACE"
fi

# Create RBAC resources for MCP Platform
echo "🔐 Setting up RBAC for MCP Platform"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mcp-platform-deployer
  namespace: $NAMESPACE
  labels:
    managed-by: mcp-platform
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: mcp-platform-deployer
  namespace: $NAMESPACE
  labels:
    managed-by: mcp-platform
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: mcp-platform-deployer
  namespace: $NAMESPACE
  labels:
    managed-by: mcp-platform
subjects:
- kind: ServiceAccount
  name: mcp-platform-deployer
  namespace: $NAMESPACE
roleRef:
  kind: Role
  name: mcp-platform-deployer
  apiGroup: rbac.authorization.k8s.io
EOF

echo "✅ RBAC resources created"

# Create a secret for the service account token (for external access)
echo "🔑 Creating service account token"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: mcp-platform-deployer-token
  namespace: $NAMESPACE
  labels:
    managed-by: mcp-platform
  annotations:
    kubernetes.io/service-account.name: mcp-platform-deployer
type: kubernetes.io/service-account-token
EOF

echo "✅ Service account token created"

# Wait for token to be generated
echo "⏳ Waiting for token to be generated..."
sleep 5

# Get the token and cluster info
TOKEN=$(kubectl get secret mcp-platform-deployer-token -n "$NAMESPACE" -o jsonpath='{.data.token}' | base64 -d)
CLUSTER_ENDPOINT=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CLUSTER_CA=$(kubectl get secret mcp-platform-deployer-token -n "$NAMESPACE" -o jsonpath='{.data.ca\.crt}')

echo ""
echo "🎉 Kubernetes setup complete!"
echo ""
echo "Environment variables for MCP Platform backend:"
echo "export MCP_DEPLOYMENT_BACKEND=kubernetes"
echo "export MCP_NAMESPACE=$NAMESPACE"
echo "export KUBERNETES_SERVICE_ACCOUNT_TOKEN='$TOKEN'"
echo "export KUBERNETES_CLUSTER_ENDPOINT='$CLUSTER_ENDPOINT'"
echo ""
echo "To test the deployment, you can run:"
echo "  kubectl get all -n $NAMESPACE"
echo ""
echo "To clean up later:"
echo "  kubectl delete namespace $NAMESPACE"
