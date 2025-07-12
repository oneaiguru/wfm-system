"""
What-if Analysis Endpoints (3 endpoints)
- POST /api/v1/scenarios/create (Create scenario)
- POST /api/v1/scenarios/compare (Compare scenarios)
- GET /api/v1/scenarios/results (Get results)
"""

from typing import List, Dict, Any, Optional
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from sqlalchemy.orm import Session
from datetime import datetime
import asyncio
import json

from ....core.database import get_db
from ...auth.dependencies import get_current_user, require_permissions
from ....db.models import ForecastScenario, Forecast, User
from ....services.forecasting_service import ForecastingService
from ....algorithms.core.erlang_c_enhanced import ErlangCEnhanced
from ....websocket.handlers.forecast_handlers import ForecastWebSocketHandler
from ...schemas.forecasting import (
    ScenarioAnalysis, ScenarioComparison, ScenarioResponse, PaginatedResponse
)

router = APIRouter(prefix="/scenarios", tags=["scenarios"])


@router.post("/create", response_model=ScenarioResponse)
async def create_scenario(
    scenario_request: ScenarioAnalysis,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_permissions(["scenarios.create"])),
    db: Session = Depends(get_db)
):
    """
    Create and analyze a what-if scenario.
    
    Features:
    - Multiple scenario types (what-if, sensitivity, stress testing)
    - Parameter variation analysis
    - Impact assessment on staffing and costs
    - Comparison with baseline forecast
    - Risk analysis and probability assessment
    """
    try:
        # Validate base forecast exists
        base_forecast = db.query(Forecast).filter(
            Forecast.id == scenario_request.base_forecast_id
        ).first()
        
        if not base_forecast:
            raise HTTPException(status_code=404, detail="Base forecast not found")
        
        # Organization check
        if not current_user.is_superuser and base_forecast.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Validate scenario parameters
        required_params = ['forecast_adjustment', 'staffing_parameters']
        for param in required_params:
            if param not in scenario_request.parameters:
                raise HTTPException(
                    status_code=400,
                    detail=f"Missing required parameter: {param}"
                )
        
        # Create scenario record
        scenario = ForecastScenario(
            name=scenario_request.name,
            scenario_type=scenario_request.scenario_type,
            forecast_id=scenario_request.base_forecast_id,
            parameters=scenario_request.parameters,
            created_by=current_user.id
        )
        
        db.add(scenario)
        db.commit()
        db.refresh(scenario)
        
        # Start background scenario analysis
        background_tasks.add_task(
            ForecastingService.analyze_scenario_background,
            scenario.id,
            scenario_request.dict(),
            current_user.id
        )
        
        # WebSocket notification
        await ForecastWebSocketHandler.notify_scenario_created(scenario.id)
        
        return ScenarioResponse.from_orm(scenario)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error creating scenario: {str(e)}"
        )


@router.post("/compare")
async def compare_scenarios(
    comparison_request: ScenarioComparison,
    current_user: User = Depends(require_permissions(["scenarios.read"])),
    db: Session = Depends(get_db)
):
    """
    Compare multiple scenarios for decision making.
    
    Features:
    - Side-by-side comparison of up to 5 scenarios
    - Multiple comparison metrics (staffing, cost, service level)
    - Statistical significance testing
    - Risk assessment and probability analysis
    - Decision recommendation engine
    """
    try:
        # Validate all scenarios exist and user has access
        scenarios = db.query(ForecastScenario).filter(
            ForecastScenario.id.in_(comparison_request.scenario_ids)
        ).all()
        
        if len(scenarios) != len(comparison_request.scenario_ids):
            raise HTTPException(
                status_code=404,
                detail="One or more scenarios not found"
            )
        
        # Organization check
        if not current_user.is_superuser:
            for scenario in scenarios:
                forecast = db.query(Forecast).filter(Forecast.id == scenario.forecast_id).first()
                if forecast and forecast.organization_id != current_user.organization_id:
                    raise HTTPException(status_code=403, detail="Access denied")
        
        # Perform detailed comparison
        service = ForecastingService(db)
        comparison_result = await service.compare_scenarios_detailed(
            scenario_ids=comparison_request.scenario_ids,
            metrics=comparison_request.comparison_metrics
        )
        
        # Generate decision recommendations
        decision_analysis = await service.generate_scenario_decision_analysis(
            scenarios=scenarios,
            comparison_result=comparison_result
        )
        
        # Risk assessment
        risk_analysis = await service.calculate_scenario_risks(
            scenarios=scenarios,
            comparison_result=comparison_result
        )
        
        return {
            "comparison_result": comparison_result,
            "decision_analysis": decision_analysis,
            "risk_analysis": risk_analysis,
            "scenarios_compared": len(comparison_request.scenario_ids),
            "comparison_metrics": comparison_request.comparison_metrics,
            "recommended_scenario": decision_analysis.get("recommended_scenario_id"),
            "confidence_level": decision_analysis.get("confidence_level"),
            "compared_at": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error comparing scenarios: {str(e)}"
        )


@router.get("/results")
async def get_scenario_results(
    scenario_id: Optional[UUID] = Query(None),
    forecast_id: Optional[UUID] = Query(None),
    scenario_type: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    current_user: User = Depends(require_permissions(["scenarios.read"])),
    db: Session = Depends(get_db)
):
    """
    Get scenario results with filtering options.
    
    Features:
    - Filter by scenario ID, forecast ID, or scenario type
    - Pagination support
    - Detailed results with impact analysis
    - Performance metrics and comparisons
    """
    try:
        query = db.query(ForecastScenario)
        
        # Apply filters
        if scenario_id:
            query = query.filter(ForecastScenario.id == scenario_id)
        
        if forecast_id:
            query = query.filter(ForecastScenario.forecast_id == forecast_id)
        
        if scenario_type:
            query = query.filter(ForecastScenario.scenario_type == scenario_type)
        
        # Organization isolation
        if not current_user.is_superuser:
            query = query.join(Forecast).filter(
                Forecast.organization_id == current_user.organization_id
            )
        
        # Order by creation date (newest first)
        query = query.order_by(ForecastScenario.created_at.desc())
        
        # Get total count
        total = query.count()
        
        # Apply pagination
        scenarios = query.offset(skip).limit(limit).all()
        
        # Format detailed results
        detailed_results = []
        for scenario in scenarios:
            scenario_data = ScenarioResponse.from_orm(scenario)
            
            # Enhance with additional analysis if available
            if scenario.results:
                # Calculate summary metrics
                service = ForecastingService(db)
                summary_metrics = await service.calculate_scenario_summary_metrics(scenario.id)
                
                scenario_data.summary_metrics = summary_metrics
                scenario_data.impact_score = summary_metrics.get("impact_score")
                scenario_data.feasibility_score = summary_metrics.get("feasibility_score")
            
            detailed_results.append(scenario_data.dict())
        
        return PaginatedResponse(
            items=detailed_results,
            total=total,
            skip=skip,
            limit=limit,
            has_next=skip + limit < total,
            has_previous=skip > 0
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving scenario results: {str(e)}"
        )


@router.get("/{scenario_id}", response_model=ScenarioResponse)
async def get_scenario(
    scenario_id: UUID,
    include_detailed_results: bool = Query(False),
    current_user: User = Depends(require_permissions(["scenarios.read"])),
    db: Session = Depends(get_db)
):
    """
    Get specific scenario with detailed results.
    
    Features:
    - Complete scenario configuration
    - Detailed analysis results
    - Impact assessment
    - Comparison with baseline
    """
    try:
        scenario = db.query(ForecastScenario).filter(
            ForecastScenario.id == scenario_id
        ).first()
        
        if not scenario:
            raise HTTPException(status_code=404, detail="Scenario not found")
        
        # Organization check
        if not current_user.is_superuser:
            forecast = db.query(Forecast).filter(Forecast.id == scenario.forecast_id).first()
            if forecast and forecast.organization_id != current_user.organization_id:
                raise HTTPException(status_code=403, detail="Access denied")
        
        response_data = ScenarioResponse.from_orm(scenario)
        
        # Include detailed results if requested
        if include_detailed_results and scenario.results:
            service = ForecastingService(db)
            
            # Get detailed analysis
            detailed_analysis = await service.get_scenario_detailed_analysis(scenario_id)
            response_data.detailed_analysis = detailed_analysis
            
            # Get comparison with baseline
            baseline_comparison = await service.compare_scenario_with_baseline(scenario_id)
            response_data.baseline_comparison = baseline_comparison
        
        return response_data
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving scenario: {str(e)}"
        )


@router.put("/{scenario_id}")
async def update_scenario(
    scenario_id: UUID,
    scenario_updates: Dict[str, Any],
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_permissions(["scenarios.write"])),
    db: Session = Depends(get_db)
):
    """
    Update scenario parameters and re-run analysis.
    """
    try:
        scenario = db.query(ForecastScenario).filter(
            ForecastScenario.id == scenario_id
        ).first()
        
        if not scenario:
            raise HTTPException(status_code=404, detail="Scenario not found")
        
        # Organization check
        if not current_user.is_superuser:
            forecast = db.query(Forecast).filter(Forecast.id == scenario.forecast_id).first()
            if forecast and forecast.organization_id != current_user.organization_id:
                raise HTTPException(status_code=403, detail="Access denied")
        
        # Update scenario
        for field, value in scenario_updates.items():
            if field in ['name', 'parameters', 'scenario_type']:
                setattr(scenario, field, value)
        
        db.commit()
        
        # Re-run analysis if parameters changed
        if 'parameters' in scenario_updates:
            background_tasks.add_task(
                ForecastingService.reanalyze_scenario_background,
                scenario_id,
                current_user.id
            )
        
        return {
            "scenario_id": str(scenario_id),
            "updated_fields": list(scenario_updates.keys()),
            "reanalysis_started": 'parameters' in scenario_updates,
            "updated_at": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error updating scenario: {str(e)}"
        )


@router.delete("/{scenario_id}")
async def delete_scenario(
    scenario_id: UUID,
    current_user: User = Depends(require_permissions(["scenarios.delete"])),
    db: Session = Depends(get_db)
):
    """
    Delete scenario and associated results.
    """
    try:
        scenario = db.query(ForecastScenario).filter(
            ForecastScenario.id == scenario_id
        ).first()
        
        if not scenario:
            raise HTTPException(status_code=404, detail="Scenario not found")
        
        # Organization check
        if not current_user.is_superuser:
            forecast = db.query(Forecast).filter(Forecast.id == scenario.forecast_id).first()
            if forecast and forecast.organization_id != current_user.organization_id:
                raise HTTPException(status_code=403, detail="Access denied")
        
        # Delete scenario
        db.delete(scenario)
        db.commit()
        
        return {
            "message": "Scenario deleted successfully",
            "scenario_id": str(scenario_id),
            "deleted_at": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error deleting scenario: {str(e)}"
        )


@router.post("/batch-analysis")
async def run_batch_scenario_analysis(
    scenarios: List[Dict[str, Any]],
    analysis_type: str = "comprehensive",
    background_tasks: BackgroundTasks = None,
    current_user: User = Depends(require_permissions(["scenarios.create"])),
    db: Session = Depends(get_db)
):
    """
    Run batch scenario analysis for multiple scenarios.
    
    Features:
    - Process multiple scenarios simultaneously
    - Comprehensive analysis including risks and opportunities
    - Parallel processing for performance
    - Consolidated reporting
    """
    try:
        if len(scenarios) > 20:
            raise HTTPException(
                status_code=400,
                detail="Maximum 20 scenarios allowed per batch"
            )
        
        # Validate all scenarios
        for i, scenario in enumerate(scenarios):
            required_fields = ['name', 'scenario_type', 'base_forecast_id', 'parameters']
            for field in required_fields:
                if field not in scenario:
                    raise HTTPException(
                        status_code=400,
                        detail=f"Missing required field '{field}' in scenario {i}"
                    )
        
        # Create batch analysis task
        batch_id = str(UUID.uuid4())
        
        background_tasks.add_task(
            ForecastingService.run_batch_scenario_analysis,
            batch_id,
            scenarios,
            analysis_type,
            current_user.id
        )
        
        return {
            "batch_id": batch_id,
            "total_scenarios": len(scenarios),
            "analysis_type": analysis_type,
            "status": "processing",
            "estimated_completion": datetime.utcnow().isoformat(),
            "started_at": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error starting batch scenario analysis: {str(e)}"
        )


@router.get("/batch-analysis/{batch_id}")
async def get_batch_analysis_status(
    batch_id: str,
    current_user: User = Depends(require_permissions(["scenarios.read"])),
    db: Session = Depends(get_db)
):
    """
    Get status of batch scenario analysis.
    """
    try:
        # Get batch analysis status
        service = ForecastingService(db)
        batch_status = await service.get_batch_analysis_status(batch_id)
        
        if not batch_status:
            raise HTTPException(status_code=404, detail="Batch analysis not found")
        
        return batch_status
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving batch analysis status: {str(e)}"
        )