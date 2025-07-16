"""
REAL FORECASTING CALCULATION ENDPOINT - DATABASE ANALYSIS
Calculates forecast from historical employee_requests data
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from typing import List, Dict
from datetime import datetime, date, timedelta
from enum import Enum

from ...core.database import get_db

router = APIRouter()

class ForecastType(str, Enum):
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"

class ForecastData(BaseModel):
    period: str
    date: date
    predicted_requests: int
    historical_average: float
    confidence: float
    factors: Dict[str, float]

class ForecastResult(BaseModel):
    forecast_type: ForecastType
    start_date: date
    end_date: date
    total_periods: int
    forecasts: List[ForecastData]
    accuracy_metrics: Dict[str, float]

@router.get("/forecasting/calculate", response_model=ForecastResult, tags=["🔥 REAL Forecasting"])
async def calculate_forecast(
    forecast_type: ForecastType = Query(default=ForecastType.WEEKLY),
    periods: int = Query(default=4, ge=1, le=12),
    db: AsyncSession = Depends(get_db)
):
    """
    REAL FORECAST CALCULATION - FROM HISTORICAL DATA!
    
    Analyzes employee_requests patterns to predict future workload
    Uses actual database trends, not simulations
    """
    try:
        # Calculate date ranges
        today = date.today()
        if forecast_type == ForecastType.DAILY:
            start_date = today + timedelta(days=1)
            end_date = today + timedelta(days=periods)
            history_days = 30
        elif forecast_type == ForecastType.WEEKLY:
            start_date = today + timedelta(days=(7 - today.weekday()))
            end_date = start_date + timedelta(weeks=periods)
            history_days = 90
        else:  # MONTHLY
            start_date = date(today.year, today.month + 1, 1) if today.month < 12 else date(today.year + 1, 1, 1)
            end_date = start_date + timedelta(days=periods * 30)
            history_days = 180
        
        # Get historical data
        history_query = text("""
            SELECT 
                DATE(submitted_at) as request_date,
                COUNT(*) as request_count,
                COUNT(DISTINCT employee_id) as unique_employees
            FROM employee_requests
            WHERE DATE(submitted_at) >= :history_start
            GROUP BY DATE(submitted_at)
            ORDER BY request_date
        """)
        
        history_start = today - timedelta(days=history_days)
        result = await db.execute(history_query, {"history_start": history_start})
        historical_data = result.fetchall()
        
        # Calculate historical patterns
        daily_counts = {row.request_date: row.request_count for row in historical_data}
        total_days = len(daily_counts)
        total_requests = sum(daily_counts.values())
        avg_daily = total_requests / total_days if total_days > 0 else 0
        
        # Get day-of-week patterns
        dow_query = text("""
            SELECT 
                EXTRACT(DOW FROM submitted_at) as day_of_week,
                COUNT(*) as request_count
            FROM employee_requests
            WHERE DATE(submitted_at) >= :history_start
            GROUP BY EXTRACT(DOW FROM submitted_at)
        """)
        
        dow_result = await db.execute(dow_query, {"history_start": history_start})
        dow_data = {int(row.day_of_week): row.request_count for row in dow_result.fetchall()}
        
        # Calculate forecasts
        forecasts = []
        current_date = start_date
        
        while current_date <= end_date and len(forecasts) < periods:
            # Base prediction on historical average
            base_prediction = avg_daily
            
            # Apply day-of-week factor
            dow = current_date.weekday()
            dow_count = dow_data.get(dow, 0)
            dow_avg = sum(dow_data.values()) / 7 if dow_data else 1
            dow_factor = (dow_count / dow_avg) if dow_avg > 0 else 1.0
            
            # Weekend factor
            weekend_factor = 0.3 if dow >= 5 else 1.0
            
            # Seasonal factor (summer = more requests)
            month = current_date.month
            seasonal_factor = 1.2 if month in [6, 7, 8] else 0.9 if month in [12, 1, 2] else 1.0
            
            # Calculate final prediction
            predicted = int(base_prediction * dow_factor * weekend_factor * seasonal_factor)
            confidence = min(0.95, 0.5 + (total_days / 100))  # More history = higher confidence
            
            if forecast_type == ForecastType.DAILY:
                period_label = current_date.strftime("%Y-%m-%d")
                current_date += timedelta(days=1)
            elif forecast_type == ForecastType.WEEKLY:
                period_label = f"Week {current_date.strftime('%Y-%W')}"
                predicted *= 7  # Weekly total
                current_date += timedelta(weeks=1)
            else:  # MONTHLY
                period_label = current_date.strftime("%Y-%m")
                predicted *= 30  # Monthly total
                current_date = (current_date + timedelta(days=32)).replace(day=1)
            
            forecasts.append(ForecastData(
                period=period_label,
                date=current_date - timedelta(days=1),
                predicted_requests=max(0, predicted),
                historical_average=avg_daily,
                confidence=round(confidence, 2),
                factors={
                    "day_of_week": round(dow_factor, 2),
                    "weekend": round(weekend_factor, 2),
                    "seasonal": round(seasonal_factor, 2)
                }
            ))
        
        # Calculate accuracy metrics
        variance = sum((count - avg_daily) ** 2 for count in daily_counts.values()) / total_days if total_days > 0 else 0
        std_dev = variance ** 0.5
        
        return ForecastResult(
            forecast_type=forecast_type,
            start_date=start_date,
            end_date=forecasts[-1].date if forecasts else end_date,
            total_periods=len(forecasts),
            forecasts=forecasts,
            accuracy_metrics={
                "historical_days": total_days,
                "average_daily_requests": round(avg_daily, 2),
                "standard_deviation": round(std_dev, 2),
                "confidence_level": round(sum(f.confidence for f in forecasts) / len(forecasts), 2) if forecasts else 0
            }
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to calculate forecast: {str(e)}"
        )

"""
ENDPOINT 13 COMPLETE!
Test: curl "http://localhost:8000/api/v1/forecasting/calculate?forecast_type=weekly&periods=4"
"""