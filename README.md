# MCP Platform Scripts

This directory contains all management scripts for the MCP Platform project.

## Scripts Overview

### 🚀 `setup.sh`
**Purpose**: Initial project setup for full Docker environment
- Sets up the complete Docker environment with `postgres_data` volume
- Runs database migrations and creates superuser (admin/admin123)
- Loads MCP server templates
- Installs frontend dependencies
- Best for: Initial setup and production-like testing

**Usage**:
```bash
scripts/setup.sh
```

### 🔧 `dev.sh`
**Purpose**: Hybrid development environment management
- Uses `postgres_dev_data` volume (separate from full Docker)
- Infrastructure in Docker, application code runs locally
- Supports dynamic port assignment to avoid conflicts
- Best for: Active development and debugging

**Usage**:
```bash
scripts/dev.sh start     # Start infrastructure services
scripts/dev.sh stop      # Stop all services
scripts/dev.sh restart   # Restart services
scripts/dev.sh logs      # Show service logs
scripts/dev.sh clean     # Clean up (removes volumes)
```

### 🐍 `start-backend.sh`
**Purpose**: Start Django backend with proper environment variables
- Automatically loads `.env` file with dynamic ports
- Activates virtual environment
- Starts Django development server
- Must be run after `scripts/dev.sh start`

**Usage**:
```bash
scripts/start-backend.sh
```

## Development Workflows

### Full Docker Development
```bash
# Initial setup
scripts/setup.sh

# Start everything
docker compose up --build
```

### Hybrid Development (Recommended)
```bash
# Start infrastructure
scripts/dev.sh start

# Start backend (in one terminal)
scripts/start-backend.sh

# Start frontend (in another terminal)
cd frontend && npm run dev
```

## Data Storage

- **Full Docker**: Uses `postgres_data` and `redis_data` volumes
- **Hybrid Development**: Uses `postgres_dev_data` and `redis_dev_data` volumes

This separation allows you to switch between development modes without losing data.
