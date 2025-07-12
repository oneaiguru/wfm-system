"""
Planning Calculations Endpoints (6 endpoints)
- POST /api/v1/planning/calculate-staffing (Staffing needs)
- POST /api/v1/planning/erlang-c (Erlang C calc)
- POST /api/v1/planning/multi-skill (Multi-skill opt)
- POST /api/v1/planning/scenarios (What-if analysis)
- GET /api/v1/planning/recommendations (AI suggestions)
- POST /api/v1/planning/validate (Validate plan)
"""

from typing import List, Dict, Any, Optional
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import asyncio

from ....core.database import get_db
from ...auth.dependencies import get_current_user, require_permissions
from ....db.models import Forecast, StaffingPlan, StaffingRequirement, User, Department
from ....services.forecasting_service import ForecastingService
from ....algorithms.core.erlang_c_enhanced import ErlangCEnhanced
from ....algorithms.optimization.multi_skill_allocation import MultiSkillAllocator
from ....websocket.handlers.forecast_handlers import ForecastWebSocketHandler
from ...schemas.forecasting import (
    StaffingCalculation, ErlangCCalculation, ErlangCResponse,
    MultiSkillOptimization, StaffingPlanCreate, StaffingPlanResponse,
    PlanValidation, PlanningRecommendations, RecommendationResponse
)

router = APIRouter(prefix="/planning", tags=["planning"])


@router.post("/calculate-staffing", response_model=StaffingPlanResponse)
async def calculate_staffing_requirements(
    staffing_request: StaffingCalculation,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_permissions(["planning.calculate"])),
    db: Session = Depends(get_db)
):
    """
    Calculate comprehensive staffing requirements from forecast.
    
    Features:
    - Erlang C calculations with multi-skill optimization
    - Service level and occupancy targets
    - Shrinkage factor integration
    - Cost estimation and optimization
    - FTE and headcount planning
    """
    try:
        # Validate forecast exists
        forecast = db.query(Forecast).filter(Forecast.id == staffing_request.forecast_id).first()
        
        if not forecast:
            raise HTTPException(status_code=404, detail="Forecast not found")
        
        # Organization check
        if not current_user.is_superuser and forecast.organization_id != current_user.organization_id:
            raise HTTPException(status_code=403, detail="Access denied")
        
        # Create staffing plan
        staffing_plan = StaffingPlan(
            name=f"Staffing Plan - {forecast.name}",
            description=f"Auto-generated staffing plan for forecast {forecast.name}",
            forecast_id=staffing_request.forecast_id,
            service_level_target=staffing_request.service_level_target,
            max_wait_time=staffing_request.max_wait_time,
            shrinkage_factor=staffing_request.shrinkage_factor,
            status="calculating",
            created_by=current_user.id
        )
        
        db.add(staffing_plan)
        db.commit()
        db.refresh(staffing_plan)
        
        # Start background calculation
        background_tasks.add_task(
            ForecastingService.calculate_staffing_requirements_background,
            staffing_plan.id,
            staffing_request.dict(),
            current_user.id
        )
        
        # WebSocket notification
        await ForecastWebSocketHandler.notify_staffing_calculation_started(staffing_plan.id)
        
        return StaffingPlanResponse.from_orm(staffing_plan)
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error calculating staffing requirements: {str(e)}"
        )


@router.post("/erlang-c", response_model=ErlangCResponse)
async def calculate_erlang_c(
    erlang_request: ErlangCCalculation,
    current_user: User = Depends(require_permissions(["planning.calculate"])),
    db: Session = Depends(get_db)
):
    """
    Enhanced Erlang C calculation with optimization.
    
    Features:
    - High-performance Erlang C calculations
    - Service level and wait time optimization
    - Occupancy and utilization metrics
    - Probability calculations
    - Multi-scenario analysis
    """
    try:
        # Initialize enhanced Erlang C calculator
        erlang_calculator = ErlangCEnhanced()
        
        # Perform calculation
        result = await erlang_calculator.calculate_optimal_staffing(
            arrival_rate=erlang_request.call_volume / 3600,  # Convert to calls per second
            service_time=erlang_request.average_handle_time,
            service_level_target=erlang_request.service_level_target,
            target_wait_time=erlang_request.max_wait_time
        )
        
        # Enhanced metrics calculation
        detailed_metrics = await erlang_calculator.calculate_detailed_metrics(
            agents=result['required_agents'],
            arrival_rate=erlang_request.call_volume / 3600,
            service_time=erlang_request.average_handle_time
        )
        
        response = ErlangCResponse(
            required_agents=result['required_agents'],
            service_level=result['service_level'],
            average_speed_to_answer=result['average_speed_to_answer'],
            occupancy=result['occupancy'],
            probability_of_wait=result['probability_of_wait'],
            calculations={
                "input_parameters": {
                    "call_volume_per_hour": erlang_request.call_volume,
                    "average_handle_time": erlang_request.average_handle_time,
                    "service_level_target": erlang_request.service_level_target,
                    "max_wait_time": erlang_request.max_wait_time
                },
                "traffic_intensity": result['traffic_intensity'],
                "detailed_metrics": detailed_metrics,
                "calculation_method": "enhanced_erlang_c",
                "calculated_at": datetime.utcnow().isoformat()
            }
        )
        
        return response
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error calculating Erlang C: {str(e)}"
        )


@router.post("/multi-skill")
async def optimize_multi_skill_allocation(
    multi_skill_request: MultiSkillOptimization,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_permissions(["planning.calculate"])),
    db: Session = Depends(get_db)
):
    """
    Multi-skill agent allocation optimization.
    
    Features:
    - Cross-skilled agent optimization
    - Multiple queue management
    - Skill-based routing optimization
    - Dynamic allocation strategies
    - Cost-efficiency analysis
    """
    try:
        # Initialize multi-skill allocator
        allocator = MultiSkillAllocator()
        
        # Prepare optimization data
        optimization_data = {
            "forecast_data": multi_skill_request.forecast_data,
            "skill_matrix": multi_skill_request.skill_matrix,
            "service_level_targets": multi_skill_request.service_level_targets,
            "max_wait_times": multi_skill_request.max_wait_times,
            "optimization_method": "genetic_algorithm"
        }
        
        # Perform optimization
        optimization_result = await allocator.optimize_allocation(optimization_data)
        
        # Calculate cost impact
        cost_analysis = await allocator.calculate_cost_impact(
            optimization_result,
            multi_skill_request.skill_matrix
        )
        
        # Performance metrics
        performance_metrics = await allocator.calculate_performance_metrics(
            optimization_result,
            multi_skill_request.service_level_targets
        )
        
        return {
            "optimization_result": optimization_result,
            "cost_analysis": cost_analysis,
            "performance_metrics": performance_metrics,
            "skill_utilization": optimization_result.get("skill_utilization"),
            "recommended_allocation": optimization_result.get("recommended_allocation"),
            "efficiency_gain": optimization_result.get("efficiency_gain"),
            "optimized_at": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error optimizing multi-skill allocation: {str(e)}"
        )


@router.post("/scenarios")
async def run_planning_scenarios(
    scenarios: List[Dict[str, Any]],
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_permissions(["planning.calculate"])),
    db: Session = Depends(get_db)
):
    """
    Run multiple planning scenarios for what-if analysis.
    
    Features:
    - Multiple scenario comparison
    - Sensitivity analysis
    - Risk assessment
    - Cost-benefit analysis
    - Decision support metrics
    """
    try:
        if len(scenarios) > 10:
            raise HTTPException(
                status_code=400,
                detail="Maximum 10 scenarios allowed per request"
            )
        
        # Process scenarios
        scenario_results = []
        
        for i, scenario in enumerate(scenarios):
            try:
                # Validate scenario structure
                required_fields = ['name', 'parameters', 'forecast_id']
                for field in required_fields:
                    if field not in scenario:
                        raise ValueError(f"Missing required field: {field}")
                
                # Run scenario calculation
                scenario_result = await ForecastingService.run_planning_scenario(
                    scenario,
                    current_user.id,
                    db
                )
                
                scenario_results.append({
                    "scenario_index": i,
                    "scenario_name": scenario['name'],
                    "result": scenario_result,
                    "status": "completed"
                })
                
            except Exception as e:
                scenario_results.append({
                    "scenario_index": i,
                    "scenario_name": scenario.get('name', f'Scenario {i}'),
                    "error": str(e),
                    "status": "failed"
                })
        
        # Compare scenarios
        comparison_analysis = await ForecastingService.compare_scenarios(scenario_results)
        
        return {
            "scenario_results": scenario_results,
            "comparison_analysis": comparison_analysis,
            "total_scenarios": len(scenarios),
            "successful_scenarios": len([r for r in scenario_results if r['status'] == 'completed']),
            "failed_scenarios": len([r for r in scenario_results if r['status'] == 'failed']),
            "analyzed_at": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error running planning scenarios: {str(e)}"
        )


@router.get("/recommendations", response_model=RecommendationResponse)
async def get_planning_recommendations(
    department_id: UUID,
    forecast_id: UUID,
    optimization_goals: List[str] = Query(["minimize_cost", "maximize_service_level"]),
    current_user: User = Depends(require_permissions(["planning.read"])),
    db: Session = Depends(get_db)
):
    """
    AI-powered planning recommendations.
    
    Features:
    - Machine learning-based recommendations
    - Historical pattern analysis
    - Optimization goal alignment
    - Risk assessment
    - Implementation roadmap
    """
    try:
        # Validate forecast and department
        forecast = db.query(Forecast).filter(Forecast.id == forecast_id).first()
        department = db.query(Department).filter(Department.id == department_id).first()
        
        if not forecast:
            raise HTTPException(status_code=404, detail="Forecast not found")
        
        if not department:
            raise HTTPException(status_code=404, detail="Department not found")
        
        # Organization check
        if not current_user.is_superuser:
            if forecast.organization_id != current_user.organization_id:
                raise HTTPException(status_code=403, detail="Access denied")
        
        # Generate recommendations
        service = ForecastingService(db)
        recommendations = await service.generate_ai_recommendations(
            department_id=department_id,
            forecast_id=forecast_id,
            optimization_goals=optimization_goals,
            user_context=current_user.dict()
        )
        
        return RecommendationResponse(
            recommendations=recommendations['recommendations'],
            analysis=recommendations['analysis'],
            confidence_score=recommendations['confidence_score'],
            generated_at=datetime.utcnow()
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error generating planning recommendations: {str(e)}"
        )


@router.post("/validate")
async def validate_staffing_plan(
    validation_request: PlanValidation,
    current_user: User = Depends(require_permissions(["planning.calculate"])),
    db: Session = Depends(get_db)
):
    """
    Validate staffing plan feasibility and compliance.
    
    Features:
    - Feasibility analysis
    - Cost validation
    - Compliance checking
    - Risk assessment
    - Implementation recommendations
    """
    try:
        # Validate staffing plan exists
        staffing_plan = db.query(StaffingPlan).filter(
            StaffingPlan.id == validation_request.staffing_plan_id
        ).first()
        
        if not staffing_plan:
            raise HTTPException(status_code=404, detail="Staffing plan not found")
        
        # Organization check
        if not current_user.is_superuser:
            forecast = db.query(Forecast).filter(Forecast.id == staffing_plan.forecast_id).first()
            if forecast and forecast.organization_id != current_user.organization_id:
                raise HTTPException(status_code=403, detail="Access denied")
        
        # Perform validation
        service = ForecastingService(db)
        validation_result = await service.validate_staffing_plan(
            staffing_plan.id,
            validation_request.validation_type,
            validation_request.parameters
        )
        
        return {
            "staffing_plan_id": str(validation_request.staffing_plan_id),
            "validation_type": validation_request.validation_type,
            "validation_result": validation_result,
            "is_valid": validation_result['overall_validity'],
            "validation_score": validation_result['validation_score'],
            "recommendations": validation_result['recommendations'],
            "validated_at": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error validating staffing plan: {str(e)}"
        )


@router.get("/staffing-plans")
async def list_staffing_plans(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    department_id: Optional[UUID] = Query(None),
    forecast_id: Optional[UUID] = Query(None),
    status: Optional[str] = Query(None),
    current_user: User = Depends(require_permissions(["planning.read"])),
    db: Session = Depends(get_db)
):
    """
    List staffing plans with filtering options.
    """
    try:
        query = db.query(StaffingPlan)
        
        # Apply filters
        if department_id:
            query = query.filter(StaffingPlan.department_id == department_id)
        
        if forecast_id:
            query = query.filter(StaffingPlan.forecast_id == forecast_id)
        
        if status:
            query = query.filter(StaffingPlan.status == status)
        
        # Organization isolation
        if not current_user.is_superuser:
            # Join with forecast to check organization
            query = query.join(Forecast).filter(
                Forecast.organization_id == current_user.organization_id
            )
        
        # Get total count
        total = query.count()
        
        # Apply pagination
        staffing_plans = query.offset(skip).limit(limit).all()
        
        return {
            "staffing_plans": [StaffingPlanResponse.from_orm(plan) for plan in staffing_plans],
            "total": total,
            "skip": skip,
            "limit": limit,
            "has_next": skip + limit < total,
            "has_previous": skip > 0
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error listing staffing plans: {str(e)}"
        )


@router.get("/staffing-plans/{plan_id}", response_model=StaffingPlanResponse)
async def get_staffing_plan(
    plan_id: UUID,
    include_requirements: bool = Query(False),
    current_user: User = Depends(require_permissions(["planning.read"])),
    db: Session = Depends(get_db)
):
    """
    Get specific staffing plan with optional requirements.
    """
    try:
        staffing_plan = db.query(StaffingPlan).filter(StaffingPlan.id == plan_id).first()
        
        if not staffing_plan:
            raise HTTPException(status_code=404, detail="Staffing plan not found")
        
        # Organization check
        if not current_user.is_superuser:
            forecast = db.query(Forecast).filter(Forecast.id == staffing_plan.forecast_id).first()
            if forecast and forecast.organization_id != current_user.organization_id:
                raise HTTPException(status_code=403, detail="Access denied")
        
        response_data = StaffingPlanResponse.from_orm(staffing_plan)
        
        # Include requirements if requested
        if include_requirements:
            requirements = db.query(StaffingRequirement).filter(
                StaffingRequirement.staffing_plan_id == plan_id
            ).order_by(StaffingRequirement.timestamp).all()
            
            response_data.requirements = [
                {
                    "timestamp": req.timestamp,
                    "required_staff": req.required_staff,
                    "skill_requirements": req.skill_requirements,
                    "call_volume": req.call_volume,
                    "average_handle_time": req.average_handle_time,
                    "service_level": req.service_level,
                    "occupancy": req.occupancy
                }
                for req in requirements
            ]
        
        return response_data
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving staffing plan: {str(e)}"
        )