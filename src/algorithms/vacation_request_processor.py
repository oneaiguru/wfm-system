#!/usr/bin/env python3
"""
Vacation Request Processing Algorithm
SPEC-02: Employee Vacation Request business logic integration
Combines vacation balance, conflict detection, and auto-approval rules
"""

import logging
from typing import Dict, List, Optional, Tuple, Any
from datetime import datetime, date, timedelta
from dataclasses import dataclass
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os

# Import handling for both module and direct execution
try:
    from .vacation_balance_calc import VacationBalanceCalculator, VacationBalance
    from .schedule_analysis_engine import detect_schedule_conflicts, ConflictInfo
    from .approval_workflow_manager import ApprovalWorkflowManager, WorkflowStage, Priority
except ImportError:
    import sys
    import os
    sys.path.append(os.path.dirname(__file__))
    from vacation_balance_calc import VacationBalanceCalculator, VacationBalance
    from schedule_analysis_engine import detect_schedule_conflicts, ConflictInfo
    from approval_workflow_manager import ApprovalWorkflowManager, WorkflowStage, Priority

logger = logging.getLogger(__name__)

@dataclass
class VacationRequestValidation:
    """Vacation request validation result"""
    is_valid: bool
    balance_check: VacationBalance
    conflicts: List[ConflictInfo]
    auto_approval_eligible: bool
    approval_stage: WorkflowStage
    validation_messages: List[str]
    recommendation: str

class VacationRequestProcessor:
    """Process vacation requests with business rules"""
    
    def __init__(self, connection_string: Optional[str] = None):
        """Initialize with database connection"""
        self.connection_string = connection_string or os.getenv(
            'DATABASE_URL',
            'postgresql://postgres:postgres@localhost:5432/wfm_enterprise'
        )
        
        # Initialize sub-components
        self.balance_calculator = VacationBalanceCalculator(self.connection_string)
        self.workflow_manager = ApprovalWorkflowManager(self.connection_string)
        
        logger.info("✅ VacationRequestProcessor initialized")
    
    def validate_vacation_request(
        self, 
        employee_id: int, 
        start_date: date, 
        end_date: date,
        request_type: str = "vacation"
    ) -> VacationRequestValidation:
        """
        Complete vacation request validation
        BDD Compliance: 02-employee-requests.feature
        """
        validation_messages = []
        
        try:
            # Step 1: Check vacation balance
            balance = self.balance_calculator.calculate_balance(employee_id)
            requested_days = (end_date - start_date).days + 1
            
            # Balance validation
            balance_valid = balance.remaining_days >= requested_days
            if not balance_valid:
                validation_messages.append(
                    f"Insufficient balance: {requested_days} days requested, "
                    f"{balance.remaining_days} days available"
                )
            
            # Step 2: Check for schedule conflicts
            conflicts = detect_schedule_conflicts(
                employee_id, start_date.strftime('%Y-%m-%d')
            )
            
            if conflicts:
                validation_messages.append(
                    f"Found {len(conflicts)} schedule conflicts in requested period"
                )
                for conflict in conflicts:
                    validation_messages.append(f"  - {conflict.description}")
            
            # Step 3: Determine auto-approval eligibility
            auto_approval_eligible = self._check_auto_approval_rules(
                employee_id, start_date, end_date, requested_days, balance, conflicts
            )
            
            # Step 4: Determine workflow stage
            if auto_approval_eligible:
                approval_stage = WorkflowStage.COMPLETED
                validation_messages.append("✅ Auto-approval criteria met")
            elif not balance_valid or len(conflicts) > 2:
                approval_stage = WorkflowStage.SUPERVISOR_REVIEW
                validation_messages.append("⚠️ Requires supervisor review")
            else:
                approval_stage = WorkflowStage.PLANNING_REVIEW
                validation_messages.append("📋 Standard approval process")
            
            # Step 5: Generate recommendation
            recommendation = self._generate_recommendation(
                balance_valid, conflicts, auto_approval_eligible, requested_days
            )
            
            # Overall validation
            is_valid = balance_valid and len(conflicts) == 0
            
            return VacationRequestValidation(
                is_valid=is_valid,
                balance_check=balance,
                conflicts=conflicts,
                auto_approval_eligible=auto_approval_eligible,
                approval_stage=approval_stage,
                validation_messages=validation_messages,
                recommendation=recommendation
            )
            
        except Exception as e:
            logger.error(f"Error validating vacation request: {e}")
            return VacationRequestValidation(
                is_valid=False,
                balance_check=VacationBalance(employee_id, 0, 0, 0, 0, 2025),
                conflicts=[],
                auto_approval_eligible=False,
                approval_stage=WorkflowStage.SUPERVISOR_REVIEW,
                validation_messages=[f"Validation error: {str(e)}"],
                recommendation="Manual review required due to system error"
            )
    
    def _check_auto_approval_rules(
        self, 
        employee_id: int, 
        start_date: date, 
        end_date: date, 
        requested_days: int,
        balance: VacationBalance,
        conflicts: List[ConflictInfo]
    ) -> bool:
        """
        Check if vacation request meets auto-approval criteria
        """
        try:
            # Rule 1: No conflicts allowed for auto-approval
            if conflicts:
                return False
            
            # Rule 2: Must have sufficient balance
            if balance.remaining_days < requested_days:
                return False
            
            # Rule 3: Request must be <= 5 days for auto-approval
            if requested_days > 5:
                return False
            
            # Rule 4: Must be at least 2 weeks in advance
            advance_days = (start_date - date.today()).days
            if advance_days < 14:
                return False
            
            # Rule 5: Not during blackout periods (simplified)
            # Check if request overlaps with holiday season
            blackout_periods = [
                (date(2025, 12, 15), date(2026, 1, 10)),  # Holiday season
                (date(2025, 6, 1), date(2025, 8, 31)),    # Summer (limited auto-approval)
            ]
            
            for blackout_start, blackout_end in blackout_periods:
                if start_date <= blackout_end and end_date >= blackout_start:
                    if requested_days > 3:  # Only short requests during blackout
                        return False
            
            return True
            
        except Exception as e:
            logger.error(f"Error checking auto-approval rules: {e}")
            return False
    
    def _generate_recommendation(
        self, 
        balance_valid: bool, 
        conflicts: List[ConflictInfo], 
        auto_approval_eligible: bool,
        requested_days: int
    ) -> str:
        """Generate recommendation for vacation request"""
        
        if auto_approval_eligible:
            return "✅ APPROVE AUTOMATICALLY - All criteria met"
        
        if not balance_valid:
            return "❌ REJECT - Insufficient vacation balance"
        
        if len(conflicts) > 2:
            return "⚠️ REVIEW REQUIRED - Multiple schedule conflicts detected"
        
        if len(conflicts) == 1:
            return "📋 MINOR CONFLICTS - Consider alternative dates or approve with conditions"
        
        if requested_days > 10:
            return "📊 EXTENDED LEAVE - Review team coverage and impact"
        
        return "✅ APPROVE - Standard request meets all basic criteria"

def process_vacation_request(
    employee_id: int, 
    start_date: date, 
    end_date: date,
    request_type: str = "vacation"
) -> VacationRequestValidation:
    """Simple function interface for vacation request processing"""
    processor = VacationRequestProcessor()
    return processor.validate_vacation_request(employee_id, start_date, end_date, request_type)

def validate_vacation_processor():
    """Test vacation request processor with real data"""
    try:
        # Test with employee 111538 requesting 3 days off next month
        start_date = date.today() + timedelta(days=30)
        end_date = start_date + timedelta(days=2)
        
        result = process_vacation_request(111538, start_date, end_date)
        
        print(f"✅ Vacation Request Validation for Employee 111538:")
        print(f"   Request: {start_date} to {end_date}")
        print(f"   Valid: {result.is_valid}")
        print(f"   Auto-approval: {result.auto_approval_eligible}")
        print(f"   Approval stage: {result.approval_stage.value}")
        print(f"   Available balance: {result.balance_check.remaining_days} days")
        print(f"   Conflicts found: {len(result.conflicts)}")
        print(f"   Recommendation: {result.recommendation}")
        print(f"   Messages:")
        for msg in result.validation_messages:
            print(f"     - {msg}")
        
        return True
        
    except Exception as e:
        print(f"❌ Vacation processor validation failed: {e}")
        return False

if __name__ == "__main__":
    # Configure logging
    logging.basicConfig(level=logging.INFO)
    
    # Test the processor
    if validate_vacation_processor():
        print("\n✅ Vacation Request Processor: READY")
    else:
        print("\n❌ Vacation Request Processor: FAILED")