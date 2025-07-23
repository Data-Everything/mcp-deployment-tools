# MCP Deployment Tools

Open source deployment utilities for self-hosting Model Context Protocol (MCP) servers.

## 🚀 What's Included

- **Docker Compose** - Quick local development setup
- **Kubernetes** - Production-ready manifests  
- **Scripts** - Server deployment and management tools
- **Documentation** - Self-hosting guides

## 📋 Quick Start

### Option 1: Docker Deployment (Recommended)

```bash
# Clone this repo
git clone https://github.com/Data-Everything/mcp-deployment-tools.git
cd mcp-deployment-tools

# Setup infrastructure
./scripts/setup-infrastructure.sh --type docker

# Deploy an MCP server
./scripts/deploy.sh --type docker --template file-server --name my-files

# Manage servers
./scripts/manage-servers.sh list
./scripts/manage-servers.sh status --name my-files
```

### Option 2: Kubernetes (Production)

```bash
# Setup Kubernetes infrastructure
./scripts/setup-infrastructure.sh --type kubernetes --namespace mcp-platform

# Deploy an MCP server
./scripts/deploy.sh --type kubernetes --template database --name db-server

# Manage servers
./scripts/manage-servers.sh list --type kubernetes
./scripts/manage-servers.sh logs --name db-server --type kubernetes --follow
```

### Option 3: Docker Compose (Development)

```bash
# Use pre-configured docker-compose
cd docker
docker-compose up -d
## 📁 Repository Structure

```
mcp-deployment-tools/
├── scripts/                    # Deployment and management scripts
│   ├── deploy.sh              # Deploy MCP servers
│   ├── manage-servers.sh      # Start, stop, restart, logs
│   └── setup-infrastructure.sh # Infrastructure setup
├── docker/                    # Docker Compose configurations
│   └── docker-compose.yml     # Quick development setup
├── kubernetes/                # Kubernetes manifests
│   ├── deployment.yaml        # Server deployment template
│   ├── service.yaml          # Service configurations
│   └── ingress.yaml          # Ingress setup
└── docs/                     # Documentation
    └── self-hosting.md       # Self-hosting guide
```

## �️ Scripts Reference

### Infrastructure Setup
```bash
# Docker environment
./scripts/setup-infrastructure.sh --type docker

# Kubernetes environment with custom namespace
./scripts/setup-infrastructure.sh --type kubernetes --namespace my-mcp
```

### Server Deployment
```bash
# Deploy with configuration file
./scripts/deploy.sh --type docker --template file-server --name my-files --config config.json

# Deploy to Kubernetes
./scripts/deploy.sh --type kubernetes --template github --name github-server
```

### Server Management
```bash
# List all servers
./scripts/manage-servers.sh list

# Check server status
./scripts/manage-servers.sh status --name my-files

# View logs (follow mode)
./scripts/manage-servers.sh logs --name my-files --follow

# Restart server
./scripts/manage-servers.sh restart --name my-files
```

```
mcp-deployment-tools/
├── docker/
│   └── docker-compose.yml     # Local development stack
├── kubernetes/
│   ├── deployment.yaml        # K8s deployment
│   ├── ingress.yaml          # Ingress configuration
│   └── secrets.yaml          # Secret templates
├── scripts/
│   ├── setup.sh              # Environment setup
│   ├── deploy.sh             # Deployment script
│   └── dev.sh                # Development helpers
└── docs/
    └── self-hosting.md        # Detailed guides
```

## 🛠️ Use Cases

### Self-Hosting Individual Servers
- Deploy specific MCP servers (GitHub, Slack, etc.)
- Full control over your infrastructure
- No vendor dependencies

### Development Environment
- Local testing of MCP integrations
- Template development and debugging
- AI assistant integration testing

### Production Deployment
- Kubernetes-ready manifests
- Security best practices included
- Monitoring and logging setup

## 🔗 Related Projects

- **[MCP Server Templates](https://github.com/Data-Everything/mcp-server-templates)** - Open source MCP server implementations
- **[MCP Platform](https://mcp-platform.dataeverything.ai)** - Managed hosting with enterprise features
- **[MCP Protocol](https://spec.modelcontextprotocol.io/)** - Official specification

## 💡 Why Self-Host vs. Managed Platform?

**Self-Hosting (This Repo):**
- ✅ Full control and customization
- ✅ No vendor lock-in
- ✅ Use your own infrastructure
- ❌ You manage security, updates, monitoring
- ❌ Setup and maintenance overhead

**[MCP Platform](https://mcp-platform.dataeverything.ai) (Managed):**
- ✅ Zero infrastructure management
- ✅ Enterprise security and compliance
- ✅ Team collaboration features
- ✅ Professional support
- ❌ Monthly subscription cost

Choose based on your needs: self-host for maximum control, use the platform for convenience and enterprise features.

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](./CONTRIBUTING.md).

## 📄 License

MIT License - see [LICENSE](./LICENSE) file for details.

## 📞 Support

- **Community Support**: [GitHub Issues](https://github.com/Data-Everything/mcp-deployment-tools/issues)
- **Documentation**: [Self-Hosting Guide](./docs/self-hosting.md)
- **Enterprise Support**: Available through [MCP Platform](https://mcp-platform.dataeverything.ai)
