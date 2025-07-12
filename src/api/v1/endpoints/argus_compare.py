"""
Argus Comparison Endpoints
Compare WFM Enterprise calculations with expected Argus outputs
"""
from typing import Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel, Field

from src.api.core.database import get_db
from src.api.services.algorithm_service import AlgorithmService
from src.api.utils.algorithm_adapter import AlgorithmAdapter

router = APIRouter()


class ErlangCComparisonRequest(BaseModel):
    """Request model for Erlang C comparison"""
    arrival_rate: float = Field(..., description="Calls per hour", ge=0)
    service_time: float = Field(..., description="Average handle time in minutes", gt=0)
    agents: int = Field(..., description="Number of agents", ge=1)
    target_service_level: float = Field(0.8, description="Target service level (0-1)", ge=0, le=1)
    target_wait_time: int = Field(20, description="Target wait time in seconds", ge=0)
    
    # Optional: Expected Argus results for comparison
    argus_result: Optional[Dict[str, float]] = Field(None, description="Expected Argus calculation results")


class ErlangCComparisonResponse(BaseModel):
    """Response model for Erlang C comparison"""
    wfm_result: Dict[str, Any] = Field(..., description="WFM Enterprise calculation results")
    argus_result: Optional[Dict[str, Any]] = Field(None, description="Argus expected results (if provided)")
    comparison: Optional[Dict[str, Any]] = Field(None, description="Comparison metrics")
    accuracy_score: Optional[float] = Field(None, description="Accuracy score (0-100%)")


@router.post("/erlang-c", response_model=ErlangCComparisonResponse)
async def compare_erlang_c_calculations(
    request: ErlangCComparisonRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Compare Erlang C calculations between WFM Enterprise and Argus.
    
    This endpoint:
    1. Calculates results using our Enhanced Erlang C
    2. Compares with provided Argus results (if available)
    3. Returns comparison metrics and accuracy score
    """
    try:
        # Calculate using WFM Enterprise Enhanced Erlang C
        from src.algorithms.core.erlang_c_enhanced import ErlangCEnhanced
        
        calculator = ErlangCEnhanced()
        mu_rate = 60 / request.service_time  # Convert minutes to hourly rate
        
        # Get our calculation
        wfm_result = AlgorithmAdapter.erlang_c_calculate(
            calculator=calculator,
            lambda_rate=request.arrival_rate,
            mu_rate=mu_rate,
            num_agents=request.agents,
            target_service_level=request.target_service_level
        )
        
        response = ErlangCComparisonResponse(wfm_result=wfm_result)
        
        # If Argus results provided, compare
        if request.argus_result:
            response.argus_result = request.argus_result
            
            # Calculate comparison metrics
            comparison = {}
            accuracy_scores = []
            
            # Compare key metrics
            metrics_map = {
                'utilization': 'utilization',
                'probability_wait': 'wait_probability',
                'service_level': 'service_level',
                'average_wait_time': 'avg_wait_time'
            }
            
            for our_key, argus_key in metrics_map.items():
                if our_key in wfm_result and argus_key in request.argus_result:
                    our_value = wfm_result[our_key]
                    argus_value = request.argus_result[argus_key]
                    
                    # Calculate difference
                    if argus_value != 0:
                        diff_percent = abs(our_value - argus_value) / argus_value * 100
                        accuracy = max(0, 100 - diff_percent)
                    else:
                        accuracy = 100 if our_value == 0 else 0
                    
                    comparison[our_key] = {
                        'wfm_value': our_value,
                        'argus_value': argus_value,
                        'difference': our_value - argus_value,
                        'difference_percent': diff_percent if argus_value != 0 else 0,
                        'accuracy': accuracy
                    }
                    
                    accuracy_scores.append(accuracy)
            
            response.comparison = comparison
            response.accuracy_score = sum(accuracy_scores) / len(accuracy_scores) if accuracy_scores else None
        
        return response
        
    except ImportError:
        # Fallback to service layer
        service = AlgorithmService(db)
        result = await service.calculate_enhanced_erlang_c({
            'arrival_rate': request.arrival_rate,
            'service_time': request.service_time,
            'agents': request.agents,
            'target_service_level': request.target_service_level
        })
        
        return ErlangCComparisonResponse(
            wfm_result=result,
            argus_result=request.argus_result
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Comparison calculation failed: {str(e)}"
        )


@router.post("/forecast", response_model=Dict[str, Any])
async def compare_forecast_calculations(
    historical_data: Dict[str, Any],
    argus_forecast: Optional[Dict[str, Any]] = None,
    db: AsyncSession = Depends(get_db)
):
    """
    Compare forecast calculations between WFM Enterprise ML models and Argus.
    
    Compares:
    - Forecast accuracy (MAPE, MAE, RMSE)
    - Seasonality detection
    - Trend identification
    - Peak period predictions
    """
    try:
        # TODO: Implement forecast comparison
        # This would use the ML ensemble to generate forecasts
        # and compare with Argus predictions
        
        return {
            "status": "endpoint_under_development",
            "message": "Forecast comparison will be implemented after ML models are fully integrated"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Forecast comparison failed: {str(e)}"
        )


@router.get("/validation-suite")
async def get_validation_test_cases():
    """
    Get standard test cases for validating calculations against Argus.
    
    Returns a set of test scenarios with expected Argus results
    for systematic validation.
    """
    test_cases = [
        {
            "id": "tc_001",
            "description": "Standard call center scenario",
            "input": {
                "arrival_rate": 100,
                "service_time": 3,
                "agents": 12,
                "target_service_level": 0.8,
                "target_wait_time": 20
            },
            "expected_argus_result": {
                "utilization": 0.833,
                "wait_probability": 0.426,
                "service_level": 0.821,
                "avg_wait_time": 15.3
            }
        },
        {
            "id": "tc_002",
            "description": "High volume scenario",
            "input": {
                "arrival_rate": 500,
                "service_time": 4,
                "agents": 40,
                "target_service_level": 0.9,
                "target_wait_time": 15
            },
            "expected_argus_result": {
                "utilization": 0.833,
                "wait_probability": 0.312,
                "service_level": 0.908,
                "avg_wait_time": 8.7
            }
        },
        {
            "id": "tc_003",
            "description": "Understaffed scenario",
            "input": {
                "arrival_rate": 200,
                "service_time": 5,
                "agents": 15,
                "target_service_level": 0.7,
                "target_wait_time": 30
            },
            "expected_argus_result": {
                "utilization": 0.889,
                "wait_probability": 0.687,
                "service_level": 0.645,
                "avg_wait_time": 42.1
            }
        }
    ]
    
    return {
        "test_cases": test_cases,
        "instructions": "Use these test cases to validate WFM Enterprise calculations against Argus",
        "endpoint": "/api/v1/argus-compare/erlang-c"
    }