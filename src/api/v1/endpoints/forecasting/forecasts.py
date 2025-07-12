"""
Forecast Management Endpoints (5 endpoints)
- POST /api/v1/forecasts (Create forecast)
- GET /api/v1/forecasts (List forecasts)
- GET /api/v1/forecasts/{id} (Get forecast)
- PUT /api/v1/forecasts/{id} (Update forecast)
- DELETE /api/v1/forecasts/{id} (Delete forecast)
"""

from typing import List, Optional
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func

from ....core.database import get_db
from ...auth.dependencies import get_current_user, require_permissions
from ....db.models import Forecast, ForecastDataPoint, User
from ....services.forecasting_service import ForecastingService
from ....websocket.handlers.forecast_handlers import ForecastWebSocketHandler
from ...schemas.forecasting import (
    ForecastCreate, ForecastUpdate, ForecastResponse, ForecastListQuery,
    PaginatedResponse, ErrorResponse
)

router = APIRouter(prefix="/forecasts", tags=["forecasts"])


@router.get("/", response_model=PaginatedResponse)
async def list_forecasts(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    forecast_type: Optional[str] = Query(None),
    department_id: Optional[UUID] = Query(None),
    service_id: Optional[str] = Query(None),
    status: Optional[str] = Query("active"),
    created_after: Optional[str] = Query(None),
    created_before: Optional[str] = Query(None),
    current_user: User = Depends(require_permissions(["forecasts.read"])),
    db: Session = Depends(get_db)
):
    """
    List forecasts with filtering and pagination.
    
    Supports filtering by:
    - forecast_type: call_volume, aht, shrinkage, etc.
    - department_id: Filter by department
    - service_id: Filter by service
    - status: draft, active, archived
    - created_after/before: Date range filtering
    """
    try:
        query = db.query(Forecast)
        
        # Apply filters
        if forecast_type:
            query = query.filter(Forecast.forecast_type == forecast_type)
        
        if department_id:
            query = query.filter(Forecast.department_id == department_id)
        
        if service_id:
            query = query.filter(Forecast.service_id == service_id)
        
        if status:
            query = query.filter(Forecast.status == status)
        
        if created_after:
            query = query.filter(Forecast.created_at >= created_after)
        
        if created_before:
            query = query.filter(Forecast.created_at <= created_before)
        
        # Organization isolation
        if not current_user.is_superuser:
            query = query.filter(Forecast.organization_id == current_user.organization_id)
        
        # Get total count
        total = query.count()
        
        # Apply pagination
        forecasts = query.offset(skip).limit(limit).all()
        
        # Enhance with computed fields
        forecast_responses = []
        for forecast in forecasts:
            forecast_data = ForecastResponse.from_orm(forecast)
            # Add data points count
            forecast_data.data_points_count = len(forecast.data_points)
            forecast_responses.append(forecast_data.dict())
        
        return PaginatedResponse(
            items=forecast_responses,
            total=total,
            skip=skip,
            limit=limit,
            has_next=skip + limit < total,
            has_previous=skip > 0
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error listing forecasts: {str(e)}"
        )


@router.post("/", response_model=ForecastResponse)
async def create_forecast(
    forecast_data: ForecastCreate,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_permissions(["forecasts.write"])),
    db: Session = Depends(get_db)
):
    """
    Create a new forecast.
    
    Supports:
    - Manual forecast creation with data points
    - Metadata storage for forecast parameters
    - Automatic organization assignment
    - Background data processing
    """
    try:
        # Validate date range
        if forecast_data.end_date <= forecast_data.start_date:
            raise HTTPException(
                status_code=400,
                detail="End date must be after start date"
            )
        
        # Create forecast
        forecast = Forecast(
            **forecast_data.dict(exclude={"data"}),
            created_by=current_user.id,
            organization_id=current_user.organization_id
        )
        
        db.add(forecast)
        db.flush()
        
        # Add data points if provided
        if forecast_data.data:
            service = ForecastingService(db)
            await service.process_forecast_data_points(forecast.id, forecast_data.data)
        
        db.commit()
        db.refresh(forecast)
        
        # Trigger background processing
        background_tasks.add_task(
            ForecastingService.post_create_processing,
            forecast.id,
            current_user.id
        )
        
        # WebSocket notification
        await ForecastWebSocketHandler.notify_forecast_created(forecast.id)
        
        response_data = ForecastResponse.from_orm(forecast)
        response_data.data_points_count = len(forecast.data_points)
        
        return response_data
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error creating forecast: {str(e)}"
        )


@router.get("/{forecast_id}", response_model=ForecastResponse)
async def get_forecast(
    forecast_id: UUID,
    include_data_points: bool = Query(False),
    current_user: User = Depends(require_permissions(["forecasts.read"])),
    db: Session = Depends(get_db)
):
    """
    Get a specific forecast by ID.
    
    Options:
    - include_data_points: Include all forecast data points in response
    """
    try:
        forecast = db.query(Forecast).filter(Forecast.id == forecast_id).first()
        
        if not forecast:
            raise HTTPException(status_code=404, detail="Forecast not found")
        
        # Organization check
        if not current_user.is_superuser and forecast.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        response_data = ForecastResponse.from_orm(forecast)
        response_data.data_points_count = len(forecast.data_points)
        
        # Include data points if requested
        if include_data_points:
            data_points = db.query(ForecastDataPoint).filter(
                ForecastDataPoint.forecast_id == forecast_id
            ).order_by(ForecastDataPoint.timestamp).all()
            
            response_data.data_points = [
                {
                    "timestamp": dp.timestamp,
                    "predicted_value": dp.predicted_value,
                    "actual_value": dp.actual_value,
                    "confidence_interval_lower": dp.confidence_interval_lower,
                    "confidence_interval_upper": dp.confidence_interval_upper
                }
                for dp in data_points
            ]
        
        return response_data
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving forecast: {str(e)}"
        )


@router.put("/{forecast_id}", response_model=ForecastResponse)
async def update_forecast(
    forecast_id: UUID,
    forecast_update: ForecastUpdate,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_permissions(["forecasts.write"])),
    db: Session = Depends(get_db)
):
    """
    Update an existing forecast.
    
    Supports:
    - Partial updates of forecast metadata
    - Data point updates
    - Status changes
    - Version management
    """
    try:
        forecast = db.query(Forecast).filter(Forecast.id == forecast_id).first()
        
        if not forecast:
            raise HTTPException(status_code=404, detail="Forecast not found")
        
        # Organization check
        if not current_user.is_superuser and forecast.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Check if forecast is editable
        if forecast.status == "archived":
            raise HTTPException(
                status_code=400,
                detail="Cannot update archived forecast"
            )
        
        # Update fields
        update_data = forecast_update.dict(exclude_unset=True)
        
        # Handle data updates
        if "data" in update_data:
            data_points = update_data.pop("data")
            if data_points:
                service = ForecastingService(db)
                await service.update_forecast_data_points(forecast_id, data_points)
        
        # Apply updates
        for field, value in update_data.items():
            setattr(forecast, field, value)
        
        # Increment version for significant changes
        if any(field in update_data for field in ["name", "data", "metadata", "status"]):
            forecast.version += 1
        
        db.commit()
        db.refresh(forecast)
        
        # Trigger background processing for data changes
        if "data" in forecast_update.dict(exclude_unset=True):
            background_tasks.add_task(
                ForecastingService.recalculate_forecast_metrics,
                forecast.id,
                current_user.id
            )
        
        # WebSocket notification
        await ForecastWebSocketHandler.notify_forecast_updated(forecast.id)
        
        response_data = ForecastResponse.from_orm(forecast)
        response_data.data_points_count = len(forecast.data_points)
        
        return response_data
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error updating forecast: {str(e)}"
        )


@router.delete("/{forecast_id}")
async def delete_forecast(
    forecast_id: UUID,
    force: bool = Query(False, description="Force delete even if forecast is referenced"),
    current_user: User = Depends(require_permissions(["forecasts.delete"])),
    db: Session = Depends(get_db)
):
    """
    Delete a forecast.
    
    Options:
    - force: Force deletion even if forecast is referenced by staffing plans
    
    Note: This performs a soft delete by setting status to 'archived' unless force=True
    """
    try:
        forecast = db.query(Forecast).filter(Forecast.id == forecast_id).first()
        
        if not forecast:
            raise HTTPException(status_code=404, detail="Forecast not found")
        
        # Organization check
        if not current_user.is_superuser and forecast.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Check for dependencies
        if not force and forecast.staffing_plans:
            raise HTTPException(
                status_code=400,
                detail="Cannot delete forecast with associated staffing plans. Use force=true to override."
            )
        
        if force:
            # Hard delete - cascade will handle related records
            db.delete(forecast)
        else:
            # Soft delete - archive the forecast
            forecast.status = "archived"
        
        db.commit()
        
        # WebSocket notification
        await ForecastWebSocketHandler.notify_forecast_deleted(forecast_id)
        
        return {
            "message": "Forecast deleted successfully",
            "forecast_id": str(forecast_id),
            "deleted_at": func.now()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error deleting forecast: {str(e)}"
        )


@router.get("/{forecast_id}/data-points")
async def get_forecast_data_points(
    forecast_id: UUID,
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(1000, ge=1, le=10000),
    current_user: User = Depends(require_permissions(["forecasts.read"])),
    db: Session = Depends(get_db)
):
    """
    Get forecast data points with optional date filtering.
    
    Supports:
    - Date range filtering
    - Pagination for large datasets
    - Time series data optimized queries
    """
    try:
        # Verify forecast exists and user has access
        forecast = db.query(Forecast).filter(Forecast.id == forecast_id).first()
        
        if not forecast:
            raise HTTPException(status_code=404, detail="Forecast not found")
        
        if not current_user.is_superuser and forecast.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Build query
        query = db.query(ForecastDataPoint).filter(
            ForecastDataPoint.forecast_id == forecast_id
        )
        
        # Apply date filters
        if start_date:
            query = query.filter(ForecastDataPoint.timestamp >= start_date)
        
        if end_date:
            query = query.filter(ForecastDataPoint.timestamp <= end_date)
        
        # Order by timestamp
        query = query.order_by(ForecastDataPoint.timestamp)
        
        # Get total count
        total = query.count()
        
        # Apply pagination
        data_points = query.offset(skip).limit(limit).all()
        
        # Format response
        formatted_data_points = [
            {
                "timestamp": dp.timestamp,
                "predicted_value": dp.predicted_value,
                "actual_value": dp.actual_value,
                "confidence_interval_lower": dp.confidence_interval_lower,
                "confidence_interval_upper": dp.confidence_interval_upper,
                "seasonal_factor": dp.seasonal_factor,
                "trend_factor": dp.trend_factor,
                "holiday_factor": dp.holiday_factor
            }
            for dp in data_points
        ]
        
        return {
            "forecast_id": str(forecast_id),
            "data_points": formatted_data_points,
            "total": total,
            "skip": skip,
            "limit": limit,
            "has_next": skip + limit < total,
            "has_previous": skip > 0
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving forecast data points: {str(e)}"
        )