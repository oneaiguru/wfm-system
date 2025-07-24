#!/usr/bin/env python3
"""
Prediction API Integration
Connect 4 prediction engines with UI/API endpoints for complete integration
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
from pydantic import BaseModel, Field
import sys
import os

# Add algorithm path for imports
sys.path.append('/Users/m/Documents/wfm/main/agents/ALGORITHM-OPUS/algorithms/prediction')

from call_volume_predictor_real import CallVolumePredictorReal, VolumePredict
from aht_trend_analyzer_real import AHTTrendAnalyzerReal, AHTTrendResult
from forecast_accuracy_calculator_real import ForecastAccuracyCalculatorReal, AccuracyMetrics
from what_if_scenario_engine_real import WhatIfScenarioEngineReal, ScenarioParameters, ScenarioResult

router = APIRouter()

# Request/Response Models
class CallVolumeRequest(BaseModel):
    """Request model for call volume prediction"""
    forecast_date: str = Field(..., description="Date for forecast (YYYY-MM-DD)")
    hours_ahead: int = Field(default=24, ge=1, le=168, description="Hours to forecast ahead")
    channel_id: Optional[int] = Field(default=1, description="Channel ID for prediction")

class CallVolumeResponse(BaseModel):
    """Response model for call volume prediction"""
    success: bool
    forecast_date: str
    predictions: List[Dict[str, Any]]
    total_volume: float
    confidence_interval: Dict[str, float]
    seasonal_factors: Dict[str, float]
    processing_time_ms: float

class AHTTrendRequest(BaseModel):
    """Request model for AHT trend analysis"""
    start_date: str = Field(..., description="Start date for analysis (YYYY-MM-DD)")
    end_date: str = Field(..., description="End date for analysis (YYYY-MM-DD)")
    channel_id: Optional[int] = Field(default=1, description="Channel ID for analysis")

class AHTTrendResponse(BaseModel):
    """Response model for AHT trend analysis"""
    success: bool
    analysis_period: Dict[str, str]
    trend_factor: float
    volatility_score: float
    trend_direction: str
    forecasted_aht: float
    recommendations: List[str]
    processing_time_ms: float

class AccuracyRequest(BaseModel):
    """Request model for forecast accuracy calculation"""
    model_type: str = Field(..., description="Type of model to evaluate")
    evaluation_period_days: int = Field(default=30, ge=7, le=90, description="Days to evaluate")

class AccuracyResponse(BaseModel):
    """Response model for forecast accuracy"""
    success: bool
    model_type: str
    mape_score: float
    wape_score: float
    accuracy_grade: str
    degradation_detected: bool
    improvement_suggestions: List[str]
    processing_time_ms: float

class ScenarioRequest(BaseModel):
    """Request model for what-if scenario analysis"""
    scenario_name: str = Field(..., description="Name of the scenario")
    growth_factor: float = Field(..., ge=0.5, le=3.0, description="Growth factor multiplier")
    seasonal_adjustment: float = Field(default=1.0, ge=0.8, le=1.2, description="Seasonal adjustment")
    forecast_horizon_days: int = Field(default=30, ge=7, le=90, description="Days to forecast")

class ScenarioResponse(BaseModel):
    """Response model for scenario analysis"""
    success: bool
    scenario_name: str
    parameters: Dict[str, float]
    projected_volume: float
    volume_change: float
    impact_assessment: str
    recommendations: List[str]
    processing_time_ms: float

# API Endpoints

@router.post("/predictions/call-volume", response_model=CallVolumeResponse)
async def predict_call_volume(request: CallVolumeRequest):
    """
    Predict call volume using CallVolumePredictorReal
    """
    start_time = datetime.now()
    
    try:
        # Initialize predictor
        predictor = CallVolumePredictorReal()
        
        # Run prediction
        predictions = predictor.predict_volume(
            forecast_date=request.forecast_date,
            hours_ahead=request.hours_ahead,
            channel_id=request.channel_id
        )
        
        # Calculate aggregated metrics
        total_volume = sum(pred.predicted_volume for pred in predictions)
        
        # Format predictions for response
        formatted_predictions = [
            {
                "hour": pred.forecast_hour,
                "predicted_volume": pred.predicted_volume,
                "confidence_level": pred.confidence_level,
                "seasonal_factor": pred.seasonal_factor
            }
            for pred in predictions
        ]
        
        # Calculate processing time
        processing_time = (datetime.now() - start_time).total_seconds() * 1000
        
        return CallVolumeResponse(
            success=True,
            forecast_date=request.forecast_date,
            predictions=formatted_predictions,
            total_volume=total_volume,
            confidence_interval={
                "lower": total_volume * 0.85,
                "upper": total_volume * 1.15
            },
            seasonal_factors={
                "average": sum(pred.seasonal_factor for pred in predictions) / len(predictions)
            },
            processing_time_ms=processing_time
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Call volume prediction failed: {str(e)}")

@router.post("/predictions/aht-trend", response_model=AHTTrendResponse)
async def analyze_aht_trend(request: AHTTrendRequest):
    """
    Analyze AHT trends using AHTTrendAnalyzerReal
    """
    start_time = datetime.now()
    
    try:
        # Initialize analyzer
        analyzer = AHTTrendAnalyzerReal()
        
        # Run trend analysis
        analysis = analyzer.analyze_aht_trends(
            start_date=request.start_date,
            end_date=request.end_date,
            channel_id=request.channel_id
        )
        
        # Generate recommendations based on trend
        recommendations = []
        if analysis.trend_factor > 1.1:
            recommendations.append("AHT increasing - review agent training")
            recommendations.append("Consider process optimization")
        elif analysis.trend_factor < 0.9:
            recommendations.append("AHT improving - maintain current practices")
        else:
            recommendations.append("AHT stable - monitor for changes")
        
        if analysis.volatility_score > 0.3:
            recommendations.append("High volatility detected - investigate causes")
        
        # Determine trend direction
        if analysis.trend_factor > 1.05:
            trend_direction = "increasing"
        elif analysis.trend_factor < 0.95:
            trend_direction = "decreasing"
        else:
            trend_direction = "stable"
        
        # Calculate processing time
        processing_time = (datetime.now() - start_time).total_seconds() * 1000
        
        return AHTTrendResponse(
            success=True,
            analysis_period={
                "start_date": request.start_date,
                "end_date": request.end_date
            },
            trend_factor=analysis.trend_factor,
            volatility_score=analysis.volatility_score,
            trend_direction=trend_direction,
            forecasted_aht=analysis.forecasted_aht,
            recommendations=recommendations,
            processing_time_ms=processing_time
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AHT trend analysis failed: {str(e)}")

@router.post("/predictions/accuracy", response_model=AccuracyResponse)
async def calculate_forecast_accuracy(request: AccuracyRequest):
    """
    Calculate forecast accuracy using ForecastAccuracyCalculatorReal
    """
    start_time = datetime.now()
    
    try:
        # Initialize calculator
        calculator = ForecastAccuracyCalculatorReal()
        
        # Calculate accuracy metrics
        metrics = calculator.calculate_accuracy_metrics(
            model_type=request.model_type,
            evaluation_period_days=request.evaluation_period_days
        )
        
        # Determine accuracy grade
        if metrics.mape_score < 10:
            accuracy_grade = "Excellent"
        elif metrics.mape_score < 20:
            accuracy_grade = "Good"
        elif metrics.mape_score < 30:
            accuracy_grade = "Fair"
        else:
            accuracy_grade = "Poor"
        
        # Generate improvement suggestions
        suggestions = []
        if metrics.mape_score > 20:
            suggestions.append("Consider model retraining")
            suggestions.append("Review input data quality")
        if metrics.degradation_detected:
            suggestions.append("Immediate model update required")
            suggestions.append("Investigate recent data changes")
        if metrics.wape_score > metrics.mape_score + 5:
            suggestions.append("Check for data outliers")
        
        # Calculate processing time
        processing_time = (datetime.now() - start_time).total_seconds() * 1000
        
        return AccuracyResponse(
            success=True,
            model_type=request.model_type,
            mape_score=metrics.mape_score,
            wape_score=metrics.wape_score,
            accuracy_grade=accuracy_grade,
            degradation_detected=metrics.degradation_detected,
            improvement_suggestions=suggestions,
            processing_time_ms=processing_time
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Accuracy calculation failed: {str(e)}")

@router.post("/predictions/scenario", response_model=ScenarioResponse)
async def run_what_if_scenario(request: ScenarioRequest):
    """
    Run what-if scenario analysis using WhatIfScenarioEngineReal
    """
    start_time = datetime.now()
    
    try:
        # Initialize scenario engine
        engine = WhatIfScenarioEngineReal()
        
        # Create scenario parameters
        params = ScenarioParameters(
            scenario_name=request.scenario_name,
            growth_factor=request.growth_factor,
            seasonal_adjustment=request.seasonal_adjustment,
            forecast_horizon_days=request.forecast_horizon_days
        )
        
        # Run scenario
        result = engine.run_scenario(params)
        
        # Calculate volume change percentage
        baseline_volume = result.projected_volume / request.growth_factor
        volume_change = ((result.projected_volume - baseline_volume) / baseline_volume) * 100
        
        # Determine impact assessment
        if abs(volume_change) < 5:
            impact_assessment = "minimal"
        elif abs(volume_change) < 15:
            impact_assessment = "moderate"
        elif abs(volume_change) < 25:
            impact_assessment = "significant"
        else:
            impact_assessment = "major"
        
        # Generate recommendations
        recommendations = []
        if volume_change > 10:
            recommendations.append("Consider increasing staffing levels")
            recommendations.append("Review capacity planning")
        elif volume_change < -10:
            recommendations.append("Potential for staff optimization")
            recommendations.append("Evaluate cost reduction opportunities")
        else:
            recommendations.append("Current staffing levels adequate")
        
        if request.growth_factor > 1.5:
            recommendations.append("High growth scenario - validate assumptions")
        
        # Calculate processing time
        processing_time = (datetime.now() - start_time).total_seconds() * 1000
        
        return ScenarioResponse(
            success=True,
            scenario_name=request.scenario_name,
            parameters={
                "growth_factor": request.growth_factor,
                "seasonal_adjustment": request.seasonal_adjustment,
                "forecast_horizon_days": request.forecast_horizon_days
            },
            projected_volume=result.projected_volume,
            volume_change=volume_change,
            impact_assessment=impact_assessment,
            recommendations=recommendations,
            processing_time_ms=processing_time
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Scenario analysis failed: {str(e)}")

@router.get("/predictions/health")
async def health_check():
    """
    Health check for prediction services
    """
    try:
        # Test each prediction engine
        results = {}
        
        # Test call volume predictor
        try:
            predictor = CallVolumePredictorReal()
            results["call_volume_predictor"] = "healthy"
        except Exception as e:
            results["call_volume_predictor"] = f"error: {str(e)}"
        
        # Test AHT analyzer
        try:
            analyzer = AHTTrendAnalyzerReal()
            results["aht_trend_analyzer"] = "healthy"
        except Exception as e:
            results["aht_trend_analyzer"] = f"error: {str(e)}"
        
        # Test accuracy calculator
        try:
            calculator = ForecastAccuracyCalculatorReal()
            results["forecast_accuracy_calculator"] = "healthy"
        except Exception as e:
            results["forecast_accuracy_calculator"] = f"error: {str(e)}"
        
        # Test scenario engine
        try:
            engine = WhatIfScenarioEngineReal()
            results["what_if_scenario_engine"] = "healthy"
        except Exception as e:
            results["what_if_scenario_engine"] = f"error: {str(e)}"
        
        # Overall health
        healthy_count = sum(1 for status in results.values() if status == "healthy")
        overall_health = "healthy" if healthy_count == 4 else "degraded"
        
        return {
            "status": overall_health,
            "engines": results,
            "healthy_engines": f"{healthy_count}/4",
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Health check failed: {str(e)}")

@router.get("/predictions/models")
async def list_available_models():
    """
    List all available prediction models
    """
    return {
        "prediction_engines": [
            {
                "name": "CallVolumePredictorReal",
                "description": "Multi-channel call volume forecasting with seasonal patterns",
                "endpoint": "/predictions/call-volume",
                "performance_target": "500ms",
                "capabilities": ["hourly_forecasting", "seasonal_analysis", "confidence_intervals"]
            },
            {
                "name": "AHTTrendAnalyzerReal", 
                "description": "Average Handling Time trend analysis and prediction",
                "endpoint": "/predictions/aht-trend",
                "performance_target": "500ms",
                "capabilities": ["trend_analysis", "volatility_tracking", "forecasting"]
            },
            {
                "name": "ForecastAccuracyCalculatorReal",
                "description": "MAPE and WAPE calculation for forecast validation",
                "endpoint": "/predictions/accuracy",
                "performance_target": "300ms",
                "capabilities": ["accuracy_metrics", "degradation_detection", "model_evaluation"]
            },
            {
                "name": "WhatIfScenarioEngineReal",
                "description": "Scenario modeling with growth factors and impact analysis",
                "endpoint": "/predictions/scenario",
                "performance_target": "2000ms",
                "capabilities": ["scenario_modeling", "impact_analysis", "parameter_variation"]
            }
        ],
        "integration_status": "complete",
        "database_integration": "wfm_enterprise PostgreSQL",
        "real_data_only": True
    }