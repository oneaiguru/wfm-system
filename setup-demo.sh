#!/bin/bash

# WFM Enterprise Demo Setup Script
# This script sets up the minimum requirements for a working demo

echo "🚀 WFM Enterprise Demo Setup"
echo "============================"

# Check Python version
echo "📌 Checking Python version..."
python3 --version

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install Python dependencies
echo "📚 Installing Python dependencies..."
pip install -r requirements.txt

# Create PostgreSQL database
echo "🗄️  Setting up PostgreSQL database..."
createdb wfm_enterprise 2>/dev/null || echo "Database already exists"

# Create .env file with demo configuration
echo "⚙️  Creating configuration file..."
cat > .env << EOF
# Database
DATABASE_URL=postgresql://postgres:@localhost/wfm_enterprise
POSTGRES_SERVER=localhost
POSTGRES_USER=postgres
POSTGRES_PASSWORD=
POSTGRES_DB=wfm_enterprise

# Redis
REDIS_URL=redis://localhost:6379/0

# Security
SECRET_KEY=demo-secret-key-for-wfm-enterprise-2024
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# CORS
BACKEND_CORS_ORIGINS=["http://localhost:3000","http://localhost:5173","http://localhost:8000"]

# API Configuration
PROJECT_NAME=WFM Enterprise Demo
VERSION=1.0.0
API_V1_STR=/api/v1

# Demo Mode
DEMO_MODE=true
LOG_LEVEL=INFO
EOF

echo "✅ Configuration file created"

# Check if Redis is installed
if ! command -v redis-cli &> /dev/null; then
    echo "⚠️  Redis not found. Please install Redis:"
    echo "   brew install redis"
    echo "   brew services start redis"
else
    echo "✅ Redis found"
fi

# Check if PostgreSQL is running
if ! pg_isready -q; then
    echo "⚠️  PostgreSQL is not running. Please start it:"
    echo "   brew services start postgresql"
else
    echo "✅ PostgreSQL is running"
fi

echo ""
echo "🎯 Next Steps:"
echo "1. Fix import paths: ./fix-imports.sh"
echo "2. Create database schema: python create_schema.py"
echo "3. Load demo data: python create_demo_data.py"
echo "4. Start API server: uvicorn src.api.main:app --reload"
echo "5. Start UI: npm install && npm run dev"

echo ""
echo "📝 Demo Checklist:"
echo "[ ] PostgreSQL running"
echo "[ ] Redis running"
echo "[ ] Python dependencies installed"
echo "[ ] .env file created"
echo "[ ] Import paths fixed"
echo "[ ] Database schema created"
echo "[ ] Demo data loaded"
echo "[ ] API server running on :8000"
echo "[ ] UI running on :5173"

echo ""
echo "✨ Setup script complete!"