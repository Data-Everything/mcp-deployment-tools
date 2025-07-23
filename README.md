# MCP Deployment Tools

Open source deployment utilities for self-hosting Model Context Protocol (MCP) servers.

## 🚀 What's Included

- **Docker Compose** - Quick local development setup
- **Kubernetes** - Production-ready manifests  
- **Scripts** - Deployment automation tools
- **Documentation** - Self-hosting guides

## 📋 Quick Start

### Option 1: Docker Compose (Recommended for Development)

```bash
# Clone this repo
git clone https://github.com/Data-Everything/mcp-deployment-tools.git
cd mcp-deployment-tools

# Get MCP server templates
git clone https://github.com/Data-Everything/mcp-server-templates.git templates

# Start services
cd docker
docker-compose up -d
```

### Option 2: Kubernetes (Production)

```bash
# Apply Kubernetes manifests
kubectl apply -f kubernetes/

# Check deployment status
kubectl get pods -l app=mcp-server
```

### Option 3: Manual Scripts

```bash
# Run setup script
./scripts/setup.sh

# Deploy servers
./scripts/deploy.sh
```

## 📁 Repository Structure

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
