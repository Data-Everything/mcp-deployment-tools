#!/bin/bash

# Update environment files with dynamic Docker ports
# This script detects the actual ports assigned to PostgreSQL and Redis containers
# and updates the .env files accordingly

set -e

echo "🔍 Detecting Docker container ports..."

# Get PostgreSQL port
POSTGRES_PORT=$(docker port host-mcp-db-1 5432 2>/dev/null | cut -d: -f2)
if [ -z "$POSTGRES_PORT" ]; then
    echo "❌ PostgreSQL container not found or not running"
    echo "💡 Start the development environment first: docker-compose -f docker-compose.dev.yml up -d"
    exit 1
fi

# Get Redis port
REDIS_PORT=$(docker port host-mcp-redis-1 6379 2>/dev/null | cut -d: -f2)
if [ -z "$REDIS_PORT" ]; then
    echo "❌ Redis container not found or not running"
    echo "💡 Start the development environment first: docker-compose -f docker-compose.dev.yml up -d"
    exit 1
fi

echo "📍 Found PostgreSQL on port: $POSTGRES_PORT"
echo "📍 Found Redis on port: $REDIS_PORT"

# Update .env.dev file
echo "📝 Updating .env.dev..."
sed -i "s|DATABASE_URL=postgresql://mcp_user:mcp_password@localhost:[0-9]*/mcp_platform|DATABASE_URL=postgresql://mcp_user:mcp_password@localhost:$POSTGRES_PORT/mcp_platform|g" .env.dev
sed -i "s|DB_PORT=[0-9]*|DB_PORT=$POSTGRES_PORT|g" .env.dev

# Update backend/.env file
echo "📝 Updating backend/.env..."
sed -i "s|DATABASE_URL=postgresql://mcp_user:mcp_password@localhost:[0-9]*/mcp_platform|DATABASE_URL=postgresql://mcp_user:mcp_password@localhost:$POSTGRES_PORT/mcp_platform|g" backend/.env
sed -i "s|REDIS_URL=redis://localhost:[0-9]*/0|REDIS_URL=redis://localhost:$REDIS_PORT/0|g" backend/.env

echo "✅ Environment files updated successfully!"
echo ""
echo "🚀 You can now run Django management commands:"
echo "   cd backend && source venv/bin/activate && DATABASE_URL=\"postgresql://mcp_user:mcp_password@localhost:$POSTGRES_PORT/mcp_platform\" python manage.py migrate"
echo "   cd backend && source venv/bin/activate && DATABASE_URL=\"postgresql://mcp_user:mcp_password@localhost:$POSTGRES_PORT/mcp_platform\" python manage.py load_templates ../templates/"
echo ""
echo "💡 Or use the development script:"
echo "   ./scripts/dev.sh migrate"
echo "   ./scripts/dev.sh load_templates"
echo ""
