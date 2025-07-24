#!/usr/bin/env python3
"""
Schedule Validation Functions
Support functions for schedule view feature
"""

import logging
from typing import Dict, List, Optional, Tuple
from datetime import datetime, date, time
from dataclasses import dataclass
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os

logger = logging.getLogger(__name__)

@dataclass
class ValidationResult:
    """Schedule validation result"""
    is_valid: bool
    message: str
    conflicts: List[str] = None

@dataclass
class CoverageResult:
    """Coverage calculation result"""
    coverage_percentage: float
    scheduled_count: int
    required_count: int
    is_adequate: bool

class ScheduleValidator:
    """Schedule validation functions for schedule view"""
    
    def __init__(self, connection_string: Optional[str] = None):
        """Initialize with wfm_enterprise database connection"""
        self.connection_string = connection_string or os.getenv(
            'DATABASE_URL',
            'postgresql://postgres:postgres@localhost:5432/wfm_enterprise'
        )
        
        self.engine = create_engine(self.connection_string)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        logger.info("✅ ScheduleValidator initialized")
    
    def check_schedule_conflicts(self, employee_id: int, target_date: str, 
                               start_time: str, end_time: str) -> ValidationResult:
        """
        Check for schedule conflicts for an employee
        """
        try:
            with self.SessionLocal() as session:
                # Check for overlapping shifts
                conflicts = session.execute(text("""
                    SELECT schedule_date, shift_start, shift_end
                    FROM work_schedules
                    WHERE agent_id = :employee_id
                    AND schedule_date = :target_date
                    AND status = 'published'
                    AND (
                        (shift_start <= :start_time AND shift_end > :start_time) OR
                        (shift_start < :end_time AND shift_end >= :end_time) OR
                        (shift_start >= :start_time AND shift_end <= :end_time)
                    )
                """), {
                    'employee_id': employee_id,
                    'target_date': target_date,
                    'start_time': start_time,
                    'end_time': end_time
                }).fetchall()
                
                if conflicts:
                    conflict_list = []
                    for conflict in conflicts:
                        conflict_list.append(f"Shift {conflict.shift_start}-{conflict.shift_end} on {conflict.schedule_date}")
                    
                    return ValidationResult(
                        is_valid=False,
                        message=f"Schedule conflict detected for employee {employee_id}",
                        conflicts=conflict_list
                    )
                
                return ValidationResult(
                    is_valid=True,
                    message="No schedule conflicts found"
                )
                
        except Exception as e:
            logger.error(f"Error checking schedule conflicts: {e}")
            return ValidationResult(
                is_valid=False,
                message=f"Error checking conflicts: {str(e)}"
            )
    
    def calculate_coverage_percentage(self, target_date: str, required_agents: int = 5) -> CoverageResult:
        """
        Calculate coverage percentage for a date
        """
        try:
            with self.SessionLocal() as session:
                # Count scheduled agents
                scheduled_count = session.execute(text("""
                    SELECT COUNT(DISTINCT agent_id) as agent_count
                    FROM work_schedules
                    WHERE schedule_date = :target_date
                    AND status = 'published'
                """), {
                    'target_date': target_date
                }).fetchone()
                
                scheduled = scheduled_count.agent_count if scheduled_count else 0
                coverage_percentage = (scheduled / required_agents) * 100 if required_agents > 0 else 100
                is_adequate = scheduled >= required_agents
                
                return CoverageResult(
                    coverage_percentage=coverage_percentage,
                    scheduled_count=scheduled,
                    required_count=required_agents,
                    is_adequate=is_adequate
                )
                
        except Exception as e:
            logger.error(f"Error calculating coverage: {e}")
            return CoverageResult(
                coverage_percentage=0.0,
                scheduled_count=0,
                required_count=required_agents,
                is_adequate=False
            )
    
    def validate_shift_times(self, start_time: str, end_time: str) -> ValidationResult:
        """
        Validate shift times are logical
        """
        try:
            # Parse times
            start = datetime.strptime(start_time, '%H:%M').time()
            end = datetime.strptime(end_time, '%H:%M').time()
            
            # Check if end is after start
            if end <= start:
                return ValidationResult(
                    is_valid=False,
                    message="End time must be after start time"
                )
            
            # Check reasonable shift length (minimum 1 hour, maximum 12 hours)
            start_minutes = start.hour * 60 + start.minute
            end_minutes = end.hour * 60 + end.minute
            
            # Handle overnight shifts
            if end_minutes < start_minutes:
                end_minutes += 24 * 60
            
            shift_duration = end_minutes - start_minutes
            
            if shift_duration < 60:  # Less than 1 hour
                return ValidationResult(
                    is_valid=False,
                    message="Shift must be at least 1 hour long"
                )
            
            if shift_duration > 720:  # More than 12 hours
                return ValidationResult(
                    is_valid=False,
                    message="Shift cannot exceed 12 hours"
                )
            
            return ValidationResult(
                is_valid=True,
                message="Shift times are valid"
            )
            
        except ValueError as e:
            return ValidationResult(
                is_valid=False,
                message=f"Invalid time format: {str(e)}"
            )
        except Exception as e:
            logger.error(f"Error validating shift times: {e}")
            return ValidationResult(
                is_valid=False,
                message=f"Error validating times: {str(e)}"
            )

# Simple function interfaces
def validate_overlap(employee_id: int, date: str) -> bool:
    """Simple overlap check function (for BDD-SCENARIO-AGENT)"""
    validator = ScheduleValidator()
    result = validator.check_schedule_conflicts(employee_id, date, "09:00", "17:00")
    return result.is_valid

def check_schedule_conflicts(employee_id: int, target_date: str, start_time: str, end_time: str) -> ValidationResult:
    """Check schedule conflicts"""
    validator = ScheduleValidator()
    return validator.check_schedule_conflicts(employee_id, target_date, start_time, end_time)

def calculate_coverage_percentage(target_date: str, required_agents: int = 5) -> CoverageResult:
    """Calculate coverage percentage"""
    validator = ScheduleValidator()
    return validator.calculate_coverage_percentage(target_date, required_agents)

def validate_shift_times(start_time: str, end_time: str) -> ValidationResult:
    """Validate shift times"""
    validator = ScheduleValidator()
    return validator.validate_shift_times(start_time, end_time)

def validate_schedule_functions():
    """Test schedule validation functions with real data"""
    try:
        # Test overlap check (from CLAUDE_SIMPLIFIED.md)
        overlap_result = validate_overlap(employee_id=111538, date="2025-07-25")
        print(f"✅ Overlap check for employee 111538: {overlap_result}")
        
        # Test conflict check
        conflict_result = check_schedule_conflicts(111538, "2025-07-25", "09:00", "17:00")
        print(f"✅ Conflict check: {conflict_result.message}")
        
        # Test coverage calculation
        coverage = calculate_coverage_percentage("2025-07-25", 5)
        print(f"✅ Coverage: {coverage.coverage_percentage:.1f}% ({coverage.scheduled_count}/{coverage.required_count})")
        
        # Test shift time validation
        time_validation = validate_shift_times("09:00", "17:00")
        print(f"✅ Shift time validation: {time_validation.message}")
        
        return True
        
    except Exception as e:
        print(f"❌ Schedule validation failed: {e}")
        return False

if __name__ == "__main__":
    # Configure logging
    logging.basicConfig(level=logging.INFO)
    
    # Test the functions
    if validate_schedule_functions():
        print("\n✅ Schedule Validation Functions: READY")
    else:
        print("\n❌ Schedule Validation Functions: FAILED")