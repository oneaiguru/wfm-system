"""
Forecast Operations Endpoints (7 endpoints)
- POST /api/v1/forecasts/generate (ML generation)
- POST /api/v1/forecasts/import (Import from file)
- POST /api/v1/forecasts/growth-factor (Apply growth)
- POST /api/v1/forecasts/seasonal (Seasonal adjustment)
- GET /api/v1/forecasts/accuracy (Accuracy metrics)
- POST /api/v1/forecasts/compare (Compare versions)
- POST /api/v1/forecasts/export (Export forecast data)
"""

from typing import List, Dict, Any, Optional
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, UploadFile, File
from sqlalchemy.orm import Session
from datetime import datetime
import json
import io
import pandas as pd

from ....core.database import get_db
from ...auth.dependencies import get_current_user, require_permissions
from ....db.models import Forecast, ForecastDataPoint, User
from ....services.forecasting_service import ForecastingService
from ....algorithms.ml.ml_ensemble import MLEnsembleForecaster
from ....algorithms.core.erlang_c_enhanced import ErlangCEnhanced
from ....websocket.handlers.forecast_handlers import ForecastWebSocketHandler
from ...schemas.forecasting import (
    ForecastGenerate, ForecastImport, ForecastExport, GrowthFactorApplication,
    SeasonalAdjustment, ForecastComparison, ForecastAccuracy, ForecastResponse,
    ErrorResponse, BatchOperationResponse
)

router = APIRouter(prefix="/forecasts", tags=["forecast-operations"])


@router.post("/generate", response_model=ForecastResponse)
async def generate_forecast(
    generate_data: ForecastGenerate,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_permissions(["forecasts.generate"])),
    db: Session = Depends(get_db)
):
    """
    Generate ML-powered forecast using ensemble models.
    
    Features:
    - Auto-selects best ML model (Prophet, ARIMA, LightGBM ensemble)
    - Supports multiple forecast types (call_volume, aht, shrinkage)
    - Automatic seasonality and holiday detection
    - Confidence intervals and accuracy metrics
    - Background processing for large datasets
    """
    try:
        # Validate department exists and user has access
        if not current_user.is_superuser:
            # Add department validation logic here
            pass
        
        # Create forecast record
        forecast = Forecast(
            name=generate_data.name,
            forecast_type=generate_data.forecast_type,
            method="ml",
            granularity=generate_data.granularity,
            start_date=generate_data.start_date,
            end_date=generate_data.end_date,
            department_id=generate_data.department_id,
            service_id=generate_data.service_id,
            status="generating",
            metadata={
                "model_type": generate_data.model_type,
                "historical_months": generate_data.historical_months,
                "include_holidays": generate_data.include_holidays,
                "seasonal_adjustment": generate_data.seasonal_adjustment,
                "generated_by": "ml_ensemble"
            },
            created_by=current_user.id,
            organization_id=current_user.organization_id
        )
        
        db.add(forecast)
        db.commit()
        db.refresh(forecast)
        
        # Start background ML generation
        background_tasks.add_task(
            ForecastingService.generate_ml_forecast_background,
            forecast.id,
            generate_data.dict(),
            current_user.id
        )
        
        # WebSocket notification
        await ForecastWebSocketHandler.notify_forecast_generation_started(forecast.id)
        
        response_data = ForecastResponse.from_orm(forecast)
        response_data.data_points_count = 0
        
        return response_data
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error starting forecast generation: {str(e)}"
        )


@router.post("/import", response_model=ForecastResponse)
async def import_forecast(
    import_data: ForecastImport,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_permissions(["forecasts.write"])),
    db: Session = Depends(get_db)
):
    """
    Import forecast data from external source.
    
    Supports:
    - JSON format with timestamp/value pairs
    - CSV data import
    - Excel file import
    - Data validation and cleaning
    - Automatic time series analysis
    """
    try:
        # Validate data format
        if not import_data.data:
            raise HTTPException(
                status_code=400,
                detail="No data provided for import"
            )
        
        # Validate data structure
        required_fields = ['timestamp', 'value']
        for i, item in enumerate(import_data.data):
            for field in required_fields:
                if field not in item:
                    raise HTTPException(
                        status_code=400,
                        detail=f"Missing required field '{field}' in data item {i}"
                    )
        
        # Determine date range from data
        timestamps = [datetime.fromisoformat(item['timestamp'].replace('Z', '+00:00')) 
                     for item in import_data.data]
        start_date = min(timestamps)
        end_date = max(timestamps)
        
        # Create forecast
        forecast = Forecast(
            name=import_data.name,
            forecast_type=import_data.forecast_type,
            method="imported",
            granularity=import_data.granularity,
            start_date=start_date,
            end_date=end_date,
            metadata={
                **import_data.metadata or {},
                "imported_at": datetime.utcnow().isoformat(),
                "data_points_count": len(import_data.data),
                "imported_by": str(current_user.id)
            },
            created_by=current_user.id,
            organization_id=current_user.organization_id
        )
        
        db.add(forecast)
        db.flush()
        
        # Process data points in background
        background_tasks.add_task(
            ForecastingService.process_imported_data,
            forecast.id,
            import_data.data,
            current_user.id
        )
        
        db.commit()
        db.refresh(forecast)
        
        response_data = ForecastResponse.from_orm(forecast)
        response_data.data_points_count = len(import_data.data)
        
        return response_data
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error importing forecast data: {str(e)}"
        )


@router.post("/import/file")
async def import_forecast_file(
    file: UploadFile = File(...),
    name: str = None,
    forecast_type: str = "call_volume",
    granularity: str = "30min",
    background_tasks: BackgroundTasks = None,
    current_user: User = Depends(require_permissions(["forecasts.write"])),
    db: Session = Depends(get_db)
):
    """
    Import forecast data from uploaded file.
    
    Supported formats:
    - CSV files with timestamp,value columns
    - Excel files with timestamp,value columns
    - JSON files with array of {timestamp, value} objects
    """
    try:
        # Validate file format
        if file.content_type not in ["text/csv", "application/vnd.ms-excel", 
                                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                                    "application/json"]:
            raise HTTPException(
                status_code=400,
                detail="Unsupported file format. Use CSV, Excel, or JSON."
            )
        
        # Read file content
        content = await file.read()
        
        # Parse based on file type
        if file.content_type == "text/csv":
            df = pd.read_csv(io.StringIO(content.decode()))
        elif file.content_type in ["application/vnd.ms-excel", 
                                  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"]:
            df = pd.read_excel(io.BytesIO(content))
        elif file.content_type == "application/json":
            data = json.loads(content.decode())
            df = pd.DataFrame(data)
        
        # Validate columns
        required_columns = ['timestamp', 'value']
        for col in required_columns:
            if col not in df.columns:
                raise HTTPException(
                    status_code=400,
                    detail=f"Missing required column: {col}"
                )
        
        # Convert to import format
        import_data = []
        for _, row in df.iterrows():
            import_data.append({
                'timestamp': row['timestamp'],
                'value': float(row['value'])
            })
        
        # Create import request
        forecast_import = ForecastImport(
            name=name or f"Imported from {file.filename}",
            forecast_type=forecast_type,
            granularity=granularity,
            data=import_data,
            metadata={
                "source_file": file.filename,
                "file_size": len(content),
                "import_method": "file_upload"
            }
        )
        
        # Use the import endpoint
        return await import_forecast(forecast_import, background_tasks, current_user, db)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error processing file import: {str(e)}"
        )


@router.post("/growth-factor")
async def apply_growth_factor(
    growth_request: GrowthFactorApplication,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_permissions(["forecasts.write"])),
    db: Session = Depends(get_db)
):
    """
    Apply growth factor to forecast data.
    
    Features:
    - Selective application (all periods, specific dates, weekdays, weekends)
    - Maintains original forecast for comparison
    - Creates new forecast version with growth applied
    - Automatic recalculation of dependent metrics
    """
    try:
        # Validate forecast exists
        forecast = db.query(Forecast).filter(Forecast.id == growth_request.forecast_id).first()
        
        if not forecast:
            raise HTTPException(status_code=404, detail="Forecast not found")
        
        # Organization check
        if not current_user.is_superuser and forecast.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Start background processing
        background_tasks.add_task(
            ForecastingService.apply_growth_factor_background,
            growth_request.dict(),
            current_user.id
        )
        
        return {
            "message": "Growth factor application started",
            "forecast_id": str(growth_request.forecast_id),
            "growth_factor": growth_request.growth_factor,
            "status": "processing"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error applying growth factor: {str(e)}"
        )


@router.post("/seasonal-adjustment")
async def apply_seasonal_adjustment(
    seasonal_request: SeasonalAdjustment,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_permissions(["forecasts.write"])),
    db: Session = Depends(get_db)
):
    """
    Apply seasonal adjustments to forecast data.
    
    Features:
    - Day-of-week adjustments (monday, tuesday, etc.)
    - Monthly adjustments (january, february, etc.)
    - Multiplicative or additive adjustments
    - Preserves original forecast for comparison
    """
    try:
        # Validate forecast exists
        forecast = db.query(Forecast).filter(Forecast.id == seasonal_request.forecast_id).first()
        
        if not forecast:
            raise HTTPException(status_code=404, detail="Forecast not found")
        
        # Organization check
        if not current_user.is_superuser and forecast.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Start background processing
        background_tasks.add_task(
            ForecastingService.apply_seasonal_adjustment_background,
            seasonal_request.dict(),
            current_user.id
        )
        
        return {
            "message": "Seasonal adjustment started",
            "forecast_id": str(seasonal_request.forecast_id),
            "adjustment_type": seasonal_request.adjustment_type,
            "seasonal_factors": seasonal_request.seasonal_factors,
            "status": "processing"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error applying seasonal adjustment: {str(e)}"
        )


@router.post("/accuracy")
async def calculate_forecast_accuracy(
    accuracy_request: ForecastAccuracy,
    current_user: User = Depends(require_permissions(["forecasts.read"])),
    db: Session = Depends(get_db)
):
    """
    Calculate forecast accuracy metrics.
    
    Metrics:
    - MAPE (Mean Absolute Percentage Error)
    - RMSE (Root Mean Square Error)
    - MAD (Mean Absolute Deviation)
    - Bias (Average forecast error)
    - Accuracy percentage
    """
    try:
        # Validate forecast exists
        forecast = db.query(Forecast).filter(Forecast.id == accuracy_request.forecast_id).first()
        
        if not forecast:
            raise HTTPException(status_code=404, detail="Forecast not found")
        
        # Organization check
        if not current_user.is_superuser and forecast.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Calculate accuracy metrics
        service = ForecastingService(db)
        accuracy_metrics = await service.calculate_accuracy_metrics(
            accuracy_request.forecast_id,
            accuracy_request.actual_data,
            accuracy_request.metrics
        )
        
        # Update forecast with accuracy metrics
        forecast.accuracy_metrics = accuracy_metrics
        forecast.last_validation = datetime.utcnow()
        db.commit()
        
        return {
            "forecast_id": str(accuracy_request.forecast_id),
            "accuracy_metrics": accuracy_metrics,
            "calculated_at": datetime.utcnow().isoformat(),
            "data_points_compared": len(accuracy_request.actual_data)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error calculating forecast accuracy: {str(e)}"
        )


@router.post("/compare")
async def compare_forecasts(
    comparison_request: ForecastComparison,
    current_user: User = Depends(require_permissions(["forecasts.read"])),
    db: Session = Depends(get_db)
):
    """
    Compare multiple forecasts.
    
    Features:
    - Side-by-side comparison of up to 10 forecasts
    - Multiple comparison metrics (MAPE, RMSE, MAD, etc.)
    - Statistical significance testing
    - Visualization data for charts
    """
    try:
        # Validate all forecasts exist and user has access
        forecasts = db.query(Forecast).filter(
            Forecast.id.in_(comparison_request.forecast_ids)
        ).all()
        
        if len(forecasts) != len(comparison_request.forecast_ids):
            raise HTTPException(
                status_code=404,
                detail="One or more forecasts not found"
            )
        
        # Organization check
        if not current_user.is_superuser:
            for forecast in forecasts:
                if forecast.organization_id != current_user.organization_id:
                    raise HTTPException(status_code=403, detail="Access denied")
        
        # Perform comparison
        service = ForecastingService(db)
        comparison_result = await service.compare_forecasts(
            comparison_request.forecast_ids,
            comparison_request.comparison_metrics,
            comparison_request.comparison_period
        )
        
        return {
            "comparison_result": comparison_result,
            "forecasts_compared": len(comparison_request.forecast_ids),
            "metrics_used": comparison_request.comparison_metrics,
            "comparison_period": comparison_request.comparison_period,
            "compared_at": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error comparing forecasts: {str(e)}"
        )


@router.post("/export")
async def export_forecast(
    export_request: ForecastExport,
    current_user: User = Depends(require_permissions(["forecasts.read"])),
    db: Session = Depends(get_db)
):
    """
    Export forecast data in various formats.
    
    Supported formats:
    - JSON: Complete forecast data with metadata
    - CSV: Time series data for Excel/analysis
    - Excel: Formatted workbook with charts
    """
    try:
        # Validate forecast exists
        forecast = db.query(Forecast).filter(Forecast.id == export_request.forecast_id).first()
        
        if not forecast:
            raise HTTPException(status_code=404, detail="Forecast not found")
        
        # Organization check
        if not current_user.is_superuser and forecast.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Export data
        service = ForecastingService(db)
        export_result = await service.export_forecast_data(
            export_request.forecast_id,
            export_request.format,
            export_request.include_metadata,
            export_request.date_range
        )
        
        return {
            "export_result": export_result,
            "forecast_id": str(export_request.forecast_id),
            "format": export_request.format,
            "exported_at": datetime.utcnow().isoformat(),
            "download_url": export_result.get("download_url"),
            "file_size": export_result.get("file_size")
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error exporting forecast: {str(e)}"
        )