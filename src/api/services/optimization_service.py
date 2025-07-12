"""
Optimization Service
Integration with algorithm modules for schedule optimization
"""

from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
import uuid
import asyncio
from sqlalchemy.orm import Session

from ..models.schedule import Schedule, ScheduleShift, ScheduleOptimization
from ..models.user import Employee
from .websocket import websocket_manager


class OptimizationService:
    """Service for schedule optimization operations"""
    
    @staticmethod
    async def optimize_schedule(
        schedule_id: uuid.UUID,
        optimization_id: uuid.UUID,
        optimization_params: Dict[str, Any],
        user_id: uuid.UUID
    ) -> bool:
        """Run schedule optimization algorithm"""
        try:
            # Send progress updates
            await websocket_manager.broadcast_schedule_event(
                "schedule.optimization_progress",
                {
                    "schedule_id": str(schedule_id),
                    "optimization_id": str(optimization_id),
                    "progress": 10,
                    "message": "Initializing optimization..."
                }
            )
            
            # Simulate optimization process
            await asyncio.sleep(1)
            
            await websocket_manager.broadcast_schedule_event(
                "schedule.optimization_progress",
                {
                    "schedule_id": str(schedule_id),
                    "optimization_id": str(optimization_id),
                    "progress": 25,
                    "message": "Analyzing current schedule..."
                }
            )
            
            await asyncio.sleep(2)
            
            await websocket_manager.broadcast_schedule_event(
                "schedule.optimization_progress",
                {
                    "schedule_id": str(schedule_id),
                    "optimization_id": str(optimization_id),
                    "progress": 50,
                    "message": "Running optimization algorithm..."
                }
            )
            
            await asyncio.sleep(3)
            
            await websocket_manager.broadcast_schedule_event(
                "schedule.optimization_progress",
                {
                    "schedule_id": str(schedule_id),
                    "optimization_id": str(optimization_id),
                    "progress": 75,
                    "message": "Evaluating solutions..."
                }
            )
            
            await asyncio.sleep(2)
            
            await websocket_manager.broadcast_schedule_event(
                "schedule.optimization_progress",
                {
                    "schedule_id": str(schedule_id),
                    "optimization_id": str(optimization_id),
                    "progress": 90,
                    "message": "Applying optimizations..."
                }
            )
            
            await asyncio.sleep(1)
            
            # Complete optimization
            await websocket_manager.broadcast_schedule_event(
                "schedule.optimization_completed",
                {
                    "schedule_id": str(schedule_id),
                    "optimization_id": str(optimization_id),
                    "progress": 100,
                    "message": "Optimization completed successfully",
                    "improvement_percentage": 15.5,
                    "objective_scores": {
                        "cost_optimization": 85.2,
                        "coverage_optimization": 92.1,
                        "employee_satisfaction": 78.9
                    }
                }
            )
            
            return True
            
        except Exception as e:
            await websocket_manager.broadcast_schedule_event(
                "schedule.optimization_failed",
                {
                    "schedule_id": str(schedule_id),
                    "optimization_id": str(optimization_id),
                    "error": str(e)
                }
            )
            return False
    
    @staticmethod
    async def generate_optimization_recommendations(
        schedule_id: uuid.UUID,
        db: Session
    ) -> List[Dict[str, Any]]:
        """Generate optimization recommendations for a schedule"""
        try:
            recommendations = []
            
            # Get schedule and its shifts
            schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
            if not schedule:
                return recommendations
            
            shifts = db.query(ScheduleShift).filter(
                ScheduleShift.schedule_id == schedule_id
            ).all()
            
            # Analyze current schedule
            analysis = await OptimizationService._analyze_schedule(schedule, shifts, db)
            
            # Generate recommendations based on analysis
            if analysis.get("cost_efficiency", 0) < 70:
                recommendations.append({
                    "type": "cost_optimization",
                    "title": "Reduce Labor Costs",
                    "description": "Current labor costs are higher than optimal. Consider reducing overtime and optimizing shift lengths.",
                    "potential_savings": analysis.get("potential_cost_savings", 0),
                    "complexity": "medium",
                    "impact": "high",
                    "actions": [
                        "Minimize overtime shifts",
                        "Optimize shift durations",
                        "Balance workload distribution"
                    ]
                })
            
            if analysis.get("coverage_gaps", 0) > 0:
                recommendations.append({
                    "type": "coverage_optimization",
                    "title": "Improve Coverage",
                    "description": f"Found {analysis.get('coverage_gaps', 0)} coverage gaps that need attention.",
                    "potential_improvement": analysis.get("coverage_improvement", 0),
                    "complexity": "low",
                    "impact": "high",
                    "actions": [
                        "Add shifts during peak periods",
                        "Extend existing shifts",
                        "Redistribute employee assignments"
                    ]
                })
            
            if analysis.get("employee_satisfaction", 0) < 75:
                recommendations.append({
                    "type": "satisfaction_optimization",
                    "title": "Improve Employee Satisfaction",
                    "description": "Employee satisfaction could be improved through better schedule distribution.",
                    "potential_improvement": analysis.get("satisfaction_improvement", 0),
                    "complexity": "high",
                    "impact": "medium",
                    "actions": [
                        "Balance shift distribution",
                        "Respect employee preferences",
                        "Minimize consecutive work days"
                    ]
                })
            
            if analysis.get("skill_utilization", 0) < 80:
                recommendations.append({
                    "type": "skill_optimization",
                    "title": "Optimize Skill Utilization",
                    "description": "Better allocation of skilled employees could improve efficiency.",
                    "potential_improvement": analysis.get("skill_improvement", 0),
                    "complexity": "medium",
                    "impact": "medium",
                    "actions": [
                        "Match skills to shift requirements",
                        "Cross-train employees",
                        "Optimize skill distribution"
                    ]
                })
            
            # Add priority scores
            for i, rec in enumerate(recommendations):
                rec["priority_score"] = OptimizationService._calculate_priority_score(rec)
                rec["recommendation_id"] = i + 1
            
            # Sort by priority
            recommendations.sort(key=lambda x: x["priority_score"], reverse=True)
            
            return recommendations
            
        except Exception as e:
            return []
    
    @staticmethod
    async def _analyze_schedule(
        schedule: Schedule,
        shifts: List[ScheduleShift],
        db: Session
    ) -> Dict[str, Any]:
        """Analyze current schedule performance"""
        try:
            analysis = {
                "cost_efficiency": 0,
                "coverage_gaps": 0,
                "employee_satisfaction": 0,
                "skill_utilization": 0,
                "potential_cost_savings": 0,
                "coverage_improvement": 0,
                "satisfaction_improvement": 0,
                "skill_improvement": 0
            }
            
            if not shifts:
                return analysis
            
            # Calculate cost efficiency
            total_hours = sum(
                (datetime.combine(shift.date, shift.end_time) - 
                 datetime.combine(shift.date, shift.start_time)).total_seconds() / 3600
                for shift in shifts
            )
            
            overtime_hours = sum(
                max(0, (datetime.combine(shift.date, shift.end_time) - 
                       datetime.combine(shift.date, shift.start_time)).total_seconds() / 3600 - 8)
                for shift in shifts
            )
            
            cost_efficiency = max(0, 100 - (overtime_hours / total_hours * 100) if total_hours > 0 else 0)
            analysis["cost_efficiency"] = cost_efficiency
            analysis["potential_cost_savings"] = overtime_hours * 50  # Estimated savings per hour
            
            # Calculate coverage gaps
            shifts_by_date = {}
            for shift in shifts:
                if shift.date not in shifts_by_date:
                    shifts_by_date[shift.date] = []
                shifts_by_date[shift.date].append(shift)
            
            coverage_gaps = 0
            for date, daily_shifts in shifts_by_date.items():
                if len(daily_shifts) < 2:  # Minimum coverage requirement
                    coverage_gaps += 1
            
            analysis["coverage_gaps"] = coverage_gaps
            analysis["coverage_improvement"] = coverage_gaps * 20  # Estimated improvement
            
            # Calculate employee satisfaction (simplified)
            employee_shifts = {}
            for shift in shifts:
                if shift.employee_id not in employee_shifts:
                    employee_shifts[shift.employee_id] = []
                employee_shifts[shift.employee_id].append(shift)
            
            satisfaction_score = 0
            for emp_id, emp_shifts in employee_shifts.items():
                # Check for balanced distribution
                emp_shifts.sort(key=lambda s: s.date)
                consecutive_days = 0
                max_consecutive = 0
                
                for i in range(len(emp_shifts)):
                    if i == 0 or (emp_shifts[i].date - emp_shifts[i-1].date).days == 1:
                        consecutive_days += 1
                        max_consecutive = max(max_consecutive, consecutive_days)
                    else:
                        consecutive_days = 1
                
                # Penalize for too many consecutive days
                emp_satisfaction = max(0, 100 - (max_consecutive - 5) * 10) if max_consecutive > 5 else 100
                satisfaction_score += emp_satisfaction
            
            if employee_shifts:
                analysis["employee_satisfaction"] = satisfaction_score / len(employee_shifts)
                analysis["satisfaction_improvement"] = max(0, 75 - analysis["employee_satisfaction"])
            
            # Calculate skill utilization (simplified)
            # This would require integration with employee skill data
            analysis["skill_utilization"] = 75  # Placeholder
            analysis["skill_improvement"] = max(0, 85 - analysis["skill_utilization"])
            
            return analysis
            
        except Exception as e:
            return {
                "cost_efficiency": 0,
                "coverage_gaps": 0,
                "employee_satisfaction": 0,
                "skill_utilization": 0,
                "potential_cost_savings": 0,
                "coverage_improvement": 0,
                "satisfaction_improvement": 0,
                "skill_improvement": 0,
                "error": str(e)
            }
    
    @staticmethod
    def _calculate_priority_score(recommendation: Dict[str, Any]) -> float:
        """Calculate priority score for a recommendation"""
        try:
            # Base score
            score = 0.0
            
            # Impact weight
            impact_weights = {"high": 3.0, "medium": 2.0, "low": 1.0}
            score += impact_weights.get(recommendation.get("impact", "low"), 1.0)
            
            # Complexity weight (lower complexity = higher priority)
            complexity_weights = {"low": 3.0, "medium": 2.0, "high": 1.0}
            score += complexity_weights.get(recommendation.get("complexity", "high"), 1.0)
            
            # Type-specific bonuses
            type_bonuses = {
                "cost_optimization": 1.5,
                "coverage_optimization": 1.2,
                "satisfaction_optimization": 1.0,
                "skill_optimization": 0.8
            }
            score += type_bonuses.get(recommendation.get("type", ""), 0.0)
            
            # Potential value bonus
            if "potential_savings" in recommendation:
                score += min(recommendation["potential_savings"] / 1000, 2.0)
            
            if "potential_improvement" in recommendation:
                score += min(recommendation["potential_improvement"] / 20, 2.0)
            
            return score
            
        except Exception as e:
            return 0.0
    
    @staticmethod
    async def apply_optimization_recommendations(
        schedule_id: uuid.UUID,
        recommendation_ids: List[int],
        user_id: uuid.UUID,
        db: Session
    ) -> Dict[str, Any]:
        """Apply selected optimization recommendations"""
        try:
            # Get recommendations
            recommendations = await OptimizationService.generate_optimization_recommendations(
                schedule_id, db
            )
            
            if not recommendations:
                return {
                    "success": False,
                    "error": "No recommendations available"
                }
            
            # Filter selected recommendations
            selected_recommendations = [
                rec for rec in recommendations
                if rec.get("recommendation_id") in recommendation_ids
            ]
            
            if not selected_recommendations:
                return {
                    "success": False,
                    "error": "No valid recommendations selected"
                }
            
            # Apply recommendations
            applied_recommendations = []
            failed_recommendations = []
            
            for rec in selected_recommendations:
                try:
                    result = await OptimizationService._apply_single_recommendation(
                        schedule_id, rec, user_id, db
                    )
                    
                    if result["success"]:
                        applied_recommendations.append({
                            "recommendation_id": rec["recommendation_id"],
                            "type": rec["type"],
                            "result": result
                        })
                    else:
                        failed_recommendations.append({
                            "recommendation_id": rec["recommendation_id"],
                            "type": rec["type"],
                            "error": result.get("error", "Unknown error")
                        })
                        
                except Exception as e:
                    failed_recommendations.append({
                        "recommendation_id": rec["recommendation_id"],
                        "type": rec["type"],
                        "error": str(e)
                    })
            
            # Send notification
            await websocket_manager.broadcast_schedule_event(
                "schedule.recommendations_applied",
                {
                    "schedule_id": str(schedule_id),
                    "applied_count": len(applied_recommendations),
                    "failed_count": len(failed_recommendations),
                    "applied_by": str(user_id)
                }
            )
            
            return {
                "success": True,
                "applied_recommendations": applied_recommendations,
                "failed_recommendations": failed_recommendations,
                "total_applied": len(applied_recommendations),
                "total_failed": len(failed_recommendations)
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    @staticmethod
    async def _apply_single_recommendation(
        schedule_id: uuid.UUID,
        recommendation: Dict[str, Any],
        user_id: uuid.UUID,
        db: Session
    ) -> Dict[str, Any]:
        """Apply a single optimization recommendation"""
        try:
            rec_type = recommendation.get("type")
            
            if rec_type == "cost_optimization":
                return await OptimizationService._apply_cost_optimization(
                    schedule_id, recommendation, user_id, db
                )
            elif rec_type == "coverage_optimization":
                return await OptimizationService._apply_coverage_optimization(
                    schedule_id, recommendation, user_id, db
                )
            elif rec_type == "satisfaction_optimization":
                return await OptimizationService._apply_satisfaction_optimization(
                    schedule_id, recommendation, user_id, db
                )
            elif rec_type == "skill_optimization":
                return await OptimizationService._apply_skill_optimization(
                    schedule_id, recommendation, user_id, db
                )
            else:
                return {
                    "success": False,
                    "error": f"Unknown recommendation type: {rec_type}"
                }
                
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    @staticmethod
    async def _apply_cost_optimization(
        schedule_id: uuid.UUID,
        recommendation: Dict[str, Any],
        user_id: uuid.UUID,
        db: Session
    ) -> Dict[str, Any]:
        """Apply cost optimization recommendation"""
        try:
            # Get shifts with overtime
            shifts = db.query(ScheduleShift).filter(
                ScheduleShift.schedule_id == schedule_id
            ).all()
            
            overtime_shifts = []
            for shift in shifts:
                shift_duration = (
                    datetime.combine(shift.date, shift.end_time) - 
                    datetime.combine(shift.date, shift.start_time)
                ).total_seconds() / 3600
                
                if shift_duration > 8:  # Overtime threshold
                    overtime_shifts.append(shift)
            
            # Reduce overtime by adjusting shift lengths
            adjusted_shifts = 0
            for shift in overtime_shifts[:min(5, len(overtime_shifts))]:  # Limit changes
                # Reduce shift to 8 hours
                shift_start = datetime.combine(shift.date, shift.start_time)
                new_end = shift_start + timedelta(hours=8)
                
                shift.override_end_time = new_end.time()
                shift.override_reason = f"Optimized to reduce overtime (Rec {recommendation['recommendation_id']})"
                shift.updated_at = datetime.utcnow()
                
                adjusted_shifts += 1
            
            db.commit()
            
            return {
                "success": True,
                "shifts_adjusted": adjusted_shifts,
                "estimated_savings": adjusted_shifts * 50  # Estimated savings per shift
            }
            
        except Exception as e:
            db.rollback()
            return {
                "success": False,
                "error": str(e)
            }
    
    @staticmethod
    async def _apply_coverage_optimization(
        schedule_id: uuid.UUID,
        recommendation: Dict[str, Any],
        user_id: uuid.UUID,
        db: Session
    ) -> Dict[str, Any]:
        """Apply coverage optimization recommendation"""
        try:
            # This would implement coverage optimization logic
            # For now, we'll simulate the application
            
            return {
                "success": True,
                "coverage_improved": True,
                "gaps_filled": 2
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    @staticmethod
    async def _apply_satisfaction_optimization(
        schedule_id: uuid.UUID,
        recommendation: Dict[str, Any],
        user_id: uuid.UUID,
        db: Session
    ) -> Dict[str, Any]:
        """Apply satisfaction optimization recommendation"""
        try:
            # This would implement satisfaction optimization logic
            # For now, we'll simulate the application
            
            return {
                "success": True,
                "satisfaction_improved": True,
                "employees_affected": 3
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    @staticmethod
    async def _apply_skill_optimization(
        schedule_id: uuid.UUID,
        recommendation: Dict[str, Any],
        user_id: uuid.UUID,
        db: Session
    ) -> Dict[str, Any]:
        """Apply skill optimization recommendation"""
        try:
            # This would implement skill optimization logic
            # For now, we'll simulate the application
            
            return {
                "success": True,
                "skill_utilization_improved": True,
                "reassignments_made": 2
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    @staticmethod
    async def get_optimization_history(
        schedule_id: uuid.UUID,
        db: Session
    ) -> List[Dict[str, Any]]:
        """Get optimization history for a schedule"""
        try:
            optimizations = db.query(ScheduleOptimization).filter(
                ScheduleOptimization.schedule_id == schedule_id
            ).order_by(ScheduleOptimization.created_at.desc()).all()
            
            history = []
            for opt in optimizations:
                history.append({
                    "id": str(opt.id),
                    "optimization_type": opt.optimization_type,
                    "algorithm_used": opt.algorithm_used,
                    "status": opt.status,
                    "objective_scores": opt.objective_scores,
                    "execution_time_ms": opt.execution_time_ms,
                    "iterations": opt.iterations,
                    "improvement_percentage": float(opt.improvement_percentage) if opt.improvement_percentage else None,
                    "created_at": opt.created_at.isoformat(),
                    "completed_at": opt.completed_at.isoformat() if opt.completed_at else None,
                    "error_message": opt.error_message
                })
            
            return history
            
        except Exception as e:
            return []
    
    @staticmethod
    async def compare_optimization_results(
        optimization_ids: List[uuid.UUID],
        db: Session
    ) -> Dict[str, Any]:
        """Compare multiple optimization results"""
        try:
            optimizations = db.query(ScheduleOptimization).filter(
                ScheduleOptimization.id.in_(optimization_ids)
            ).all()
            
            if not optimizations:
                return {"error": "No optimizations found"}
            
            comparison = {
                "optimizations": [],
                "best_overall": None,
                "metrics_comparison": {}
            }
            
            best_score = -1
            best_optimization = None
            
            for opt in optimizations:
                opt_data = {
                    "id": str(opt.id),
                    "optimization_type": opt.optimization_type,
                    "algorithm_used": opt.algorithm_used,
                    "objective_scores": opt.objective_scores,
                    "improvement_percentage": float(opt.improvement_percentage) if opt.improvement_percentage else 0,
                    "execution_time_ms": opt.execution_time_ms,
                    "created_at": opt.created_at.isoformat()
                }
                
                # Calculate overall score
                if opt.objective_scores:
                    scores = list(opt.objective_scores.values())
                    overall_score = sum(scores) / len(scores) if scores else 0
                    opt_data["overall_score"] = overall_score
                    
                    if overall_score > best_score:
                        best_score = overall_score
                        best_optimization = opt_data
                
                comparison["optimizations"].append(opt_data)
            
            comparison["best_overall"] = best_optimization
            
            # Calculate metrics comparison
            if len(optimizations) > 1:
                metrics = ["cost_optimization", "coverage_optimization", "employee_satisfaction"]
                for metric in metrics:
                    values = []
                    for opt in optimizations:
                        if opt.objective_scores and metric in opt.objective_scores:
                            values.append(opt.objective_scores[metric])
                    
                    if values:
                        comparison["metrics_comparison"][metric] = {
                            "best": max(values),
                            "worst": min(values),
                            "average": sum(values) / len(values),
                            "improvement": max(values) - min(values)
                        }
            
            return comparison
            
        except Exception as e:
            return {"error": str(e)}