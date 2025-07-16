"""
Working WFM Enterprise API for Testing
Minimal FastAPI app that actually starts without import errors
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Simple imports that work
from src.api.v1.router_working import api_router

app = FastAPI(
    title="WFM Enterprise Demo API - Working Version",
    version="1.0.0-demo",
    description="""
    WFM Enterprise Demo API - Working Version for BDD Testing
    
    Features:
    - Simple authentication
    - Basic employee management  
    - **VACATION REQUEST SYSTEM** (CORE BDD SCENARIO)
    - Demo endpoints
    
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
        "message": "WFM Enterprise Demo API - Working Version",
        "status": "running",
        "docs": "/docs",
        "vacation_request_system": "ACTIVE",
        "bdd_scenario_ready": True,
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
        "api_endpoints": 8,
        "demo_mode": True,
        "vacation_request_system": "ready",
        "core_bdd_scenario": "operational"
    }