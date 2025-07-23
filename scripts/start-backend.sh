#!/bin/bash

# Helper script to start Django backend with correct environment variables

# Change to backend directory
cd "$(dirname "$0")/../backend"

if [ ! -f .env ]; then
    echo "❌ .env file not found. Please run './scripts/dev.sh start' first."
    exit 1
fi

# Load environment variables from .env file
export $(cat .env | grep -v '^#' | xargs)

echo "🐍 Starting Django backend with:"
echo "   DATABASE_URL: $DATABASE_URL"
echo "   REDIS_URL: $REDIS_URL"
echo ""

# Activate virtual environment and start Django
source venv/bin/activate
python manage.py runserver
