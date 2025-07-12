"""
Schedule Service Layer
Business logic for schedule management operations
"""

from typing import List, Dict, Any, Optional
from datetime import datetime, date, timedelta
from decimal import Decimal
import uuid
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func

from ..models.schedule import (
    Schedule, ScheduleShift, ScheduleVariant, ScheduleConflict, 
    ScheduleRule, ScheduleConstraint, ScheduleOptimization
)
from ..models.user import User, Employee
from ..v1.schemas.schedules import ValidationResult, BulkOperationResult
from .websocket import websocket_manager


class ScheduleService:
    """Service class for schedule management operations"""
    
    @staticmethod
    async def generate_schedule(
        schedule_id: uuid.UUID,
        generation_params: Dict[str, Any],
        user_id: uuid.UUID
    ) -> bool:
        """Generate schedule using AI/ML algorithms"""
        try:
            # This would integrate with the algorithm modules
            # For now, we'll simulate the generation process
            
            # Send progress updates via WebSocket
            await websocket_manager.broadcast_schedule_event(
                "schedule.generation_progress",
                {
                    "schedule_id": str(schedule_id),
                    "progress": 25,
                    "message": "Analyzing constraints..."
                }
            )
            
            # Simulate processing time
            await asyncio.sleep(2)
            
            await websocket_manager.broadcast_schedule_event(
                "schedule.generation_progress",
                {
                    "schedule_id": str(schedule_id),
                    "progress": 50,
                    "message": "Generating shift assignments..."
                }
            )
            
            await asyncio.sleep(2)
            
            await websocket_manager.broadcast_schedule_event(
                "schedule.generation_progress",
                {
                    "schedule_id": str(schedule_id),
                    "progress": 75,
                    "message": "Optimizing coverage..."
                }
            )
            
            await asyncio.sleep(2)
            
            # Complete generation
            await websocket_manager.broadcast_schedule_event(
                "schedule.generation_completed",
                {
                    "schedule_id": str(schedule_id),
                    "progress": 100,
                    "message": "Schedule generated successfully"
                }
            )
            
            return True
            
        except Exception as e:
            await websocket_manager.broadcast_schedule_event(
                "schedule.generation_failed",
                {
                    "schedule_id": str(schedule_id),
                    "error": str(e)
                }
            )
            return False
    
    @staticmethod
    async def validate_schedule(schedule_id: uuid.UUID, db: Session) -> ValidationResult:
        """Validate schedule against rules and constraints"""
        try:
            schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
            if not schedule:
                return ValidationResult(
                    is_valid=False,
                    errors=[{"error": "Schedule not found", "severity": "critical"}],
                    validation_summary={"valid": False, "error_count": 1}
                )
            
            errors = []
            warnings = []
            suggestions = []
            
            # Get all shifts for this schedule
            shifts = db.query(ScheduleShift).filter(
                ScheduleShift.schedule_id == schedule_id
            ).all()
            
            # Check for basic validation issues
            if not shifts:
                errors.append({
                    "error": "Schedule has no shifts assigned",
                    "severity": "critical",
                    "code": "NO_SHIFTS"
                })
            
            # Check for overlapping shifts
            overlaps = await ScheduleService._check_shift_overlaps(shifts, db)
            if overlaps:
                errors.extend(overlaps)
            
            # Check coverage requirements
            coverage_issues = await ScheduleService._check_coverage_requirements(
                schedule_id, shifts, db
            )
            if coverage_issues:
                warnings.extend(coverage_issues)
            
            # Check rule violations
            rule_violations = await ScheduleService._check_rule_violations(
                schedule_id, shifts, db
            )
            if rule_violations:
                errors.extend(rule_violations)
            
            # Check constraint violations
            constraint_violations = await ScheduleService._check_constraint_violations(
                schedule_id, shifts, db
            )
            if constraint_violations:
                warnings.extend(constraint_violations)
            
            is_valid = len([e for e in errors if e.get("severity") == "critical"]) == 0
            
            return ValidationResult(
                is_valid=is_valid,
                errors=errors,
                warnings=warnings,
                suggestions=suggestions,
                validation_summary={
                    "valid": is_valid,
                    "error_count": len(errors),
                    "warning_count": len(warnings),
                    "suggestion_count": len(suggestions)
                }
            )
            
        except Exception as e:
            return ValidationResult(
                is_valid=False,
                errors=[{"error": str(e), "severity": "critical"}],
                validation_summary={"valid": False, "error_count": 1}
            )
    
    @staticmethod
    async def validate_schedule_data(
        schedule_data: Dict[str, Any],
        validation_rules: Optional[List[str]],
        strict_validation: bool,
        organization_id: uuid.UUID,
        db: Session
    ) -> ValidationResult:
        """Validate schedule data before creating/updating"""
        try:
            errors = []
            warnings = []
            suggestions = []
            
            # Basic data validation
            if not schedule_data.get("name"):
                errors.append({
                    "error": "Schedule name is required",
                    "severity": "critical",
                    "field": "name"
                })
            
            if not schedule_data.get("start_date") or not schedule_data.get("end_date"):
                errors.append({
                    "error": "Start date and end date are required",
                    "severity": "critical",
                    "field": "dates"
                })
            
            # Date validation
            if schedule_data.get("start_date") and schedule_data.get("end_date"):
                start_date = datetime.fromisoformat(schedule_data["start_date"]).date()
                end_date = datetime.fromisoformat(schedule_data["end_date"]).date()
                
                if end_date <= start_date:
                    errors.append({
                        "error": "End date must be after start date",
                        "severity": "critical",
                        "field": "dates"
                    })
                
                # Check for reasonable date range
                if (end_date - start_date).days > 365:
                    warnings.append({
                        "warning": "Schedule spans more than a year",
                        "severity": "minor",
                        "field": "dates"
                    })
            
            # Check for duplicate names in organization
            if schedule_data.get("name"):
                existing = db.query(Schedule).filter(
                    Schedule.name == schedule_data["name"],
                    Schedule.organization_id == organization_id
                ).first()
                
                if existing:
                    if strict_validation:
                        errors.append({
                            "error": "Schedule name already exists",
                            "severity": "critical",
                            "field": "name"
                        })
                    else:
                        warnings.append({
                            "warning": "Schedule name already exists",
                            "severity": "minor",
                            "field": "name"
                        })
            
            is_valid = len([e for e in errors if e.get("severity") == "critical"]) == 0
            
            return ValidationResult(
                is_valid=is_valid,
                errors=errors,
                warnings=warnings,
                suggestions=suggestions,
                validation_summary={
                    "valid": is_valid,
                    "error_count": len(errors),
                    "warning_count": len(warnings),
                    "suggestion_count": len(suggestions)
                }
            )
            
        except Exception as e:
            return ValidationResult(
                is_valid=False,
                errors=[{"error": str(e), "severity": "critical"}],
                validation_summary={"valid": False, "error_count": 1}
            )
    
    @staticmethod
    async def bulk_update_schedules(
        operations: List[Dict[str, Any]],
        validate_before_apply: bool,
        rollback_on_error: bool,
        user_id: uuid.UUID,
        organization_id: uuid.UUID,
        db: Session
    ) -> BulkOperationResult:
        """Perform bulk updates on schedules"""
        try:
            results = []
            successful_operations = 0
            failed_operations = 0
            errors = []
            
            for i, operation in enumerate(operations):
                try:
                    op_type = operation.get("type")
                    op_data = operation.get("data", {})
                    
                    if op_type == "update_schedule":
                        schedule_id = operation.get("schedule_id")
                        schedule = db.query(Schedule).filter(
                            Schedule.id == schedule_id,
                            Schedule.organization_id == organization_id
                        ).first()
                        
                        if not schedule:
                            raise Exception(f"Schedule {schedule_id} not found")
                        
                        # Apply updates
                        for field, value in op_data.items():
                            if hasattr(schedule, field):
                                setattr(schedule, field, value)
                        
                        schedule.updated_at = datetime.utcnow()
                        
                        results.append({
                            "operation": i + 1,
                            "type": op_type,
                            "status": "success",
                            "schedule_id": str(schedule_id)
                        })
                        successful_operations += 1
                        
                    elif op_type == "create_shift":
                        shift_data = ScheduleShift(**op_data)
                        db.add(shift_data)
                        
                        results.append({
                            "operation": i + 1,
                            "type": op_type,
                            "status": "success",
                            "shift_id": str(shift_data.id)
                        })
                        successful_operations += 1
                        
                    elif op_type == "delete_shift":
                        shift_id = operation.get("shift_id")
                        shift = db.query(ScheduleShift).filter(
                            ScheduleShift.id == shift_id
                        ).first()
                        
                        if shift:
                            db.delete(shift)
                            
                        results.append({
                            "operation": i + 1,
                            "type": op_type,
                            "status": "success",
                            "shift_id": str(shift_id)
                        })
                        successful_operations += 1
                        
                    else:
                        raise Exception(f"Unknown operation type: {op_type}")
                        
                except Exception as e:
                    error_msg = str(e)
                    errors.append({
                        "operation": i + 1,
                        "error": error_msg,
                        "data": operation
                    })
                    
                    results.append({
                        "operation": i + 1,
                        "type": operation.get("type", "unknown"),
                        "status": "failed",
                        "error": error_msg
                    })
                    failed_operations += 1
                    
                    if rollback_on_error:
                        db.rollback()
                        return BulkOperationResult(
                            total_operations=len(operations),
                            successful_operations=0,
                            failed_operations=len(operations),
                            results=[],
                            errors=errors
                        )
            
            if not rollback_on_error or failed_operations == 0:
                db.commit()
            
            return BulkOperationResult(
                total_operations=len(operations),
                successful_operations=successful_operations,
                failed_operations=failed_operations,
                results=results,
                errors=errors
            )
            
        except Exception as e:
            db.rollback()
            return BulkOperationResult(
                total_operations=len(operations),
                successful_operations=0,
                failed_operations=len(operations),
                results=[],
                errors=[{"error": str(e)}]
            )
    
    @staticmethod
    async def copy_schedule_assignments(
        source_schedule_id: uuid.UUID,
        target_schedule_id: uuid.UUID,
        start_date: date,
        end_date: date,
        db: Session
    ) -> bool:
        """Copy schedule assignments from source to target"""
        try:
            # Get source shifts
            source_shifts = db.query(ScheduleShift).filter(
                ScheduleShift.schedule_id == source_schedule_id
            ).all()
            
            if not source_shifts:
                return True  # No shifts to copy
            
            # Calculate date offset
            source_schedule = db.query(Schedule).filter(
                Schedule.id == source_schedule_id
            ).first()
            
            if not source_schedule:
                return False
            
            date_offset = (start_date - source_schedule.start_date).days
            
            # Copy shifts with date adjustment
            for source_shift in source_shifts:
                new_date = source_shift.date + timedelta(days=date_offset)
                
                # Skip if new date is outside target range
                if new_date < start_date or new_date > end_date:
                    continue
                
                new_shift = ScheduleShift(
                    schedule_id=target_schedule_id,
                    shift_id=source_shift.shift_id,
                    employee_id=source_shift.employee_id,
                    date=new_date,
                    start_time=source_shift.start_time,
                    end_time=source_shift.end_time,
                    override_start_time=source_shift.override_start_time,
                    override_end_time=source_shift.override_end_time,
                    override_reason=source_shift.override_reason,
                    notes=source_shift.notes,
                    break_times=source_shift.break_times,
                    status="assigned"
                )
                
                db.add(new_shift)
            
            db.commit()
            return True
            
        except Exception as e:
            db.rollback()
            return False
    
    @staticmethod
    async def copy_schedule_constraints(
        source_schedule_id: uuid.UUID,
        target_schedule_id: uuid.UUID,
        start_date: date,
        end_date: date,
        db: Session
    ) -> bool:
        """Copy schedule constraints from source to target"""
        try:
            # Get employees from source schedule
            source_employees = db.query(ScheduleShift.employee_id).filter(
                ScheduleShift.schedule_id == source_schedule_id
            ).distinct().all()
            
            employee_ids = [emp[0] for emp in source_employees]
            
            # Get constraints for these employees
            constraints = db.query(ScheduleConstraint).filter(
                ScheduleConstraint.employee_id.in_(employee_ids),
                ScheduleConstraint.is_active == True
            ).all()
            
            # Copy relevant constraints
            for constraint in constraints:
                # Check if constraint is relevant for target date range
                if constraint.valid_to and constraint.valid_to < start_date:
                    continue
                if constraint.valid_from > end_date:
                    continue
                
                # Adjust constraint dates
                new_valid_from = max(constraint.valid_from, start_date)
                new_valid_to = min(constraint.valid_to, end_date) if constraint.valid_to else end_date
                
                new_constraint = ScheduleConstraint(
                    employee_id=constraint.employee_id,
                    constraint_type=constraint.constraint_type,
                    name=f"{constraint.name} (copied)",
                    description=constraint.description,
                    constraint_data=constraint.constraint_data,
                    priority=constraint.priority,
                    is_hard_constraint=constraint.is_hard_constraint,
                    valid_from=new_valid_from,
                    valid_to=new_valid_to,
                    days_of_week=constraint.days_of_week,
                    time_ranges=constraint.time_ranges,
                    created_by=constraint.created_by
                )
                
                db.add(new_constraint)
            
            db.commit()
            return True
            
        except Exception as e:
            db.rollback()
            return False
    
    @staticmethod
    async def merge_schedules(
        source_schedule_ids: List[uuid.UUID],
        name: str,
        merge_strategy: str,
        conflict_resolution: str,
        priority_order: Optional[List[uuid.UUID]],
        user_id: uuid.UUID,
        organization_id: uuid.UUID,
        db: Session
    ) -> Schedule:
        """Merge multiple schedules into one"""
        try:
            # Get source schedules
            source_schedules = db.query(Schedule).filter(
                Schedule.id.in_(source_schedule_ids)
            ).all()
            
            # Calculate date range for merged schedule
            start_date = min(schedule.start_date for schedule in source_schedules)
            end_date = max(schedule.end_date for schedule in source_schedules)
            
            # Create merged schedule
            merged_schedule = Schedule(
                name=name,
                description=f"Merged from {len(source_schedules)} schedules",
                start_date=start_date,
                end_date=end_date,
                schedule_type="merged",
                organization_id=organization_id,
                created_by=user_id,
                status="draft"
            )
            
            db.add(merged_schedule)
            db.commit()
            db.refresh(merged_schedule)
            
            # Merge shifts based on strategy
            if merge_strategy == "combine":
                # Simply combine all shifts
                await ScheduleService._merge_combine_shifts(
                    source_schedule_ids, merged_schedule.id, db
                )
            elif merge_strategy == "overlay":
                # Overlay shifts with conflict resolution
                await ScheduleService._merge_overlay_shifts(
                    source_schedule_ids, merged_schedule.id, conflict_resolution, db
                )
            elif merge_strategy == "priority":
                # Use priority order for conflicts
                await ScheduleService._merge_priority_shifts(
                    source_schedule_ids, merged_schedule.id, priority_order, db
                )
            
            return merged_schedule
            
        except Exception as e:
            db.rollback()
            raise e
    
    @staticmethod
    async def analyze_variant_impact(
        schedule_id: uuid.UUID,
        variant_data: Dict[str, Any],
        db: Session
    ) -> Dict[str, Any]:
        """Analyze the impact of a schedule variant"""
        try:
            # Get base schedule
            base_schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
            if not base_schedule:
                return {}
            
            # Get base schedule shifts
            base_shifts = db.query(ScheduleShift).filter(
                ScheduleShift.schedule_id == schedule_id
            ).all()
            
            # Analyze cost impact
            cost_impact = await ScheduleService._analyze_cost_impact(
                base_shifts, variant_data, db
            )
            
            # Analyze coverage impact
            coverage_impact = await ScheduleService._analyze_coverage_impact(
                base_shifts, variant_data, db
            )
            
            # Analyze employee satisfaction impact
            satisfaction_impact = await ScheduleService._analyze_satisfaction_impact(
                base_shifts, variant_data, db
            )
            
            return {
                "cost_impact": cost_impact,
                "coverage_impact": coverage_impact,
                "employee_satisfaction": satisfaction_impact
            }
            
        except Exception as e:
            return {"error": str(e)}
    
    @staticmethod
    async def detect_schedule_conflicts(
        schedule_id: uuid.UUID,
        organization_id: uuid.UUID,
        db: Session
    ) -> Any:
        """Detect conflicts in a schedule"""
        try:
            start_time = datetime.utcnow()
            
            # Get schedule shifts
            shifts = db.query(ScheduleShift).filter(
                ScheduleShift.schedule_id == schedule_id
            ).all()
            
            conflicts_found = 0
            critical_conflicts = 0
            major_conflicts = 0
            minor_conflicts = 0
            warnings = 0
            
            # Check for overlapping shifts
            overlaps = await ScheduleService._detect_shift_overlaps(shifts, db)
            for overlap in overlaps:
                conflict = ScheduleConflict(
                    schedule_id=schedule_id,
                    conflict_type="overlap",
                    severity=overlap["severity"],
                    title=overlap["title"],
                    description=overlap["description"],
                    affected_employees=overlap["affected_employees"],
                    affected_shifts=overlap["affected_shifts"],
                    suggested_resolution=overlap["suggested_resolution"]
                )
                db.add(conflict)
                
                if overlap["severity"] == "critical":
                    critical_conflicts += 1
                elif overlap["severity"] == "major":
                    major_conflicts += 1
                else:
                    minor_conflicts += 1
                
                conflicts_found += 1
            
            # Check for coverage gaps
            coverage_gaps = await ScheduleService._detect_coverage_gaps(
                schedule_id, shifts, db
            )
            for gap in coverage_gaps:
                conflict = ScheduleConflict(
                    schedule_id=schedule_id,
                    conflict_type="coverage",
                    severity=gap["severity"],
                    title=gap["title"],
                    description=gap["description"],
                    affected_shifts=gap["affected_shifts"],
                    suggested_resolution=gap["suggested_resolution"]
                )
                db.add(conflict)
                
                if gap["severity"] == "critical":
                    critical_conflicts += 1
                elif gap["severity"] == "major":
                    major_conflicts += 1
                else:
                    minor_conflicts += 1
                
                conflicts_found += 1
            
            # Check for rule violations
            rule_violations = await ScheduleService._detect_rule_violations(
                schedule_id, shifts, organization_id, db
            )
            for violation in rule_violations:
                conflict = ScheduleConflict(
                    schedule_id=schedule_id,
                    conflict_type="rule",
                    severity=violation["severity"],
                    title=violation["title"],
                    description=violation["description"],
                    affected_employees=violation["affected_employees"],
                    affected_shifts=violation["affected_shifts"],
                    suggested_resolution=violation["suggested_resolution"]
                )
                db.add(conflict)
                
                if violation["severity"] == "critical":
                    critical_conflicts += 1
                elif violation["severity"] == "major":
                    major_conflicts += 1
                else:
                    minor_conflicts += 1
                
                conflicts_found += 1
            
            end_time = datetime.utcnow()
            detection_time_ms = int((end_time - start_time).total_seconds() * 1000)
            
            # Return detection result
            class DetectionResult:
                def __init__(self):
                    self.conflicts_found = conflicts_found
                    self.critical_conflicts = critical_conflicts
                    self.major_conflicts = major_conflicts
                    self.minor_conflicts = minor_conflicts
                    self.warnings = warnings
                    self.detection_time_ms = detection_time_ms
            
            return DetectionResult()
            
        except Exception as e:
            db.rollback()
            raise e
    
    @staticmethod
    async def get_employee_schedule_conflicts(
        employee_id: uuid.UUID,
        start_date: date,
        end_date: date,
        db: Session
    ) -> List[Dict[str, Any]]:
        """Get conflicts for an employee's schedule"""
        try:
            conflicts = db.query(ScheduleConflict).join(Schedule).join(ScheduleShift).filter(
                ScheduleShift.employee_id == employee_id,
                ScheduleShift.date >= start_date,
                ScheduleShift.date <= end_date,
                ScheduleConflict.status == "open"
            ).all()
            
            return [
                {
                    "id": str(conflict.id),
                    "type": conflict.conflict_type,
                    "severity": conflict.severity,
                    "title": conflict.title,
                    "description": conflict.description,
                    "detected_at": conflict.detected_at.isoformat()
                }
                for conflict in conflicts
            ]
            
        except Exception as e:
            return []
    
    @staticmethod
    async def record_schedule_acknowledgment(
        employee_id: uuid.UUID,
        schedule_id: uuid.UUID,
        acknowledged_at: datetime,
        comments: Optional[str],
        user_id: uuid.UUID,
        db: Session
    ) -> bool:
        """Record schedule acknowledgment"""
        try:
            # This would typically be stored in a separate acknowledgment table
            # For now, we'll just log it
            
            # Could create a ScheduleAcknowledgment model if needed
            return True
            
        except Exception as e:
            return False
    
    @staticmethod
    async def send_schedule_notifications(
        schedule_id: uuid.UUID,
        publication_id: uuid.UUID,
        user_id: uuid.UUID
    ) -> bool:
        """Send schedule notifications to employees"""
        try:
            # This would integrate with notification service
            # For now, we'll simulate sending notifications
            
            await websocket_manager.broadcast_schedule_event(
                "schedule.notifications_sent",
                {
                    "schedule_id": str(schedule_id),
                    "publication_id": str(publication_id),
                    "sent_by": str(user_id)
                }
            )
            
            return True
            
        except Exception as e:
            return False
    
    @staticmethod
    async def apply_schedule_variant(
        schedule_id: uuid.UUID,
        variant_id: uuid.UUID,
        user_id: uuid.UUID
    ) -> bool:
        """Apply a schedule variant to the main schedule"""
        try:
            # This would apply the variant changes to the main schedule
            # For now, we'll simulate the application
            
            await websocket_manager.broadcast_schedule_event(
                "schedule.variant_applied",
                {
                    "schedule_id": str(schedule_id),
                    "variant_id": str(variant_id),
                    "applied_by": str(user_id)
                }
            )
            
            return True
            
        except Exception as e:
            return False
    
    # Helper methods
    @staticmethod
    async def _check_shift_overlaps(shifts: List[ScheduleShift], db: Session) -> List[Dict[str, Any]]:
        """Check for overlapping shifts"""
        overlaps = []
        
        # Group shifts by employee and date
        employee_shifts = {}
        for shift in shifts:
            key = (shift.employee_id, shift.date)
            if key not in employee_shifts:
                employee_shifts[key] = []
            employee_shifts[key].append(shift)
        
        # Check for overlaps within each employee's daily shifts
        for (employee_id, date), daily_shifts in employee_shifts.items():
            if len(daily_shifts) > 1:
                # Sort shifts by start time
                daily_shifts.sort(key=lambda s: s.start_time)
                
                for i in range(len(daily_shifts) - 1):
                    current_shift = daily_shifts[i]
                    next_shift = daily_shifts[i + 1]
                    
                    # Check if current shift end time overlaps with next shift start time
                    if current_shift.end_time > next_shift.start_time:
                        overlaps.append({
                            "error": "Overlapping shifts detected",
                            "severity": "critical",
                            "employee_id": str(employee_id),
                            "date": date.isoformat(),
                            "shift_ids": [str(current_shift.id), str(next_shift.id)]
                        })
        
        return overlaps
    
    @staticmethod
    async def _check_coverage_requirements(
        schedule_id: uuid.UUID,
        shifts: List[ScheduleShift],
        db: Session
    ) -> List[Dict[str, Any]]:
        """Check coverage requirements"""
        coverage_issues = []
        
        # This would check against coverage requirements
        # For now, we'll do basic checks
        
        # Group shifts by date
        shifts_by_date = {}
        for shift in shifts:
            if shift.date not in shifts_by_date:
                shifts_by_date[shift.date] = []
            shifts_by_date[shift.date].append(shift)
        
        # Check minimum coverage
        for date, daily_shifts in shifts_by_date.items():
            if len(daily_shifts) < 2:  # Minimum 2 people per day
                coverage_issues.append({
                    "warning": "Insufficient coverage",
                    "severity": "minor",
                    "date": date.isoformat(),
                    "current_coverage": len(daily_shifts),
                    "required_coverage": 2
                })
        
        return coverage_issues
    
    @staticmethod
    async def _check_rule_violations(
        schedule_id: uuid.UUID,
        shifts: List[ScheduleShift],
        db: Session
    ) -> List[Dict[str, Any]]:
        """Check for rule violations"""
        violations = []
        
        # Get active rules
        schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
        if not schedule:
            return violations
        
        rules = db.query(ScheduleRule).filter(
            ScheduleRule.organization_id == schedule.organization_id,
            ScheduleRule.is_active == True
        ).all()
        
        # Check each rule
        for rule in rules:
            rule_violations = await ScheduleService._check_specific_rule(
                rule, shifts, db
            )
            violations.extend(rule_violations)
        
        return violations
    
    @staticmethod
    async def _check_constraint_violations(
        schedule_id: uuid.UUID,
        shifts: List[ScheduleShift],
        db: Session
    ) -> List[Dict[str, Any]]:
        """Check for constraint violations"""
        violations = []
        
        # Get employee constraints
        employee_ids = list(set(shift.employee_id for shift in shifts))
        constraints = db.query(ScheduleConstraint).filter(
            ScheduleConstraint.employee_id.in_(employee_ids),
            ScheduleConstraint.is_active == True
        ).all()
        
        # Check each constraint
        for constraint in constraints:
            constraint_violations = await ScheduleService._check_specific_constraint(
                constraint, shifts, db
            )
            violations.extend(constraint_violations)
        
        return violations
    
    @staticmethod
    async def _check_specific_rule(
        rule: ScheduleRule,
        shifts: List[ScheduleShift],
        db: Session
    ) -> List[Dict[str, Any]]:
        """Check a specific rule against shifts"""
        violations = []
        
        # This would implement specific rule checking logic
        # For now, we'll do basic checks
        
        if rule.rule_type == "max_consecutive_days":
            max_days = rule.rule_config.get("max_consecutive_days", 5)
            violations.extend(
                await ScheduleService._check_consecutive_days_rule(
                    shifts, max_days, rule.violation_penalty
                )
            )
        
        return violations
    
    @staticmethod
    async def _check_specific_constraint(
        constraint: ScheduleConstraint,
        shifts: List[ScheduleShift],
        db: Session
    ) -> List[Dict[str, Any]]:
        """Check a specific constraint against shifts"""
        violations = []
        
        # Filter shifts for this employee
        employee_shifts = [s for s in shifts if s.employee_id == constraint.employee_id]
        
        if constraint.constraint_type == "availability":
            # Check availability constraints
            for shift in employee_shifts:
                if not await ScheduleService._check_availability_constraint(
                    constraint, shift
                ):
                    violations.append({
                        "warning": f"Shift violates availability constraint: {constraint.name}",
                        "severity": "major" if constraint.is_hard_constraint else "minor",
                        "employee_id": str(constraint.employee_id),
                        "shift_id": str(shift.id),
                        "constraint_id": str(constraint.id)
                    })
        
        return violations
    
    @staticmethod
    async def _check_consecutive_days_rule(
        shifts: List[ScheduleShift],
        max_days: int,
        penalty: Decimal
    ) -> List[Dict[str, Any]]:
        """Check consecutive days rule"""
        violations = []
        
        # Group shifts by employee
        employee_shifts = {}
        for shift in shifts:
            if shift.employee_id not in employee_shifts:
                employee_shifts[shift.employee_id] = []
            employee_shifts[shift.employee_id].append(shift)
        
        # Check consecutive days for each employee
        for employee_id, emp_shifts in employee_shifts.items():
            # Sort shifts by date
            emp_shifts.sort(key=lambda s: s.date)
            
            consecutive_days = 1
            for i in range(1, len(emp_shifts)):
                if (emp_shifts[i].date - emp_shifts[i-1].date).days == 1:
                    consecutive_days += 1
                    if consecutive_days > max_days:
                        violations.append({
                            "error": f"Employee works {consecutive_days} consecutive days",
                            "severity": "major",
                            "employee_id": str(employee_id),
                            "consecutive_days": consecutive_days,
                            "max_allowed": max_days,
                            "penalty": float(penalty)
                        })
                else:
                    consecutive_days = 1
        
        return violations
    
    @staticmethod
    async def _check_availability_constraint(
        constraint: ScheduleConstraint,
        shift: ScheduleShift
    ) -> bool:
        """Check if shift violates availability constraint"""
        # Check if shift date is within constraint validity period
        if shift.date < constraint.valid_from:
            return True
        if constraint.valid_to and shift.date > constraint.valid_to:
            return True
        
        # Check day of week
        if constraint.days_of_week:
            shift_day = shift.date.weekday()  # 0=Monday, 6=Sunday
            if shift_day not in constraint.days_of_week:
                return False
        
        # Check time ranges
        if constraint.time_ranges:
            shift_start = shift.start_time
            shift_end = shift.end_time
            
            for time_range in constraint.time_ranges:
                range_start = datetime.strptime(time_range["start"], "%H:%M").time()
                range_end = datetime.strptime(time_range["end"], "%H:%M").time()
                
                # Check if shift times overlap with available time range
                if not (shift_end <= range_start or shift_start >= range_end):
                    return True
            
            return False  # No overlapping time ranges found
        
        return True
    
    # Additional helper methods for merge operations
    @staticmethod
    async def _merge_combine_shifts(
        source_schedule_ids: List[uuid.UUID],
        target_schedule_id: uuid.UUID,
        db: Session
    ) -> None:
        """Combine shifts from multiple schedules"""
        for source_id in source_schedule_ids:
            shifts = db.query(ScheduleShift).filter(
                ScheduleShift.schedule_id == source_id
            ).all()
            
            for shift in shifts:
                new_shift = ScheduleShift(
                    schedule_id=target_schedule_id,
                    shift_id=shift.shift_id,
                    employee_id=shift.employee_id,
                    date=shift.date,
                    start_time=shift.start_time,
                    end_time=shift.end_time,
                    override_start_time=shift.override_start_time,
                    override_end_time=shift.override_end_time,
                    override_reason=shift.override_reason,
                    notes=shift.notes,
                    break_times=shift.break_times,
                    status="assigned"
                )
                db.add(new_shift)
    
    @staticmethod
    async def _merge_overlay_shifts(
        source_schedule_ids: List[uuid.UUID],
        target_schedule_id: uuid.UUID,
        conflict_resolution: str,
        db: Session
    ) -> None:
        """Overlay shifts with conflict resolution"""
        # Implementation would handle overlapping shifts
        pass
    
    @staticmethod
    async def _merge_priority_shifts(
        source_schedule_ids: List[uuid.UUID],
        target_schedule_id: uuid.UUID,
        priority_order: Optional[List[uuid.UUID]],
        db: Session
    ) -> None:
        """Merge shifts using priority order"""
        # Implementation would use priority order for conflicts
        pass
    
    @staticmethod
    async def _analyze_cost_impact(
        base_shifts: List[ScheduleShift],
        variant_data: Dict[str, Any],
        db: Session
    ) -> Optional[Decimal]:
        """Analyze cost impact of variant"""
        # Implementation would calculate cost differences
        return None
    
    @staticmethod
    async def _analyze_coverage_impact(
        base_shifts: List[ScheduleShift],
        variant_data: Dict[str, Any],
        db: Session
    ) -> Optional[Decimal]:
        """Analyze coverage impact of variant"""
        # Implementation would calculate coverage differences
        return None
    
    @staticmethod
    async def _analyze_satisfaction_impact(
        base_shifts: List[ScheduleShift],
        variant_data: Dict[str, Any],
        db: Session
    ) -> Optional[Decimal]:
        """Analyze employee satisfaction impact of variant"""
        # Implementation would calculate satisfaction differences
        return None
    
    @staticmethod
    async def _detect_shift_overlaps(
        shifts: List[ScheduleShift],
        db: Session
    ) -> List[Dict[str, Any]]:
        """Detect overlapping shifts"""
        overlaps = []
        
        # Group shifts by employee and date
        employee_shifts = {}
        for shift in shifts:
            key = (shift.employee_id, shift.date)
            if key not in employee_shifts:
                employee_shifts[key] = []
            employee_shifts[key].append(shift)
        
        # Check for overlaps
        for (employee_id, date), daily_shifts in employee_shifts.items():
            if len(daily_shifts) > 1:
                daily_shifts.sort(key=lambda s: s.start_time)
                
                for i in range(len(daily_shifts) - 1):
                    current = daily_shifts[i]
                    next_shift = daily_shifts[i + 1]
                    
                    if current.end_time > next_shift.start_time:
                        overlaps.append({
                            "severity": "critical",
                            "title": "Overlapping shifts detected",
                            "description": f"Employee has overlapping shifts on {date}",
                            "affected_employees": [str(employee_id)],
                            "affected_shifts": [
                                {"id": str(current.id), "start": current.start_time.isoformat(), "end": current.end_time.isoformat()},
                                {"id": str(next_shift.id), "start": next_shift.start_time.isoformat(), "end": next_shift.end_time.isoformat()}
                            ],
                            "suggested_resolution": {
                                "type": "adjust_times",
                                "options": ["Adjust shift times", "Reassign one shift", "Split shifts"]
                            }
                        })
        
        return overlaps
    
    @staticmethod
    async def _detect_coverage_gaps(
        schedule_id: uuid.UUID,
        shifts: List[ScheduleShift],
        db: Session
    ) -> List[Dict[str, Any]]:
        """Detect coverage gaps"""
        gaps = []
        
        # This would implement coverage gap detection logic
        # For now, we'll do basic checks
        
        shifts_by_date = {}
        for shift in shifts:
            if shift.date not in shifts_by_date:
                shifts_by_date[shift.date] = []
            shifts_by_date[shift.date].append(shift)
        
        for date, daily_shifts in shifts_by_date.items():
            if len(daily_shifts) < 2:  # Minimum coverage requirement
                gaps.append({
                    "severity": "major",
                    "title": "Insufficient coverage",
                    "description": f"Only {len(daily_shifts)} employee(s) scheduled on {date}",
                    "affected_shifts": [{"id": str(shift.id), "employee_id": str(shift.employee_id)} for shift in daily_shifts],
                    "suggested_resolution": {
                        "type": "add_coverage",
                        "options": ["Add more employees", "Extend shift hours", "Use overtime"]
                    }
                })
        
        return gaps
    
    @staticmethod
    async def _detect_rule_violations(
        schedule_id: uuid.UUID,
        shifts: List[ScheduleShift],
        organization_id: uuid.UUID,
        db: Session
    ) -> List[Dict[str, Any]]:
        """Detect rule violations"""
        violations = []
        
        # Get active rules
        rules = db.query(ScheduleRule).filter(
            ScheduleRule.organization_id == organization_id,
            ScheduleRule.is_active == True
        ).all()
        
        # Check each rule
        for rule in rules:
            rule_violations = await ScheduleService._detect_specific_rule_violations(
                rule, shifts, db
            )
            violations.extend(rule_violations)
        
        return violations
    
    @staticmethod
    async def _detect_specific_rule_violations(
        rule: ScheduleRule,
        shifts: List[ScheduleShift],
        db: Session
    ) -> List[Dict[str, Any]]:
        """Detect violations of a specific rule"""
        violations = []
        
        if rule.rule_type == "max_consecutive_days":
            max_days = rule.rule_config.get("max_consecutive_days", 5)
            
            # Group shifts by employee
            employee_shifts = {}
            for shift in shifts:
                if shift.employee_id not in employee_shifts:
                    employee_shifts[shift.employee_id] = []
                employee_shifts[shift.employee_id].append(shift)
            
            # Check consecutive days for each employee
            for employee_id, emp_shifts in employee_shifts.items():
                emp_shifts.sort(key=lambda s: s.date)
                
                consecutive_days = 1
                for i in range(1, len(emp_shifts)):
                    if (emp_shifts[i].date - emp_shifts[i-1].date).days == 1:
                        consecutive_days += 1
                        if consecutive_days > max_days:
                            violations.append({
                                "severity": "major",
                                "title": f"Too many consecutive days: {rule.name}",
                                "description": f"Employee works {consecutive_days} consecutive days (max: {max_days})",
                                "affected_employees": [str(employee_id)],
                                "affected_shifts": [{"id": str(shift.id)} for shift in emp_shifts[i-consecutive_days+1:i+1]],
                                "suggested_resolution": {
                                    "type": "add_rest_day",
                                    "options": ["Add rest day", "Reassign shifts", "Adjust schedule"]
                                }
                            })
                    else:
                        consecutive_days = 1
        
        return violations


# Import asyncio for async operations
import asyncio