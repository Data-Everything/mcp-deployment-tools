# Self-Hosting MCP Servers

This guide helps you deploy MCP servers on your own infrastructure using the open source templates and deployment tools.

## Prerequisites

- Docker and Docker Compose
- Basic understanding of MCP (Model Context Protocol)
- Server templates from [mcp-server-templates](https://github.com/Data-Everything/mcp-server-templates)

## Quick Start with Docker Compose

1. Clone this repository:
```bash
git clone https://github.com/Data-Everything/mcp-deployment-tools.git
cd mcp-deployment-tools
```

2. Copy your MCP server templates:
```bash
git clone https://github.com/Data-Everything/mcp-server-templates.git templates
```

3. Start the services:
```bash
cd docker
docker-compose up -d
```

## Kubernetes Deployment

For production deployments, use the Kubernetes manifests:

```bash
kubectl apply -f kubernetes/
```

## Configuration

### Environment Variables

- `DB_PASSWORD`: PostgreSQL password
- `REDIS_URL`: Redis connection string
- `NODE_ENV`: Environment (development/production)

### Server Templates

Place your MCP server configurations in the `templates/` directory. Each template should follow the MCP specification.

## Security Considerations

- Change default passwords
- Use TLS/SSL in production
- Implement proper firewall rules
- Regular security updates

## Monitoring

Basic monitoring is included via:
- Health checks on all services
- PostgreSQL and Redis persistence
- Container restart policies

## Support

For self-hosting support:
- Community forums: [GitHub Discussions](https://github.com/Data-Everything/mcp-deployment-tools/discussions)
- Documentation: [MCP Protocol Docs](https://spec.modelcontextprotocol.io/)

For enterprise support and managed hosting, see [MCP Platform](https://mcp-platform.dataeverything.ai).
