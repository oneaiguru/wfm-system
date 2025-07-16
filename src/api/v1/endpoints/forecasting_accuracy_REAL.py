"""
Forecasting Accuracy API - Task 26
Real PostgreSQL implementation for calculating forecast accuracy metrics
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, Dict, List, Any
from datetime import datetime, date
import psycopg2
from psycopg2.extras import RealDictCursor
import os

router = APIRouter()

def get_db_connection():
    """Get database connection"""
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        database=os.getenv('DB_NAME', 'wfm_enterprise'),
        user=os.getenv('DB_USER', 'postgres'),
        password=os.getenv('DB_PASSWORD', 'postgres'),
        port=os.getenv('DB_PORT', '5432')
    )

@router.get("/api/v1/forecasting/accuracy")
def get_forecasting_accuracy(
    start_date: Optional[date] = Query(None, description="Start date for accuracy analysis"),
    end_date: Optional[date] = Query(None, description="End date for accuracy analysis"),
    model_id: Optional[str] = Query(None, description="Specific forecast model ID"),
    metric_type: Optional[str] = Query("all", description="Type of accuracy metric (mape, rmse, mae, all)")
):
    """
    Calculate and return forecasting accuracy metrics from historical vs actual data
    
    Returns:
    - MAPE (Mean Absolute Percentage Error)
    - RMSE (Root Mean Square Error) 
    - MAE (Mean Absolute Error)
    - Accuracy percentage
    - Count of predictions analyzed
    """
    
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # Base query for accuracy analysis
        base_query = """
            WITH accuracy_calculations AS (
                SELECT 
                    fat.id,
                    fat.model_id,
                    fat.prediction_date,
                    fat.actual_value,
                    fat.predicted_value,
                    fat.accuracy_percentage,
                    fat.error_margin,
                    ABS(fat.actual_value - fat.predicted_value) as absolute_error,
                    CASE 
                        WHEN fat.actual_value != 0 
                        THEN ABS((fat.actual_value - fat.predicted_value) / fat.actual_value) * 100
                        ELSE 0
                    END as percentage_error,
                    POWER(fat.actual_value - fat.predicted_value, 2) as squared_error
                FROM forecast_accuracy_tracking fat
                WHERE fat.actual_value IS NOT NULL
                AND fat.predicted_value IS NOT NULL
        """
        
        conditions = []
        params = []
        
        if start_date:
            conditions.append("AND fat.prediction_date >= %s")
            params.append(start_date)
            
        if end_date:
            conditions.append("AND fat.prediction_date <= %s")
            params.append(end_date)
            
        if model_id:
            conditions.append("AND fat.model_id = %s")
            params.append(model_id)
        
        # Add conditions to query
        if conditions:
            base_query += " " + " ".join(conditions)
        
        # Complete query with metrics calculation
        full_query = base_query + """
            )
            SELECT 
                COUNT(*) as total_predictions,
                AVG(accuracy_percentage) as avg_accuracy_percentage,
                AVG(percentage_error) as mape,
                SQRT(AVG(squared_error)) as rmse,
                AVG(absolute_error) as mae,
                MIN(prediction_date) as earliest_date,
                MAX(prediction_date) as latest_date,
                COUNT(DISTINCT model_id) as models_analyzed,
                STDDEV(percentage_error) as accuracy_std_dev,
                PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY percentage_error) as median_error,
                MAX(percentage_error) as max_error,
                MIN(percentage_error) as min_error
            FROM accuracy_calculations
        """
        
        cur.execute(full_query, params)
        result = cur.fetchone()
        
        if not result or result['total_predictions'] == 0:
            return {
                "status": "no_data",
                "message": "No forecast accuracy data found for the specified criteria",
                "filters": {
                    "start_date": start_date.isoformat() if start_date else None,
                    "end_date": end_date.isoformat() if end_date else None,
                    "model_id": model_id
                }
            }
        
        # Get detailed breakdown by model if no specific model requested
        model_breakdown = []
        if not model_id:
            model_query = base_query + """
                )
                SELECT 
                    ac.model_id,
                    COUNT(*) as prediction_count,
                    AVG(ac.accuracy_percentage) as avg_accuracy,
                    AVG(ac.percentage_error) as mape,
                    SQRT(AVG(ac.squared_error)) as rmse,
                    AVG(ac.absolute_error) as mae,
                    MIN(ac.prediction_date) as first_prediction,
                    MAX(ac.prediction_date) as last_prediction
                FROM accuracy_calculations ac
                WHERE ac.model_id IS NOT NULL
                GROUP BY ac.model_id
                ORDER BY AVG(ac.accuracy_percentage) DESC
            """
            
            cur.execute(model_query, params)
            model_results = cur.fetchall()
            
            for model in model_results:
                model_breakdown.append({
                    "model_id": str(model['model_id']) if model['model_id'] else None,
                    "prediction_count": model['prediction_count'],
                    "avg_accuracy": float(model['avg_accuracy']) if model['avg_accuracy'] else None,
                    "mape": float(model['mape']) if model['mape'] else None,
                    "rmse": float(model['rmse']) if model['rmse'] else None,
                    "mae": float(model['mae']) if model['mae'] else None,
                    "first_prediction": model['first_prediction'].isoformat() if model['first_prediction'] else None,
                    "last_prediction": model['last_prediction'].isoformat() if model['last_prediction'] else None
                })
        
        # Format response based on metric_type
        response_data = {
            "status": "success",
            "analysis_period": {
                "start_date": result['earliest_date'].isoformat() if result['earliest_date'] else None,
                "end_date": result['latest_date'].isoformat() if result['latest_date'] else None,
                "total_predictions": result['total_predictions'],
                "models_analyzed": result['models_analyzed']
            },
            "accuracy_metrics": {},
            "filters_applied": {
                "start_date": start_date.isoformat() if start_date else None,
                "end_date": end_date.isoformat() if end_date else None,
                "model_id": model_id,
                "metric_type": metric_type
            }
        }
        
        # Add metrics based on requested type
        if metric_type in ['all', 'mape']:
            response_data["accuracy_metrics"]["mape"] = {
                "value": float(result['mape']) if result['mape'] else None,
                "description": "Mean Absolute Percentage Error",
                "interpretation": "Lower is better (< 10% is excellent, < 20% is good)"
            }
        
        if metric_type in ['all', 'rmse']:
            response_data["accuracy_metrics"]["rmse"] = {
                "value": float(result['rmse']) if result['rmse'] else None,
                "description": "Root Mean Square Error",
                "interpretation": "Lower is better (units match predicted values)"
            }
        
        if metric_type in ['all', 'mae']:
            response_data["accuracy_metrics"]["mae"] = {
                "value": float(result['mae']) if result['mae'] else None,
                "description": "Mean Absolute Error", 
                "interpretation": "Lower is better (units match predicted values)"
            }
        
        if metric_type == 'all':
            response_data["accuracy_metrics"]["overall_accuracy"] = {
                "value": float(result['avg_accuracy_percentage']) if result['avg_accuracy_percentage'] else None,
                "description": "Average Accuracy Percentage",
                "interpretation": "Higher is better (> 80% is good, > 90% is excellent)"
            }
            
            response_data["statistical_summary"] = {
                "standard_deviation": float(result['accuracy_std_dev']) if result['accuracy_std_dev'] else None,
                "median_error": float(result['median_error']) if result['median_error'] else None,
                "max_error": float(result['max_error']) if result['max_error'] else None,
                "min_error": float(result['min_error']) if result['min_error'] else None
            }
            
            if model_breakdown:
                response_data["model_breakdown"] = model_breakdown
        
        cur.close()
        conn.close()
        
        return response_data
        
    except psycopg2.Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")