#!/bin/bash

# MCP Platform Development Setup Script

set -e

# Change to project root directory
cd "$(dirname "$0")/.."

echo "🚀 Setting up MCP Platform development environment..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not available. Please install Docker Compose first."
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "✅ .env file created. Please review and update the configuration."
fi

# Set up Python virtual environment for local development
echo "🐍 Setting up Python virtual environment..."
cd backend
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

echo "📦 Installing Python dependencies..."
source venv/bin/activate
pip install --upgrade pip > /dev/null 2>&1
pip install -r requirements.txt > /dev/null 2>&1
pip install -r requirements_dev.txt > /dev/null 2>&1
echo "✅ Python dependencies installed"
cd ..

# Build and start infrastructure services for full Docker setup
echo "🏗️  Building and starting Docker services..."
docker compose build
docker compose up -d db redis

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 10

# Get the dynamically assigned ports (if using dynamic ports)
if docker compose port db 5432 > /dev/null 2>&1; then
    DB_PORT=$(docker compose port db 5432 | cut -d: -f2)
    REDIS_PORT=$(docker compose port redis 6379 | cut -d: -f2)
else
    # Use default ports for full Docker setup
    DB_PORT=5432
    REDIS_PORT=6379
fi

echo "📋 Service ports:"
echo "   PostgreSQL: localhost:$DB_PORT"
echo "   Redis: localhost:$REDIS_PORT"

# Run Django commands inside Docker containers
echo "🔄 Running Django migrations..."
docker compose run --rm backend python manage.py migrate

# Create superuser if it doesn't exist
echo "👤 Creating Django superuser..."
docker compose run --rm backend python manage.py shell -c "
from authentication.models import User
import os
from django.core.management.utils import get_random_secret_key

# Create superuser with secure password
if not User.objects.filter(username='admin').exists():
    admin_password = os.environ.get('ADMIN_PASSWORD', get_random_secret_key()[:16])
    User.objects.create_superuser('admin', 'admin@example.com', admin_password)
    print(f'Superuser created: admin/{admin_password}')
    print('⚠️  IMPORTANT: Save this admin password securely!')
else:
    print('Superuser already exists')

# Create demo user for frontend testing
if not User.objects.filter(username='demo').exists():
    User.objects.create_user('demo', 'demo@example.com', 'demo123', first_name='Demo', last_name='User')
    print('Demo user created: demo/demo123')
else:
    print('Demo user already exists')
"

# Load MCP server templates
echo "📦 Loading MCP server templates..."
docker compose run --rm backend python manage.py load_templates templates/

# Install frontend dependencies
echo "📦 Installing frontend dependencies..."
cd frontend && npm install && cd ..

echo "✅ Setup complete!"
echo ""
echo "🎉 MCP Platform is ready!"
echo ""
echo "Your **FULL DOCKER ENVIRONMENT** is now set up with:"
echo "✅ PostgreSQL database (postgres_data volume)"
echo "✅ Redis cache (redis_data volume)"
echo "✅ Database migrated with admin and demo users created"
echo "✅ MCP server templates loaded"
echo ""
echo "🔑 User Accounts:"
echo "   Demo User: demo/demo123 (for frontend testing)"
echo "   Admin User: Check terminal output above for secure password"
echo ""
echo "🚀 Choose your development mode:"
echo ""
echo "🐳 FULL DOCKER (Current Setup):"
echo "   docker compose up --build"
echo "   → Everything runs in containers"
echo "   → Uses postgres_data volume"
echo "   → Good for production-like testing"
echo ""
echo "🔧 HYBRID DEVELOPMENT (Alternative):"
echo "   scripts/dev.sh start    # Uses postgres_dev_data volume"
echo "   → Infrastructure in Docker, code runs locally"
echo "   → Better for development and debugging"
echo ""
echo "📋 Management Commands:"
echo "   scripts/dev.sh start    # Start hybrid development environment"
echo "   scripts/dev.sh stop     # Stop services"
echo "   scripts/dev.sh logs     # View service logs"
echo ""
echo "Access the application:"
echo "   - Frontend: http://localhost:3000"
echo "   - Backend API: http://localhost:8000"
echo "   - Django Admin: http://localhost:8000/admin"
echo "   - Database: localhost:$DB_PORT"
echo "   - Redis: localhost:$REDIS_PORT"
echo ""
echo "Happy coding! 🚀"
