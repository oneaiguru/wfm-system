"""
Main Forecasting & Planning API Router
Combines all forecasting endpoints into a single router
"""

from fastapi import APIRouter

from .forecasts import router as forecasts_router
from .operations import router as operations_router
from .planning import router as planning_router
from .ml_integration import router as ml_router
from .scenarios import router as scenarios_router

# Create main forecasting router
router = APIRouter(prefix="/api/v1", tags=["forecasting"])

# Include all forecasting sub-routers
router.include_router(forecasts_router, prefix="", tags=["forecast-management"])
router.include_router(operations_router, prefix="", tags=["forecast-operations"])
router.include_router(planning_router, prefix="", tags=["planning-calculations"])
router.include_router(ml_router, prefix="", tags=["ml-integration"])
router.include_router(scenarios_router, prefix="", tags=["what-if-analysis"])

# Health check endpoint
@router.get("/forecasting/health")
async def forecasting_health_check():
    """Health check for forecasting API."""
    return {
        "status": "healthy",
        "service": "forecasting_api",
        "version": "1.0.0",
        "endpoints": {
            "forecast_management": 5,
            "forecast_operations": 7,
            "planning_calculations": 6,
            "ml_integration": 4,
            "what_if_analysis": 3,
            "total_endpoints": 25
        }
    }

# API documentation summary
@router.get("/forecasting/endpoints")
async def list_forecasting_endpoints():
    """List all available forecasting endpoints."""
    return {
        "forecast_management": {
            "description": "CRUD operations for forecasts",
            "endpoints": [
                "POST /api/v1/forecasts",
                "GET /api/v1/forecasts",
                "GET /api/v1/forecasts/{id}",
                "PUT /api/v1/forecasts/{id}",
                "DELETE /api/v1/forecasts/{id}"
            ]
        },
        "forecast_operations": {
            "description": "Forecast generation and operations",
            "endpoints": [
                "POST /api/v1/forecasts/generate",
                "POST /api/v1/forecasts/import",
                "POST /api/v1/forecasts/import/file",
                "POST /api/v1/forecasts/growth-factor",
                "POST /api/v1/forecasts/seasonal-adjustment",
                "POST /api/v1/forecasts/accuracy",
                "POST /api/v1/forecasts/compare",
                "POST /api/v1/forecasts/export"
            ]
        },
        "planning_calculations": {
            "description": "Staffing and planning calculations",
            "endpoints": [
                "POST /api/v1/planning/calculate-staffing",
                "POST /api/v1/planning/erlang-c",
                "POST /api/v1/planning/multi-skill",
                "POST /api/v1/planning/scenarios",
                "GET /api/v1/planning/recommendations",
                "POST /api/v1/planning/validate"
            ]
        },
        "ml_integration": {
            "description": "Machine learning model integration",
            "endpoints": [
                "POST /api/v1/ml/forecast/train",
                "GET /api/v1/ml/forecast/models",
                "POST /api/v1/ml/forecast/predict",
                "GET /api/v1/ml/forecast/performance"
            ]
        },
        "what_if_analysis": {
            "description": "Scenario analysis and what-if modeling",
            "endpoints": [
                "POST /api/v1/scenarios/create",
                "POST /api/v1/scenarios/compare",
                "GET /api/v1/scenarios/results"
            ]
        }
    }