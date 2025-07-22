#!/bin/bash

# Development script for MCP Platform

set -e

# Change to project root directory
cd "$(dirname "$0")/.."

case "$1" in
    "start")
        echo "🚀 Starting MCP Platform development environment..."
        echo "📦 Starting infrastructure services (PostgreSQL, Redis)..."
        docker compose -f docker-compose.dev.yml up -d

        echo "⏳ Waiting for database to be ready..."
        sleep 5

        # Get the dynamically assigned ports
        DB_PORT=$(docker compose -f docker-compose.dev.yml port db 5432 | cut -d: -f2)
        REDIS_PORT=$(docker compose -f docker-compose.dev.yml port redis 6379 | cut -d: -f2)

        echo "🌐 Service ports:"
        echo "   PostgreSQL: localhost:$DB_PORT"
        echo "   Redis: localhost:$REDIS_PORT"

        echo "🔧 Setting up database..."
        cd backend
        if [ ! -d "venv" ]; then
            echo "❌ Virtual environment not found. Please run ./setup.sh first."
            exit 1
        fi

        echo "📦 Installing/updating development dependencies..."
        source venv/bin/activate
        pip install -r requirements_dev.txt > /dev/null 2>&1

        export DATABASE_URL="postgresql://mcp_user:mcp_password@localhost:$DB_PORT/mcp_platform"
        export REDIS_URL="redis://localhost:$REDIS_PORT/0"
        python manage.py migrate

        echo "� Creating demo users..."
        python manage.py create_demo_users

        echo "�📊 Loading MCP server templates..."
        if [ -d "../templates/" ]; then
            python manage.py load_templates ../templates/
        else
            echo "⚠️  Templates directory not found, skipping template loading"
        fi

        # Create .env file with dynamic ports for development
        echo "📝 Creating .env file with dynamic ports..."
        cat > .env << EOF
DATABASE_URL=postgresql://mcp_user:mcp_password@localhost:$DB_PORT/mcp_platform
REDIS_URL=redis://localhost:$REDIS_PORT/0
DJANGO_DEBUG=True
DJANGO_SECRET_KEY=dev-secret-key-change-in-production
EOF

        echo ""
        echo "✅ Development environment is ready!"
        echo ""
        echo "🔑 Login Credentials:"
        echo "   Demo User: demo/demo123 (use this for frontend testing)"
        echo ""
        echo "🎯 Next steps:"
        echo "1. Start Django backend:"
        echo "   scripts/start-backend.sh"
        echo ""
        echo "2. Start Next.js frontend (new terminal):"
        echo "   cd frontend && npm run dev"
        echo ""
        echo "3. Access the application:"
        echo "   - Frontend: http://localhost:3000"
        echo "   - Backend API: http://localhost:8000"
        echo "   - Django Admin: http://localhost:8000/admin (admin access only)"
        ;;

    "stop")
        echo "🛑 Stopping MCP Platform development environment..."
        docker compose -f docker-compose.dev.yml down
        echo "✅ Development environment stopped!"
        ;;

    "restart")
        echo "🔄 Restarting MCP Platform development environment..."
        docker compose -f docker-compose.dev.yml restart
        echo "✅ Development environment restarted!"
        ;;

    "logs")
        echo "📋 Showing infrastructure logs..."
        docker compose -f docker-compose.dev.yml logs -f
        ;;

    "clean")
        echo "🧹 Cleaning up development environment..."
        docker compose -f docker-compose.dev.yml down -v
        echo "✅ Development environment cleaned!"
        ;;

    *)
        echo "MCP Platform Development Helper"
        echo ""
        echo "Usage: $0 {start|stop|restart|logs|clean}"
        echo ""
        echo "Commands:"
        echo "  start   - Start infrastructure services and setup database"
        echo "  stop    - Stop all infrastructure services"
        echo "  restart - Restart infrastructure services"
        echo "  logs    - Show infrastructure service logs"
        echo "  clean   - Stop services and remove volumes (clean slate)"
        echo ""
        echo "After running 'start', manually run:"
        echo "  Backend:  scripts/start-backend.sh"
        echo "  Frontend: cd frontend && npm run dev"
        ;;
esac
