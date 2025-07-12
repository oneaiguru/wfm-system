"""
Standalone BDD Test Application
Runs the BDD System Integration endpoints for testing
"""

from fastapi import FastAPI
from src.api.v1.endpoints.bdd_system_integration import router

app = FastAPI(
    title="BDD System Integration API",
    version="1.0.0",
    description="BDD-compliant API implementation based on 11-system-integration-api-management.feature"
)

# Include the BDD integration router
app.include_router(router, prefix="/api/v1")

# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "BDD System Integration API"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)