#!/bin/bash

# Test runner script for MCP Platform

set -e

# Change to project root directory
cd "$(dirname "$0")/.."

case "${1:-local}" in
    "local")
        echo "🧪 Running MCP Platform tests locally..."

        # Change to backend directory
        cd backend

        # Check if virtual environment exists
        if [ ! -d "venv" ]; then
            echo "❌ Virtual environment not found. Please run './scripts/setup.sh' first."
            exit 1
        fi

        # Activate virtual environment
        source venv/bin/activate

        # Ensure development dependencies are installed
        echo "📦 Ensuring test dependencies are installed..."
        pip install -r requirements_dev.txt > /dev/null 2>&1

        # Set up test database URL (using environment variables if available)
        if [ -f ".env" ]; then
            # Load environment variables but override for testing
            export $(cat .env | grep -v '^#' | xargs)
        fi

        # Use test database (separate from development database)
        export DJANGO_SETTINGS_MODULE="mcp_platform.test_settings"

        # Run tests with coverage
        echo "🚀 Running pytest with coverage..."
        pytest "${@:2}"

        echo "✅ Tests completed!"
        echo ""
        echo "📊 Coverage report generated in htmlcov/ directory"
        echo "   Open htmlcov/index.html in your browser to view detailed coverage"
        ;;

    "docker")
        echo "🐳 Running MCP Platform tests in Docker..."

        # Stop any existing test containers
        docker compose -f docker-compose.test.yml down > /dev/null 2>&1 || true

        # Build and run tests
        echo "🏗️  Building test environment..."
        docker compose -f docker-compose.test.yml build test-backend

        echo "🚀 Running tests..."
        docker compose -f docker-compose.test.yml run --rm test-backend pytest "${@:2}"

        # Clean up
        echo "🧹 Cleaning up test environment..."
        docker compose -f docker-compose.test.yml down

        echo "✅ Docker tests completed!"
        ;;

    "ci")
        echo "🔄 Running MCP Platform tests for CI/CD..."

        # Similar to docker but with CI-specific settings
        docker compose -f docker-compose.test.yml down > /dev/null 2>&1 || true
        docker compose -f docker-compose.test.yml build test-backend
        docker compose -f docker-compose.test.yml run --rm test-backend pytest --tb=short --cov=. --cov-report=xml --cov-report=term "${@:2}"
        docker compose -f docker-compose.test.yml down

        echo "✅ CI tests completed!"
        ;;

    *)
        echo "Usage: $0 [local|docker|ci] [pytest-args...]"
        echo ""
        echo "Test modes:"
        echo "  local  - Run tests in local virtual environment (default)"
        echo "  docker - Run tests in isolated Docker containers"
        echo "  ci     - Run tests for CI/CD with XML coverage output"
        echo ""
        echo "Examples:"
        echo "  $0                                    # Run all tests locally"
        echo "  $0 local -k test_user                # Run specific test locally"
        echo "  $0 docker                            # Run all tests in Docker"
        echo "  $0 docker -x --lf                    # Run failed tests in Docker"
        echo "  $0 ci                                 # Run tests for CI/CD"
        exit 1
        ;;
esac
