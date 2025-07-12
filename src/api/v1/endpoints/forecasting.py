from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.core.database import get_db
from src.api.v1.schemas.forecasting import (
    GrowthFactorRequest,
    GrowthFactorResponse,
    ForecastCalculationRequest,
    ForecastCalculationResponse,
    MLForecastRequest,
    MLForecastResponse
)
from src.api.services.forecasting_service import ForecastingService
from src.api.utils.cache import cache_decorator

router = APIRouter()


@router.post("/calculate/growth-factor", response_model=GrowthFactorResponse)
async def calculate_growth_factor(
    request: GrowthFactorRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Apply growth factor to forecast calculations.
    Improvement over Argus manual UI process.
    """
    try:
        service = ForecastingService(db)
        result = await service.apply_growth_factor(request)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@router.post("/calculate/erlang-c", response_model=ForecastCalculationResponse)
@cache_decorator(expire=3600)
async def calculate_erlang_c_forecast(
    request: ForecastCalculationRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Calculate Erlang C based forecasts with enhanced accuracy.
    Target: 90%+ accuracy improvement over Argus.
    """
    try:
        service = ForecastingService(db)
        result = await service.calculate_erlang_c_forecast(request)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@router.post("/ml-enhanced", response_model=MLForecastResponse)
@cache_decorator(expire=3600)
async def generate_ml_forecast(
    request: MLForecastRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Generate ML-enhanced forecasts using Prophet and custom algorithms.
    Competitive advantage over standard Argus forecasting.
    """
    try:
        service = ForecastingService(db)
        result = await service.generate_ml_forecast(request)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")