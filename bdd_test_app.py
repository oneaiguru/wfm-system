"""
Standalone BDD Test Application
Runs the BDD System Integration endpoints for testing
"""

from fastapi import FastAPI
from src.api.v1.endpoints.bdd_system_integration import router as integration_router
from src.api.v1.endpoints.bdd_personnel_management import router as personnel_router

app = FastAPI(
    title="BDD System Integration API",
    version="1.0.0",
    description="BDD-compliant API implementation based on multiple BDD feature files"
)

# Include the BDD routers
app.include_router(integration_router, prefix="/api/v1")
app.include_router(personnel_router, prefix="/api/v1")

# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "BDD System Integration API"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)