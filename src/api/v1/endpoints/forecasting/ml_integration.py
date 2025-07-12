"""
ML Integration Endpoints (4 endpoints)
- POST /api/v1/ml/forecast/train (Train ML model)
- GET /api/v1/ml/forecast/models (List models)
- POST /api/v1/ml/forecast/predict (Make prediction)
- GET /api/v1/ml/forecast/performance (Model performance)
"""

from typing import List, Dict, Any, Optional
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import asyncio
import json

from ....core.database import get_db
from ...auth.dependencies import get_current_user, require_permissions
from ....db.models import ForecastModel, Forecast, User
from ....services.forecasting_service import ForecastingService
from ....algorithms.ml.ml_ensemble import MLEnsembleForecaster, create_ensemble_forecaster
from ....websocket.handlers.forecast_handlers import ForecastWebSocketHandler
from ...schemas.forecasting import (
    MLModelTraining, MLModelResponse, MLPrediction, MLModelPerformance,
    ModelListQuery, PaginatedResponse
)

router = APIRouter(prefix="/ml/forecast", tags=["ml-integration"])


@router.post("/train", response_model=MLModelResponse)
async def train_ml_model(
    training_request: MLModelTraining,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_permissions(["ml.train"])),
    db: Session = Depends(get_db)
):
    """
    Train a new ML forecasting model.
    
    Features:
    - Multiple model types (Prophet, ARIMA, LightGBM, Ensemble)
    - Automatic hyperparameter tuning
    - Cross-validation for model selection
    - Model versioning and management
    - Performance tracking
    """
    try:
        # Validate training data availability
        training_data_days = (training_request.training_data_end - training_request.training_data_start).days
        if training_data_days < 30:
            raise HTTPException(
                status_code=400,
                detail="Training data must span at least 30 days"
            )
        
        # Create model record
        model = ForecastModel(
            name=training_request.name,
            description=f"ML model trained on {training_data_days} days of data",
            model_type=training_request.model_type,
            algorithm=training_request.model_type.value,
            version="1.0.0",
            parameters=training_request.hyperparameters or {},
            training_data_start=training_request.training_data_start,
            training_data_end=training_request.training_data_end,
            status="training",
            created_by=current_user.id
        )
        
        db.add(model)
        db.commit()
        db.refresh(model)
        
        # Start background training
        background_tasks.add_task(
            ForecastingService.train_ml_model_background,
            model.id,
            training_request.dict(),
            current_user.id
        )
        
        # WebSocket notification
        await ForecastWebSocketHandler.notify_model_training_started(model.id)
        
        return MLModelResponse.from_orm(model)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error starting model training: {str(e)}"
        )


@router.get("/models", response_model=PaginatedResponse)
async def list_ml_models(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    model_type: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    is_default: Optional[bool] = Query(None),
    current_user: User = Depends(require_permissions(["ml.read"])),
    db: Session = Depends(get_db)
):
    """
    List ML models with filtering options.
    
    Features:
    - Filter by model type, status, default status
    - Pagination support
    - Model performance metrics
    - Usage statistics
    """
    try:
        query = db.query(ForecastModel)
        
        # Apply filters
        if model_type:
            query = query.filter(ForecastModel.model_type == model_type)
        
        if status:
            query = query.filter(ForecastModel.status == status)
        
        if is_default is not None:
            query = query.filter(ForecastModel.is_default == is_default)
        
        # Order by creation date (newest first)
        query = query.order_by(ForecastModel.created_at.desc())
        
        # Get total count
        total = query.count()
        
        # Apply pagination
        models = query.offset(skip).limit(limit).all()
        
        # Format response
        model_responses = []
        for model in models:
            model_data = MLModelResponse.from_orm(model)
            model_responses.append(model_data.dict())
        
        return PaginatedResponse(
            items=model_responses,
            total=total,
            skip=skip,
            limit=limit,
            has_next=skip + limit < total,
            has_previous=skip > 0
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error listing ML models: {str(e)}"
        )


@router.post("/predict")
async def make_ml_prediction(
    prediction_request: MLPrediction,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_permissions(["ml.predict"])),
    db: Session = Depends(get_db)
):
    """
    Generate predictions using trained ML model.
    
    Features:
    - Single model or ensemble predictions
    - Confidence intervals
    - Batch prediction support
    - Real-time prediction capability
    - Model performance tracking
    """
    try:
        # Validate model exists and is ready
        model = db.query(ForecastModel).filter(ForecastModel.id == prediction_request.model_id).first()
        
        if not model:
            raise HTTPException(status_code=404, detail="Model not found")
        
        if model.status != "active":
            raise HTTPException(
                status_code=400,
                detail=f"Model is not active (status: {model.status})"
            )
        
        # Validate prediction parameters
        prediction_days = (prediction_request.end_date - prediction_request.start_date).days
        if prediction_days > 365:
            raise HTTPException(
                status_code=400,
                detail="Prediction period cannot exceed 365 days"
            )
        
        # Calculate prediction periods based on granularity
        granularity_minutes = {
            "15min": 15,
            "30min": 30,
            "1hour": 60,
            "1day": 1440
        }
        
        minutes_per_period = granularity_minutes.get(prediction_request.granularity, 30)
        total_periods = int((prediction_days * 24 * 60) / minutes_per_period)
        
        # Load and use the model
        service = ForecastingService(db)
        
        if model.model_type == "ensemble":
            # Use ensemble forecaster
            forecaster = create_ensemble_forecaster()
            
            # Load model from file
            model_data = await service.load_model_from_file(model.model_path)
            
            # Generate predictions
            prediction_result = await service.generate_ensemble_predictions(
                forecaster=forecaster,
                model_data=model_data,
                periods=total_periods,
                granularity=prediction_request.granularity,
                include_confidence=prediction_request.confidence_intervals
            )
        else:
            # Use single model
            prediction_result = await service.generate_single_model_predictions(
                model_id=model.id,
                periods=total_periods,
                granularity=prediction_request.granularity,
                include_confidence=prediction_request.confidence_intervals
            )
        
        # Update model usage
        model.last_used = datetime.utcnow()
        db.commit()
        
        # Create forecast record for the prediction
        forecast = Forecast(
            name=f"ML Prediction - {model.name}",
            description=f"Prediction generated using {model.model_type} model",
            forecast_type="call_volume",  # Default, could be parameterized
            method="ml",
            granularity=prediction_request.granularity,
            start_date=prediction_request.start_date,
            end_date=prediction_request.end_date,
            metadata={
                "model_id": str(model.id),
                "model_type": model.model_type,
                "prediction_periods": total_periods,
                "confidence_intervals": prediction_request.confidence_intervals,
                "generated_at": datetime.utcnow().isoformat()
            },
            status="active",
            created_by=current_user.id
        )
        
        db.add(forecast)
        db.flush()
        
        # Store prediction data points
        background_tasks.add_task(
            service.store_prediction_data_points,
            forecast.id,
            prediction_result['predictions'],
            prediction_result.get('confidence_intervals')
        )
        
        db.commit()
        
        return {
            "forecast_id": str(forecast.id),
            "model_id": str(model.id),
            "prediction_result": prediction_result,
            "prediction_periods": total_periods,
            "granularity": prediction_request.granularity,
            "confidence_intervals_included": prediction_request.confidence_intervals,
            "generated_at": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error generating ML prediction: {str(e)}"
        )


@router.get("/performance")
async def get_model_performance(
    model_id: UUID,
    test_data_start: Optional[datetime] = Query(None),
    test_data_end: Optional[datetime] = Query(None),
    metrics: List[str] = Query(["mape", "rmse", "mae", "r2"]),
    current_user: User = Depends(require_permissions(["ml.read"])),
    db: Session = Depends(get_db)
):
    """
    Get ML model performance metrics.
    
    Features:
    - Multiple performance metrics (MAPE, RMSE, MAE, R²)
    - Custom test data periods
    - Comparison with baseline models
    - Performance trend analysis
    - Model degradation detection
    """
    try:
        # Validate model exists
        model = db.query(ForecastModel).filter(ForecastModel.id == model_id).first()
        
        if not model:
            raise HTTPException(status_code=404, detail="Model not found")
        
        # Set default test data period if not provided
        if not test_data_end:
            test_data_end = datetime.utcnow()
        
        if not test_data_start:
            test_data_start = test_data_end - timedelta(days=30)
        
        # Calculate performance metrics
        service = ForecastingService(db)
        performance_result = await service.calculate_model_performance(
            model_id=model_id,
            test_data_start=test_data_start,
            test_data_end=test_data_end,
            metrics=metrics
        )
        
        # Get historical performance for trend analysis
        historical_performance = await service.get_historical_model_performance(
            model_id=model_id,
            days_back=90
        )
        
        # Compare with other models
        model_comparison = await service.compare_model_performance(
            model_id=model_id,
            comparison_period_days=30
        )
        
        return {
            "model_id": str(model_id),
            "model_name": model.name,
            "model_type": model.model_type,
            "performance_metrics": performance_result,
            "test_period": {
                "start": test_data_start.isoformat(),
                "end": test_data_end.isoformat(),
                "days": (test_data_end - test_data_start).days
            },
            "historical_performance": historical_performance,
            "model_comparison": model_comparison,
            "performance_trend": performance_result.get("trend_analysis"),
            "degradation_detected": performance_result.get("degradation_detected", False),
            "calculated_at": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error calculating model performance: {str(e)}"
        )


@router.get("/models/{model_id}", response_model=MLModelResponse)
async def get_ml_model(
    model_id: UUID,
    include_details: bool = Query(False),
    current_user: User = Depends(require_permissions(["ml.read"])),
    db: Session = Depends(get_db)
):
    """
    Get specific ML model details.
    
    Features:
    - Model metadata and configuration
    - Training history and parameters
    - Performance metrics
    - Usage statistics
    """
    try:
        model = db.query(ForecastModel).filter(ForecastModel.id == model_id).first()
        
        if not model:
            raise HTTPException(status_code=404, detail="Model not found")
        
        response_data = MLModelResponse.from_orm(model)
        
        # Include additional details if requested
        if include_details:
            service = ForecastingService(db)
            
            # Get usage statistics
            usage_stats = await service.get_model_usage_statistics(model_id)
            
            # Get recent predictions
            recent_predictions = await service.get_model_recent_predictions(model_id, limit=10)
            
            response_data.usage_statistics = usage_stats
            response_data.recent_predictions = recent_predictions
        
        return response_data
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving ML model: {str(e)}"
        )


@router.put("/models/{model_id}/status")
async def update_model_status(
    model_id: UUID,
    status: str,
    current_user: User = Depends(require_permissions(["ml.train"])),
    db: Session = Depends(get_db)
):
    """
    Update ML model status (activate, deactivate, deprecate).
    """
    try:
        valid_statuses = ["training", "active", "deprecated"]
        if status not in valid_statuses:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid status. Must be one of: {', '.join(valid_statuses)}"
            )
        
        model = db.query(ForecastModel).filter(ForecastModel.id == model_id).first()
        
        if not model:
            raise HTTPException(status_code=404, detail="Model not found")
        
        # Update status
        model.status = status
        
        # If setting as default, remove default from other models of same type
        if status == "active" and hasattr(model, 'is_default') and model.is_default:
            db.query(ForecastModel).filter(
                ForecastModel.model_type == model.model_type,
                ForecastModel.id != model_id
            ).update({"is_default": False})
        
        db.commit()
        
        return {
            "model_id": str(model_id),
            "status": status,
            "updated_at": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error updating model status: {str(e)}"
        )


@router.delete("/models/{model_id}")
async def delete_ml_model(
    model_id: UUID,
    force: bool = Query(False, description="Force delete even if model is in use"),
    current_user: User = Depends(require_permissions(["ml.delete"])),
    db: Session = Depends(get_db)
):
    """
    Delete ML model and associated files.
    """
    try:
        model = db.query(ForecastModel).filter(ForecastModel.id == model_id).first()
        
        if not model:
            raise HTTPException(status_code=404, detail="Model not found")
        
        # Check if model is in use
        if not force:
            recent_usage = await ForecastingService.check_model_recent_usage(model_id, hours=24)
            if recent_usage:
                raise HTTPException(
                    status_code=400,
                    detail="Model has been used recently. Use force=true to delete."
                )
        
        # Delete model files
        service = ForecastingService(db)
        await service.delete_model_files(model.model_path)
        
        # Delete model record
        db.delete(model)
        db.commit()
        
        return {
            "message": "Model deleted successfully",
            "model_id": str(model_id),
            "deleted_at": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error deleting ML model: {str(e)}"
        )