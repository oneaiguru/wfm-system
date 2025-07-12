"""
Conflict Resolution Service
Business logic for resolving schedule conflicts
"""

from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
import uuid
from sqlalchemy.orm import Session

from ..models.schedule import (
    Schedule, ScheduleShift, ScheduleConflict, ScheduleRule, ScheduleConstraint
)
from ..models.user import Employee
from .websocket import websocket_manager


class ConflictResolutionResult:
    """Result of conflict resolution operation"""
    
    def __init__(self, success: bool, error_message: Optional[str] = None, details: Optional[Dict[str, Any]] = None):
        self.success = success
        self.error_message = error_message
        self.details = details or {}


class ConflictResolutionService:
    """Service for resolving schedule conflicts"""
    
    @staticmethod
    async def resolve_conflict(
        conflict_id: uuid.UUID,
        resolution_type: str,
        resolution_data: Dict[str, Any],
        apply_immediately: bool,
        user_id: uuid.UUID,
        db: Session
    ) -> ConflictResolutionResult:
        """Resolve a schedule conflict"""
        try:
            # Get the conflict
            conflict = db.query(ScheduleConflict).filter(
                ScheduleConflict.id == conflict_id
            ).first()
            
            if not conflict:
                return ConflictResolutionResult(
                    success=False,
                    error_message="Conflict not found"
                )
            
            # Route to appropriate resolution method
            if resolution_type == "adjust_times":
                return await ConflictResolutionService._resolve_adjust_times(
                    conflict, resolution_data, apply_immediately, user_id, db
                )
            elif resolution_type == "reassign_employee":
                return await ConflictResolutionService._resolve_reassign_employee(
                    conflict, resolution_data, apply_immediately, user_id, db
                )
            elif resolution_type == "split_shift":
                return await ConflictResolutionService._resolve_split_shift(
                    conflict, resolution_data, apply_immediately, user_id, db
                )
            elif resolution_type == "add_coverage":
                return await ConflictResolutionService._resolve_add_coverage(
                    conflict, resolution_data, apply_immediately, user_id, db
                )
            elif resolution_type == "remove_shift":
                return await ConflictResolutionService._resolve_remove_shift(
                    conflict, resolution_data, apply_immediately, user_id, db
                )
            elif resolution_type == "override_constraint":
                return await ConflictResolutionService._resolve_override_constraint(
                    conflict, resolution_data, apply_immediately, user_id, db
                )
            elif resolution_type == "add_rest_day":
                return await ConflictResolutionService._resolve_add_rest_day(
                    conflict, resolution_data, apply_immediately, user_id, db
                )
            elif resolution_type == "custom":
                return await ConflictResolutionService._resolve_custom(
                    conflict, resolution_data, apply_immediately, user_id, db
                )
            else:
                return ConflictResolutionResult(
                    success=False,
                    error_message=f"Unknown resolution type: {resolution_type}"
                )
                
        except Exception as e:
            return ConflictResolutionResult(
                success=False,
                error_message=str(e)
            )
    
    @staticmethod
    async def _resolve_adjust_times(
        conflict: ScheduleConflict,
        resolution_data: Dict[str, Any],
        apply_immediately: bool,
        user_id: uuid.UUID,
        db: Session
    ) -> ConflictResolutionResult:
        """Resolve conflict by adjusting shift times"""
        try:
            if not apply_immediately:
                return ConflictResolutionResult(
                    success=True,
                    details={
                        "resolution_type": "adjust_times",
                        "preview": True,
                        "proposed_changes": resolution_data
                    }
                )
            
            # Get affected shifts
            shift_adjustments = resolution_data.get("shift_adjustments", [])
            
            for adjustment in shift_adjustments:
                shift_id = adjustment.get("shift_id")
                new_start_time = adjustment.get("new_start_time")
                new_end_time = adjustment.get("new_end_time")
                
                if not all([shift_id, new_start_time, new_end_time]):
                    continue
                
                # Get shift
                shift = db.query(ScheduleShift).filter(
                    ScheduleShift.id == shift_id
                ).first()
                
                if not shift:
                    continue
                
                # Parse times
                from datetime import time
                start_time = time.fromisoformat(new_start_time)
                end_time = time.fromisoformat(new_end_time)
                
                # Update shift times
                shift.override_start_time = start_time
                shift.override_end_time = end_time
                shift.override_reason = f"Adjusted to resolve conflict {conflict.id}"
                shift.updated_at = datetime.utcnow()
            
            db.commit()
            
            return ConflictResolutionResult(
                success=True,
                details={
                    "resolution_type": "adjust_times",
                    "shifts_adjusted": len(shift_adjustments),
                    "adjustments": shift_adjustments
                }
            )
            
        except Exception as e:
            db.rollback()
            return ConflictResolutionResult(
                success=False,
                error_message=str(e)
            )
    
    @staticmethod
    async def _resolve_reassign_employee(
        conflict: ScheduleConflict,
        resolution_data: Dict[str, Any],
        apply_immediately: bool,
        user_id: uuid.UUID,
        db: Session
    ) -> ConflictResolutionResult:
        """Resolve conflict by reassigning employee"""
        try:
            if not apply_immediately:
                return ConflictResolutionResult(
                    success=True,
                    details={
                        "resolution_type": "reassign_employee",
                        "preview": True,
                        "proposed_changes": resolution_data
                    }
                )
            
            shift_id = resolution_data.get("shift_id")
            new_employee_id = resolution_data.get("new_employee_id")
            
            if not all([shift_id, new_employee_id]):
                return ConflictResolutionResult(
                    success=False,
                    error_message="Missing required parameters: shift_id, new_employee_id"
                )
            
            # Get shift
            shift = db.query(ScheduleShift).filter(
                ScheduleShift.id == shift_id
            ).first()
            
            if not shift:
                return ConflictResolutionResult(
                    success=False,
                    error_message="Shift not found"
                )
            
            # Verify new employee exists
            new_employee = db.query(Employee).filter(
                Employee.id == new_employee_id
            ).first()
            
            if not new_employee:
                return ConflictResolutionResult(
                    success=False,
                    error_message="New employee not found"
                )
            
            # Check if new employee has conflicts
            existing_shifts = db.query(ScheduleShift).filter(
                ScheduleShift.employee_id == new_employee_id,
                ScheduleShift.date == shift.date,
                ScheduleShift.id != shift_id
            ).all()
            
            for existing_shift in existing_shifts:
                if (existing_shift.start_time < shift.end_time and 
                    existing_shift.end_time > shift.start_time):
                    return ConflictResolutionResult(
                        success=False,
                        error_message="New employee has conflicting shift at the same time"
                    )
            
            # Update shift assignment
            old_employee_id = shift.employee_id
            shift.employee_id = new_employee_id
            shift.notes = f"Reassigned from {old_employee_id} to resolve conflict {conflict.id}"
            shift.updated_at = datetime.utcnow()
            
            db.commit()
            
            return ConflictResolutionResult(
                success=True,
                details={
                    "resolution_type": "reassign_employee",
                    "shift_id": str(shift_id),
                    "old_employee_id": str(old_employee_id),
                    "new_employee_id": str(new_employee_id)
                }
            )
            
        except Exception as e:
            db.rollback()
            return ConflictResolutionResult(
                success=False,
                error_message=str(e)
            )
    
    @staticmethod
    async def _resolve_split_shift(
        conflict: ScheduleConflict,
        resolution_data: Dict[str, Any],
        apply_immediately: bool,
        user_id: uuid.UUID,
        db: Session
    ) -> ConflictResolutionResult:
        """Resolve conflict by splitting a shift"""
        try:
            if not apply_immediately:
                return ConflictResolutionResult(
                    success=True,
                    details={
                        "resolution_type": "split_shift",
                        "preview": True,
                        "proposed_changes": resolution_data
                    }
                )
            
            shift_id = resolution_data.get("shift_id")
            split_time = resolution_data.get("split_time")
            
            if not all([shift_id, split_time]):
                return ConflictResolutionResult(
                    success=False,
                    error_message="Missing required parameters: shift_id, split_time"
                )
            
            # Get shift
            shift = db.query(ScheduleShift).filter(
                ScheduleShift.id == shift_id
            ).first()
            
            if not shift:
                return ConflictResolutionResult(
                    success=False,
                    error_message="Shift not found"
                )
            
            # Parse split time
            from datetime import time
            split_time_obj = time.fromisoformat(split_time)
            
            # Validate split time is within shift bounds
            if split_time_obj <= shift.start_time or split_time_obj >= shift.end_time:
                return ConflictResolutionResult(
                    success=False,
                    error_message="Split time must be within shift bounds"
                )
            
            # Create second shift
            second_shift = ScheduleShift(
                schedule_id=shift.schedule_id,
                shift_id=shift.shift_id,
                employee_id=shift.employee_id,
                date=shift.date,
                start_time=split_time_obj,
                end_time=shift.end_time,
                notes=f"Split from shift {shift.id} to resolve conflict {conflict.id}",
                status=shift.status,
                break_times=shift.break_times
            )
            
            # Update original shift
            shift.end_time = split_time_obj
            shift.notes = f"Split at {split_time} to resolve conflict {conflict.id}"
            shift.updated_at = datetime.utcnow()
            
            db.add(second_shift)
            db.commit()
            db.refresh(second_shift)
            
            return ConflictResolutionResult(
                success=True,
                details={
                    "resolution_type": "split_shift",
                    "original_shift_id": str(shift.id),
                    "new_shift_id": str(second_shift.id),
                    "split_time": split_time
                }
            )
            
        except Exception as e:
            db.rollback()
            return ConflictResolutionResult(
                success=False,
                error_message=str(e)
            )
    
    @staticmethod
    async def _resolve_add_coverage(
        conflict: ScheduleConflict,
        resolution_data: Dict[str, Any],
        apply_immediately: bool,
        user_id: uuid.UUID,
        db: Session
    ) -> ConflictResolutionResult:
        """Resolve conflict by adding coverage"""
        try:
            if not apply_immediately:
                return ConflictResolutionResult(
                    success=True,
                    details={
                        "resolution_type": "add_coverage",
                        "preview": True,
                        "proposed_changes": resolution_data
                    }
                )
            
            new_shifts = resolution_data.get("new_shifts", [])
            
            if not new_shifts:
                return ConflictResolutionResult(
                    success=False,
                    error_message="No new shifts provided"
                )
            
            created_shifts = []
            
            for shift_data in new_shifts:
                employee_id = shift_data.get("employee_id")
                shift_id = shift_data.get("shift_id")
                date = shift_data.get("date")
                start_time = shift_data.get("start_time")
                end_time = shift_data.get("end_time")
                
                if not all([employee_id, shift_id, date, start_time, end_time]):
                    continue
                
                # Parse date and times
                from datetime import datetime, time
                shift_date = datetime.fromisoformat(date).date()
                start_time_obj = time.fromisoformat(start_time)
                end_time_obj = time.fromisoformat(end_time)
                
                # Create new shift
                new_shift = ScheduleShift(
                    schedule_id=conflict.schedule_id,
                    shift_id=shift_id,
                    employee_id=employee_id,
                    date=shift_date,
                    start_time=start_time_obj,
                    end_time=end_time_obj,
                    notes=f"Added to resolve coverage conflict {conflict.id}",
                    status="assigned"
                )
                
                db.add(new_shift)
                created_shifts.append(new_shift)
            
            db.commit()
            
            # Refresh created shifts
            for shift in created_shifts:
                db.refresh(shift)
            
            return ConflictResolutionResult(
                success=True,
                details={
                    "resolution_type": "add_coverage",
                    "shifts_added": len(created_shifts),
                    "new_shift_ids": [str(shift.id) for shift in created_shifts]
                }
            )
            
        except Exception as e:
            db.rollback()
            return ConflictResolutionResult(
                success=False,
                error_message=str(e)
            )
    
    @staticmethod
    async def _resolve_remove_shift(
        conflict: ScheduleConflict,
        resolution_data: Dict[str, Any],
        apply_immediately: bool,
        user_id: uuid.UUID,
        db: Session
    ) -> ConflictResolutionResult:
        """Resolve conflict by removing a shift"""
        try:
            if not apply_immediately:
                return ConflictResolutionResult(
                    success=True,
                    details={
                        "resolution_type": "remove_shift",
                        "preview": True,
                        "proposed_changes": resolution_data
                    }
                )
            
            shift_id = resolution_data.get("shift_id")
            
            if not shift_id:
                return ConflictResolutionResult(
                    success=False,
                    error_message="Missing required parameter: shift_id"
                )
            
            # Get shift
            shift = db.query(ScheduleShift).filter(
                ScheduleShift.id == shift_id
            ).first()
            
            if not shift:
                return ConflictResolutionResult(
                    success=False,
                    error_message="Shift not found"
                )
            
            # Store shift info for logging
            shift_info = {
                "shift_id": str(shift.id),
                "employee_id": str(shift.employee_id),
                "date": shift.date.isoformat(),
                "start_time": shift.start_time.isoformat(),
                "end_time": shift.end_time.isoformat()
            }
            
            # Remove shift
            db.delete(shift)
            db.commit()
            
            return ConflictResolutionResult(
                success=True,
                details={
                    "resolution_type": "remove_shift",
                    "removed_shift": shift_info
                }
            )
            
        except Exception as e:
            db.rollback()
            return ConflictResolutionResult(
                success=False,
                error_message=str(e)
            )
    
    @staticmethod
    async def _resolve_override_constraint(
        conflict: ScheduleConflict,
        resolution_data: Dict[str, Any],
        apply_immediately: bool,
        user_id: uuid.UUID,
        db: Session
    ) -> ConflictResolutionResult:
        """Resolve conflict by overriding a constraint"""
        try:
            if not apply_immediately:
                return ConflictResolutionResult(
                    success=True,
                    details={
                        "resolution_type": "override_constraint",
                        "preview": True,
                        "proposed_changes": resolution_data
                    }
                )
            
            constraint_id = resolution_data.get("constraint_id")
            override_reason = resolution_data.get("override_reason", "")
            
            if not constraint_id:
                return ConflictResolutionResult(
                    success=False,
                    error_message="Missing required parameter: constraint_id"
                )
            
            # Get constraint
            constraint = db.query(ScheduleConstraint).filter(
                ScheduleConstraint.id == constraint_id
            ).first()
            
            if not constraint:
                return ConflictResolutionResult(
                    success=False,
                    error_message="Constraint not found"
                )
            
            # Don't allow overriding hard constraints
            if constraint.is_hard_constraint:
                return ConflictResolutionResult(
                    success=False,
                    error_message="Cannot override hard constraint"
                )
            
            # Create override record (this could be a separate model)
            # For now, we'll add a note to the constraint
            constraint.description = f"{constraint.description or ''}\n\nOVERRIDE: {override_reason} (Conflict {conflict.id})"
            constraint.updated_at = datetime.utcnow()
            
            db.commit()
            
            return ConflictResolutionResult(
                success=True,
                details={
                    "resolution_type": "override_constraint",
                    "constraint_id": str(constraint_id),
                    "override_reason": override_reason
                }
            )
            
        except Exception as e:
            db.rollback()
            return ConflictResolutionResult(
                success=False,
                error_message=str(e)
            )
    
    @staticmethod
    async def _resolve_add_rest_day(
        conflict: ScheduleConflict,
        resolution_data: Dict[str, Any],
        apply_immediately: bool,
        user_id: uuid.UUID,
        db: Session
    ) -> ConflictResolutionResult:
        """Resolve conflict by adding a rest day"""
        try:
            if not apply_immediately:
                return ConflictResolutionResult(
                    success=True,
                    details={
                        "resolution_type": "add_rest_day",
                        "preview": True,
                        "proposed_changes": resolution_data
                    }
                )
            
            employee_id = resolution_data.get("employee_id")
            rest_date = resolution_data.get("rest_date")
            
            if not all([employee_id, rest_date]):
                return ConflictResolutionResult(
                    success=False,
                    error_message="Missing required parameters: employee_id, rest_date"
                )
            
            # Parse rest date
            from datetime import datetime
            rest_date_obj = datetime.fromisoformat(rest_date).date()
            
            # Find shifts to remove on the rest date
            shifts_to_remove = db.query(ScheduleShift).filter(
                ScheduleShift.employee_id == employee_id,
                ScheduleShift.date == rest_date_obj,
                ScheduleShift.schedule_id == conflict.schedule_id
            ).all()
            
            removed_shifts = []
            for shift in shifts_to_remove:
                removed_shifts.append({
                    "shift_id": str(shift.id),
                    "start_time": shift.start_time.isoformat(),
                    "end_time": shift.end_time.isoformat()
                })
                db.delete(shift)
            
            db.commit()
            
            return ConflictResolutionResult(
                success=True,
                details={
                    "resolution_type": "add_rest_day",
                    "employee_id": str(employee_id),
                    "rest_date": rest_date,
                    "removed_shifts": removed_shifts
                }
            )
            
        except Exception as e:
            db.rollback()
            return ConflictResolutionResult(
                success=False,
                error_message=str(e)
            )
    
    @staticmethod
    async def _resolve_custom(
        conflict: ScheduleConflict,
        resolution_data: Dict[str, Any],
        apply_immediately: bool,
        user_id: uuid.UUID,
        db: Session
    ) -> ConflictResolutionResult:
        """Resolve conflict with custom resolution"""
        try:
            if not apply_immediately:
                return ConflictResolutionResult(
                    success=True,
                    details={
                        "resolution_type": "custom",
                        "preview": True,
                        "proposed_changes": resolution_data
                    }
                )
            
            # Custom resolution logic would go here
            # For now, we'll just log the resolution
            custom_action = resolution_data.get("action", "")
            custom_notes = resolution_data.get("notes", "")
            
            return ConflictResolutionResult(
                success=True,
                details={
                    "resolution_type": "custom",
                    "action": custom_action,
                    "notes": custom_notes
                }
            )
            
        except Exception as e:
            return ConflictResolutionResult(
                success=False,
                error_message=str(e)
            )
    
    @staticmethod
    async def suggest_resolution(
        conflict: ScheduleConflict,
        db: Session
    ) -> List[Dict[str, Any]]:
        """Suggest possible resolutions for a conflict"""
        try:
            suggestions = []
            
            if conflict.conflict_type == "overlap":
                # Suggest time adjustments
                suggestions.append({
                    "type": "adjust_times",
                    "title": "Adjust shift times",
                    "description": "Modify start/end times to eliminate overlap",
                    "complexity": "low",
                    "impact": "low"
                })
                
                # Suggest employee reassignment
                suggestions.append({
                    "type": "reassign_employee",
                    "title": "Reassign employee",
                    "description": "Assign one of the overlapping shifts to a different employee",
                    "complexity": "medium",
                    "impact": "medium"
                })
                
                # Suggest shift splitting
                suggestions.append({
                    "type": "split_shift",
                    "title": "Split shift",
                    "description": "Split one shift into two non-overlapping shifts",
                    "complexity": "high",
                    "impact": "medium"
                })
            
            elif conflict.conflict_type == "coverage":
                # Suggest adding coverage
                suggestions.append({
                    "type": "add_coverage",
                    "title": "Add additional coverage",
                    "description": "Schedule additional employees to meet coverage requirements",
                    "complexity": "medium",
                    "impact": "high"
                })
                
                # Suggest extending existing shifts
                suggestions.append({
                    "type": "adjust_times",
                    "title": "Extend existing shifts",
                    "description": "Extend current shifts to provide better coverage",
                    "complexity": "low",
                    "impact": "medium"
                })
            
            elif conflict.conflict_type == "rule":
                # Suggest rule-specific resolutions
                if "consecutive" in conflict.description.lower():
                    suggestions.append({
                        "type": "add_rest_day",
                        "title": "Add rest day",
                        "description": "Add a rest day to break consecutive work period",
                        "complexity": "medium",
                        "impact": "medium"
                    })
                
                # Suggest override if not critical
                if conflict.severity != "critical":
                    suggestions.append({
                        "type": "override_constraint",
                        "title": "Override rule",
                        "description": "Override the rule with proper justification",
                        "complexity": "low",
                        "impact": "low"
                    })
            
            # Always suggest custom resolution
            suggestions.append({
                "type": "custom",
                "title": "Custom resolution",
                "description": "Apply a custom resolution tailored to this specific conflict",
                "complexity": "high",
                "impact": "variable"
            })
            
            return suggestions
            
        except Exception as e:
            return []
    
    @staticmethod
    async def get_resolution_preview(
        conflict: ScheduleConflict,
        resolution_type: str,
        resolution_data: Dict[str, Any],
        db: Session
    ) -> Dict[str, Any]:
        """Get a preview of what the resolution would do"""
        try:
            # Call the resolution method with apply_immediately=False
            result = await ConflictResolutionService.resolve_conflict(
                conflict.id,
                resolution_type,
                resolution_data,
                apply_immediately=False,
                user_id=uuid.uuid4(),  # Dummy user ID for preview
                db=db
            )
            
            if result.success:
                return {
                    "success": True,
                    "preview": result.details,
                    "impact_summary": await ConflictResolutionService._calculate_impact_summary(
                        conflict, resolution_type, resolution_data, db
                    )
                }
            else:
                return {
                    "success": False,
                    "error": result.error_message
                }
                
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    @staticmethod
    async def _calculate_impact_summary(
        conflict: ScheduleConflict,
        resolution_type: str,
        resolution_data: Dict[str, Any],
        db: Session
    ) -> Dict[str, Any]:
        """Calculate the impact summary of a resolution"""
        try:
            impact = {
                "employees_affected": 0,
                "shifts_modified": 0,
                "cost_impact": 0.0,
                "coverage_impact": 0.0,
                "satisfaction_impact": 0.0
            }
            
            # Calculate based on resolution type
            if resolution_type == "adjust_times":
                shift_adjustments = resolution_data.get("shift_adjustments", [])
                impact["shifts_modified"] = len(shift_adjustments)
                impact["employees_affected"] = len(set(
                    adj.get("employee_id") for adj in shift_adjustments
                    if adj.get("employee_id")
                ))
                impact["satisfaction_impact"] = -0.1  # Slight negative impact
            
            elif resolution_type == "reassign_employee":
                impact["employees_affected"] = 2  # Old and new employee
                impact["shifts_modified"] = 1
                impact["satisfaction_impact"] = -0.2  # Reassignment may be disruptive
            
            elif resolution_type == "add_coverage":
                new_shifts = resolution_data.get("new_shifts", [])
                impact["shifts_modified"] = len(new_shifts)
                impact["employees_affected"] = len(set(
                    shift.get("employee_id") for shift in new_shifts
                    if shift.get("employee_id")
                ))
                impact["cost_impact"] = len(new_shifts) * 100  # Estimated cost per shift
                impact["coverage_impact"] = 0.2  # Positive coverage impact
            
            elif resolution_type == "remove_shift":
                impact["shifts_modified"] = 1
                impact["employees_affected"] = 1
                impact["cost_impact"] = -100  # Cost savings
                impact["coverage_impact"] = -0.1  # Negative coverage impact
            
            return impact
            
        except Exception as e:
            return {
                "employees_affected": 0,
                "shifts_modified": 0,
                "cost_impact": 0.0,
                "coverage_impact": 0.0,
                "satisfaction_impact": 0.0,
                "error": str(e)
            }
    
    @staticmethod
    async def batch_resolve_similar_conflicts(
        conflict_ids: List[uuid.UUID],
        resolution_type: str,
        resolution_template: Dict[str, Any],
        user_id: uuid.UUID,
        db: Session
    ) -> Dict[str, Any]:
        """Batch resolve similar conflicts"""
        try:
            results = []
            successful_resolutions = 0
            failed_resolutions = 0
            
            for conflict_id in conflict_ids:
                try:
                    # Get conflict
                    conflict = db.query(ScheduleConflict).filter(
                        ScheduleConflict.id == conflict_id
                    ).first()
                    
                    if not conflict:
                        results.append({
                            "conflict_id": str(conflict_id),
                            "status": "failed",
                            "error": "Conflict not found"
                        })
                        failed_resolutions += 1
                        continue
                    
                    # Customize resolution data for this conflict
                    resolution_data = await ConflictResolutionService._customize_resolution_data(
                        conflict, resolution_template, db
                    )
                    
                    # Resolve conflict
                    resolution_result = await ConflictResolutionService.resolve_conflict(
                        conflict_id,
                        resolution_type,
                        resolution_data,
                        apply_immediately=True,
                        user_id=user_id,
                        db=db
                    )
                    
                    if resolution_result.success:
                        results.append({
                            "conflict_id": str(conflict_id),
                            "status": "resolved",
                            "details": resolution_result.details
                        })
                        successful_resolutions += 1
                    else:
                        results.append({
                            "conflict_id": str(conflict_id),
                            "status": "failed",
                            "error": resolution_result.error_message
                        })
                        failed_resolutions += 1
                
                except Exception as e:
                    results.append({
                        "conflict_id": str(conflict_id),
                        "status": "failed",
                        "error": str(e)
                    })
                    failed_resolutions += 1
            
            return {
                "total_conflicts": len(conflict_ids),
                "successful_resolutions": successful_resolutions,
                "failed_resolutions": failed_resolutions,
                "results": results
            }
            
        except Exception as e:
            return {
                "total_conflicts": len(conflict_ids),
                "successful_resolutions": 0,
                "failed_resolutions": len(conflict_ids),
                "error": str(e),
                "results": []
            }
    
    @staticmethod
    async def _customize_resolution_data(
        conflict: ScheduleConflict,
        resolution_template: Dict[str, Any],
        db: Session
    ) -> Dict[str, Any]:
        """Customize resolution data for a specific conflict"""
        try:
            # Start with the template
            resolution_data = resolution_template.copy()
            
            # Customize based on conflict specifics
            if conflict.conflict_type == "overlap":
                # Get affected shifts
                affected_shifts = conflict.affected_shifts or []
                
                # Customize shift adjustments
                if "shift_adjustments" in resolution_data:
                    customized_adjustments = []
                    for adjustment in resolution_data["shift_adjustments"]:
                        # This would implement conflict-specific customization
                        customized_adjustments.append(adjustment)
                    resolution_data["shift_adjustments"] = customized_adjustments
            
            elif conflict.conflict_type == "coverage":
                # Customize coverage additions based on specific gaps
                if "new_shifts" in resolution_data:
                    # This would implement coverage-specific customization
                    pass
            
            return resolution_data
            
        except Exception as e:
            return resolution_template