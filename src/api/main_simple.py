"""
Simple WFM Enterprise API for Demo
Minimal FastAPI app to get something running quickly
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Simple imports that work
from src.api.core.config import settings
from src.api.v1.router_simple import api_router

app = FastAPI(
    title="WFM Enterprise Demo API",
    version="1.0.0-demo",
    description="""
    WFM Enterprise Demo API - Minimal version for testing
    
    Features:
    - Simple authentication
    - Basic employee management
    - Demo forecasting
    - Demo scheduling
    
    Demo Credentials:
    - Admin: admin@demo.com / AdminPass123!
    - Manager: manager@demo.com / ManagerPass123!
    """,
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for demo
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API router
app.include_router(api_router, prefix="/api/v1")

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "WFM Enterprise Demo API",
        "status": "running",
        "docs": "/docs",
        "demo_credentials": {
            "admin": "admin@demo.com / AdminPass123!",
            "manager": "manager@demo.com / ManagerPass123!"
        }
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "version": "1.0.0-demo",
        "api_endpoints": 6,
        "demo_mode": True
    }