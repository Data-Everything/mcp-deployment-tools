# MCP Platform Deployment System

This document describes the Kubernetes-based deployment system for MCP (Model Context Protocol) server templates.

## Overview

The MCP Platform can deploy server templates to multiple backends:

- **Kubernetes** - Production-ready container orchestration
- **Docker** - Simple container deployment for development
- **Mock** - Simulated deployment for testing

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Django API     │    │  Deployment     │
│   (React)       │───▶│   (Backend)      │───▶│  Backend        │
│                 │    │                  │    │  (K8s/Docker)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │  Template Repo   │
                       │  (GitHub)        │
                       └──────────────────┘
```

## Components

### 1. Deployment Manager (`deployment/manager.py`)

Central orchestrator that:
- Validates template configurations
- Routes deployments to appropriate backends
- Provides unified API for deployment operations

### 2. Kubernetes Service (`deployment/kubernetes_service.py`)

Production deployment backend that:
- Creates Kubernetes Deployments, Services, ConfigMaps
- Manages namespaces and RBAC
- Provides health checks and monitoring
- Supports ingress for external access

### 3. Docker Service (`deployment/docker_service.py`)

Development deployment backend that:
- Runs containers with Docker Engine
- Creates isolated networks
- Maps ports for local access
- Simpler setup for local development

### 4. Mock Service (`deployment/manager.py`)

Testing backend that:
- Simulates deployments without real containers
- Useful for CI/CD and unit testing
- No external dependencies

## Configuration

### Environment Variables

```bash
# Deployment backend selection
MCP_DEPLOYMENT_BACKEND=kubernetes  # kubernetes, docker, or mock

# Kubernetes configuration
MCP_NAMESPACE=mcp-servers
MCP_IMAGE_REGISTRY=ghcr.io/data-everything
MCP_INGRESS_HOST=mcp.example.com

# Authentication (for in-cluster or external access)
KUBERNETES_SERVICE_ACCOUNT_TOKEN=<token>
KUBERNETES_CLUSTER_ENDPOINT=https://cluster.example.com
```

### Django Settings

Add to `settings.py`:

```python
# MCP Deployment Configuration
MCP_DEPLOYMENT_BACKEND = env_config("MCP_DEPLOYMENT_BACKEND", default="mock")
MCP_NAMESPACE = env_config("MCP_NAMESPACE", default="mcp-servers")
MCP_IMAGE_REGISTRY = env_config("MCP_IMAGE_REGISTRY", default="ghcr.io/data-everything")
MCP_INGRESS_HOST = env_config("MCP_INGRESS_HOST", default="")
```

## API Endpoints

### Deploy Template
```http
POST /api/templates/deploy/{template_id}/
Content-Type: application/json

{
  "configuration": {
    "key": "value"
  }
}
```

### List Deployments
```http
GET /api/templates/deployments/
```

### Get Deployment Status
```http
GET /api/templates/deployments/{deployment_name}/
```

### Delete Deployment
```http
DELETE /api/templates/deployments/{deployment_name}/delete/
```

## Setup Instructions

### Prerequisites

1. **Python Dependencies**
```bash
pip install kubernetes docker PyYAML
```

2. **Docker** (for Docker backend)
```bash
# Install Docker Engine
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

3. **Kubernetes** (for Kubernetes backend)
```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### Quick Start

1. **Setup Environment**
```bash
# For mock deployment (no setup required)
export MCP_DEPLOYMENT_BACKEND=mock

# For Docker deployment
export MCP_DEPLOYMENT_BACKEND=docker

# For Kubernetes deployment
export MCP_DEPLOYMENT_BACKEND=kubernetes
./scripts/setup-k8s.sh
```

2. **Start Backend**
```bash
cd backend
python manage.py runserver
```

3. **Test Deployment**
```bash
./scripts/test-deployment.sh file-server
```

## Kubernetes Setup

### 1. Automatic Setup
```bash
./scripts/setup-k8s.sh
```

This script will:
- Create the `mcp-servers` namespace
- Set up RBAC permissions
- Create service account tokens
- Display configuration commands

### 2. Manual Setup

Create namespace:
```bash
kubectl create namespace mcp-servers
kubectl label namespace mcp-servers managed-by=mcp-platform
```

Apply RBAC:
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mcp-platform-deployer
  namespace: mcp-servers
---
# Add Role and RoleBinding as shown in setup-k8s.sh
EOF
```

### 3. In-Cluster Deployment

For production deployment inside Kubernetes:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mcp-platform-backend
spec:
  template:
    spec:
      serviceAccountName: mcp-platform-deployer
      containers:
      - name: backend
        image: mcp-platform:latest
        env:
        - name: MCP_DEPLOYMENT_BACKEND
          value: "kubernetes"
        - name: MCP_NAMESPACE
          value: "mcp-servers"
```

## Docker Images

### Building Images

Build all template images:
```bash
./scripts/build-images.sh
```

Build specific template:
```bash
cd /path/to/template
docker build -t ghcr.io/data-everything/mcp-{template}:latest .
```

### Image Requirements

Each template must include:

1. **Dockerfile**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
CMD ["npm", "start"]
```

2. **Health Endpoints**
- `/health` - Liveness probe
- `/ready` - Readiness probe

3. **Environment Configuration**
- Accept configuration via environment variables
- Use `PORT` environment variable for port binding

## Monitoring and Troubleshooting

### View Deployments
```bash
# List all deployments
curl http://localhost:8000/api/templates/deployments/

# Get specific deployment status
curl http://localhost:8000/api/templates/deployments/{deployment_name}/
```

### Kubernetes Debugging
```bash
# View pods
kubectl get pods -n mcp-servers

# Check logs
kubectl logs -n mcp-servers deployment/{deployment_name}

# Describe resources
kubectl describe deployment {deployment_name} -n mcp-servers
```

### Docker Debugging
```bash
# List containers
docker ps --filter label=managed-by=mcp-platform

# Check logs
docker logs {container_name}

# Inspect container
docker inspect {container_name}
```

## Security Considerations

1. **RBAC** - Kubernetes permissions are limited to the MCP namespace
2. **Network Policies** - Consider implementing network segmentation
3. **Image Security** - Scan images for vulnerabilities
4. **Secrets Management** - Use Kubernetes Secrets for sensitive data
5. **Resource Limits** - Configure CPU/memory limits for containers

## Development

### Adding New Backends

1. Create service class implementing the interface:
```python
class CustomDeploymentService:
    def deploy_template(self, template_id, config, template_data):
        # Implementation
        pass
    
    def list_deployments(self):
        # Implementation
        pass
    
    def delete_deployment(self, deployment_name):
        # Implementation
        pass
    
    def get_deployment_status(self, deployment_name):
        # Implementation
        pass
```

2. Register in `deployment/manager.py`:
```python
elif backend_type == 'custom':
    from .custom_service import CustomDeploymentService
    return CustomDeploymentService()
```

### Testing

Run deployment tests:
```bash
# Test with mock backend
python manage.py test deployment.tests

# Integration test with real backend
./scripts/test-deployment.sh
```

## Performance Tuning

### Kubernetes
- Use resource requests and limits
- Configure horizontal pod autoscaling
- Use node affinity for workload placement

### Docker
- Limit container resources with `--memory` and `--cpus`
- Use multi-stage builds for smaller images
- Configure restart policies

### General
- Implement caching for template metadata
- Use connection pooling for database access
- Configure appropriate timeouts

## Scaling

The system supports horizontal scaling:

1. **API Backend** - Multiple Django instances behind load balancer
2. **Deployments** - Kubernetes native scaling capabilities
3. **Storage** - Shared storage for persistent data

## Backup and Recovery

### Kubernetes
- Regular etcd backups
- Persistent volume snapshots
- Configuration backup via GitOps

### Application Data
- Database backups
- Template repository mirroring
- Deployment metadata export
