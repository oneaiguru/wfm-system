from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.core.database import get_db
from src.api.v1.schemas.algorithm import (
    ErlangCRequest,
    ErlangCResponse,
    ForecastRequest,
    ForecastResponse,
    ScheduleOptimizationRequest,
    ScheduleOptimizationResponse
)
from src.api.services.algorithm_service import AlgorithmService
from src.api.utils.cache import cache_decorator

router = APIRouter()


@router.post("/erlang-c", response_model=ErlangCResponse)
async def calculate_erlang_c(
    request: ErlangCRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Calculate Erlang C metrics for workforce planning.
    Response time: <100ms for standard calculations.
    """
    try:
        service = AlgorithmService(db)
        result = await service.calculate_erlang_c(request)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@router.post("/forecast", response_model=ForecastResponse)
@cache_decorator(expire=3600)
async def generate_forecast(
    request: ForecastRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Generate ML-based forecast using Prophet and enhanced algorithms.
    Response time: 1-10 seconds depending on data size.
    """
    try:
        service = AlgorithmService(db)
        result = await service.generate_forecast(request)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@router.post("/optimize-schedule", response_model=ScheduleOptimizationResponse)
async def optimize_schedule(
    request: ScheduleOptimizationRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Optimize agent schedules using multi-skill algorithms.
    Handles billions of combinations in seconds.
    """
    try:
        service = AlgorithmService(db)
        result = await service.optimize_schedule(request)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")