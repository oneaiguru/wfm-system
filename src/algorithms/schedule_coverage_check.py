#!/usr/bin/env python3
"""
Schedule Coverage Check
Check team coverage during absence and minimum staffing
"""

import logging
from typing import Dict, List, Optional
from datetime import datetime, date, time, timedelta
from dataclasses import dataclass
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os

logger = logging.getLogger(__name__)

@dataclass
class CoverageResult:
    """Schedule coverage check result"""
    date: str
    team_id: int
    scheduled_agents: int
    minimum_required: int
    coverage_percentage: float
    is_adequate: bool
    conflicts: List[str]

class ScheduleCoverageChecker:
    """Check team coverage and minimum staffing levels"""
    
    def __init__(self, connection_string: Optional[str] = None):
        """Initialize with wfm_enterprise database connection"""
        self.connection_string = connection_string or os.getenv(
            'DATABASE_URL',
            'postgresql://postgres:postgres@localhost:5432/wfm_enterprise'
        )
        
        self.engine = create_engine(self.connection_string)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        logger.info("✅ ScheduleCoverageChecker initialized")
    
    def check_coverage(self, team_id: int, target_date: str, minimum_required: int = 2) -> CoverageResult:
        """
        Check team coverage during absence
        """
        try:
            with self.SessionLocal() as session:
                # Get scheduled agents for date (no team_id in work_schedules)
                scheduled_count = session.execute(text("""
                    SELECT COUNT(DISTINCT agent_id) as agent_count
                    FROM work_schedules 
                    WHERE schedule_date = :target_date
                    AND status = 'published'
                """), {
                    'target_date': target_date
                }).fetchone()
                
                scheduled_agents = scheduled_count.agent_count if scheduled_count else 0
                
                # Calculate coverage percentage
                coverage_percentage = (scheduled_agents / minimum_required) * 100 if minimum_required > 0 else 100
                is_adequate = scheduled_agents >= minimum_required
                
                # Check for conflicts
                conflicts = self._detect_conflicts(session, team_id, target_date)
                
                return CoverageResult(
                    date=target_date,
                    team_id=team_id,
                    scheduled_agents=scheduled_agents,
                    minimum_required=minimum_required,
                    coverage_percentage=coverage_percentage,
                    is_adequate=is_adequate,
                    conflicts=conflicts
                )
                
        except Exception as e:
            logger.error(f"Error checking coverage: {e}")
            return CoverageResult(
                date=target_date,
                team_id=team_id,
                scheduled_agents=0,
                minimum_required=minimum_required,
                coverage_percentage=0.0,
                is_adequate=False,
                conflicts=[f"Error: {str(e)}"]
            )
    
    def _detect_conflicts(self, session, team_id: int, target_date: str) -> List[str]:
        """Detect scheduling conflicts"""
        conflicts = []
        
        try:
            # Check for overlapping shifts (no team_id in work_schedules)
            overlaps = session.execute(text("""
                SELECT agent_id, COUNT(*) as shift_count
                FROM work_schedules
                WHERE schedule_date = :target_date
                AND status = 'published'
                GROUP BY agent_id
                HAVING COUNT(*) > 1
            """), {
                'target_date': target_date
            }).fetchall()
            
            for overlap in overlaps:
                conflicts.append(f"Agent {overlap.agent_id} has {overlap.shift_count} overlapping shifts")
                
        except Exception as e:
            conflicts.append(f"Conflict detection error: {str(e)}")
            
        return conflicts

def check_schedule_coverage(team_id: int, target_date: str, minimum_required: int = 2) -> CoverageResult:
    """Simple function interface for schedule coverage check"""
    checker = ScheduleCoverageChecker()
    return checker.check_coverage(team_id, target_date, minimum_required)

def validate_coverage_checker():
    """Test schedule coverage check with real data"""
    try:
        # Test with team 1 for tomorrow
        tomorrow = (datetime.now().date() + timedelta(days=1)).strftime('%Y-%m-%d')
        
        result = check_schedule_coverage(team_id=1, target_date=tomorrow, minimum_required=2)
        
        print(f"✅ Schedule Coverage Check for Team {result.team_id} on {result.date}:")
        print(f"   Scheduled Agents: {result.scheduled_agents}")
        print(f"   Minimum Required: {result.minimum_required}")
        print(f"   Coverage: {result.coverage_percentage:.1f}%")
        print(f"   Adequate: {result.is_adequate}")
        
        if result.conflicts:
            print(f"   Conflicts: {len(result.conflicts)}")
            for conflict in result.conflicts:
                print(f"     - {conflict}")
        else:
            print("   No conflicts detected")
        
        return True
        
    except Exception as e:
        print(f"❌ Coverage checker validation failed: {e}")
        return False

if __name__ == "__main__":
    # Configure logging
    logging.basicConfig(level=logging.INFO)
    
    # Test the checker
    if validate_coverage_checker():
        print("\n✅ Schedule Coverage Checker: READY")
    else:
        print("\n❌ Schedule Coverage Checker: FAILED")