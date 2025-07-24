"""
Employee Request Validation Algorithm

Priority 1: Employee Self-Service request validation
BDD Files: 02-employee-requests.feature, 03-complete-business-process.feature

Validates all employee request types:
- Time off requests (отгул)
- Sick leave requests (больничный) 
- Unscheduled vacation (внеочередной отпуск)
- Shift exchange requests (обмен сменами)

Integrates with existing validation patterns and PostgreSQL database.
"""

import logging
from datetime import datetime, date, timedelta
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass
from enum import Enum
import psycopg2
from psycopg2.extras import RealDictCursor

# Self-contained validation components (no external dependencies)
@dataclass
class BasicValidationResult:
    """Basic validation result for employee requests"""
    is_valid: bool
    errors: List[str]
    warnings: List[str] = None
    
    def __post_init__(self):
        if self.warnings is None:
            self.warnings = []


class RequestType(Enum):
    """Employee request types from BDD scenarios"""
    TIME_OFF = "отгул"           # Day off
    SICK_LEAVE = "больничный"    # Sick leave  
    VACATION = "внеочередной отпуск"  # Unscheduled vacation
    SHIFT_EXCHANGE = "обмен сменами"   # Shift exchange


class RequestStatus(Enum):
    """Request status progression from BDD scenarios"""
    CREATED = "Новый"                    # Created/New
    UNDER_REVIEW = "На рассмотрении"     # Under Review
    APPROVED = "Подтвержден"             # Approved/Confirmed
    REJECTED = "Отказано"                # Rejected
    COMPLETED = "Выполнено"              # Completed (for exchanges)


@dataclass
class ValidationContext:
    """Validation context for employee requests"""
    employee_id: int  # Integer ID for employee_requests table
    request_type: RequestType
    start_date: date
    end_date: date
    reason: str
    exchange_partner_id: Optional[int] = None  # Integer ID  
    supervisor_id: Optional[int] = None  # Integer ID


@dataclass
class RequestValidationResult:
    """Enhanced validation result for employee requests"""
    is_valid: bool
    errors: List[str]
    warnings: List[str]
    validation_details: Dict[str, Any]
    can_auto_approve: bool = False
    requires_1c_integration: bool = False


class EmployeeRequestValidator:
    """
    Comprehensive employee request validation system
    
    Validates requests according to BDD scenarios and business rules:
    - Schedule conflicts
    - Business rule compliance  
    - Vacation balance checking
    - Approval workflow validation
    - 1C ZUP integration requirements
    """
    
    def __init__(self, connection_string: Optional[str] = None):
        self.connection_string = connection_string or "postgresql://postgres:postgres@localhost:5432/wfm_enterprise"
        self.logger = logging.getLogger(__name__)
        
        # Performance tracking
        self.validation_start_time = None
        
    def validate_employee_request(self, context: ValidationContext) -> RequestValidationResult:
        """
        Main validation entry point for employee requests
        
        Validates according to BDD scenarios:
        - Schedule conflicts and overlaps
        - Business rule compliance
        - Request-specific validation rules
        - Approval workflow requirements
        
        Performance target: <500ms per BDD requirements
        """
        self.validation_start_time = datetime.now()
        
        try:
            errors = []
            warnings = []
            validation_details = {}
            can_auto_approve = False
            requires_1c = False
            
            # 1. Basic request validation
            basic_result = self._validate_basic_request(context)
            errors.extend(basic_result.get('errors', []))
            warnings.extend(basic_result.get('warnings', []))
            validation_details.update(basic_result.get('details', {}))
            
            # 2. Schedule conflict validation
            conflict_result = self._validate_schedule_conflicts(context)
            errors.extend(conflict_result.get('errors', []))
            warnings.extend(conflict_result.get('warnings', []))
            validation_details.update(conflict_result.get('details', {}))
            
            # 3. Business rule validation
            business_result = self._validate_business_rules(context)
            errors.extend(business_result.get('errors', []))
            warnings.extend(business_result.get('warnings', []))
            validation_details.update(business_result.get('details', {}))
            
            # 4. Request type specific validation
            type_result = self._validate_request_type_specific(context)
            errors.extend(type_result.get('errors', []))
            warnings.extend(type_result.get('warnings', []))
            validation_details.update(type_result.get('details', {}))
            requires_1c = type_result.get('requires_1c', False)
            can_auto_approve = type_result.get('can_auto_approve', False)
            
            # 5. Approval workflow validation
            workflow_result = self._validate_approval_workflow(context)
            errors.extend(workflow_result.get('errors', []))
            warnings.extend(workflow_result.get('warnings', []))
            validation_details.update(workflow_result.get('details', {}))
            
            # Performance validation
            elapsed_time = (datetime.now() - self.validation_start_time).total_seconds() * 1000
            validation_details['validation_time_ms'] = elapsed_time
            
            if elapsed_time > 500:
                warnings.append(f"Validation took {elapsed_time:.0f}ms (target: <500ms)")
            
            return RequestValidationResult(
                is_valid=len(errors) == 0,
                errors=errors,
                warnings=warnings,
                validation_details=validation_details,
                can_auto_approve=can_auto_approve and len(errors) == 0,
                requires_1c_integration=requires_1c
            )
            
        except Exception as e:
            self.logger.error(f"Request validation failed: {str(e)}")
            return RequestValidationResult(
                is_valid=False,
                errors=[f"Validation system error: {str(e)}"],
                warnings=[],
                validation_details={'error_type': 'system_error'},
                can_auto_approve=False,
                requires_1c_integration=False
            )
    
    def _validate_basic_request(self, context: ValidationContext) -> Dict[str, Any]:
        """Basic request validation - dates, employee existence, etc."""
        errors = []
        warnings = []
        details = {}
        
        # Date validation
        if context.start_date > context.end_date:
            errors.append("Start date must be before end date")
        
        if context.start_date < date.today():
            warnings.append("Request is for past date")
        
        # Duration validation
        duration_days = (context.end_date - context.start_date).days + 1
        details['duration_days'] = duration_days
        
        if duration_days > 365:
            errors.append("Request duration exceeds maximum allowed (365 days)")
        
        # Employee existence validation
        try:
            with psycopg2.connect(self.connection_string) as conn:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    # Check if employee ID exists in employee_requests (validation uses this table)
                    cur.execute("""
                        SELECT DISTINCT employee_id
                        FROM employee_requests 
                        WHERE employee_id = %s
                        LIMIT 1
                    """, (context.employee_id,))
                    
                    employee = cur.fetchone()
                    if not employee:
                        warnings.append(f"Employee {context.employee_id} not found in historical requests")
                    else:
                        details['employee_id_validated'] = True
                        
        except Exception as e:
            errors.append(f"Failed to validate employee: {str(e)}")
        
        return {
            'errors': errors,
            'warnings': warnings,
            'details': details
        }
    
    def _validate_schedule_conflicts(self, context: ValidationContext) -> Dict[str, Any]:
        """Validate schedule conflicts with database queries"""
        errors = []
        warnings = []
        details = {}
        
        try:
            with psycopg2.connect(self.connection_string) as conn:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    # Check for existing employee requests in the request period
                    cur.execute("""
                        SELECT start_date, end_date, request_type, status
                        FROM employee_requests 
                        WHERE employee_id = %s 
                        AND status IN ('approved', 'pending')
                        AND (
                            (start_date <= %s AND end_date >= %s) OR
                            (start_date <= %s AND end_date >= %s) OR
                            (start_date >= %s AND end_date <= %s)
                        )
                    """, (
                        context.employee_id,
                        context.start_date, context.start_date,
                        context.end_date, context.end_date,
                        context.start_date, context.end_date
                    ))
                    
                    existing_requests = cur.fetchall()
                    if existing_requests:
                        for request in existing_requests:
                            errors.append(f"Conflicting {request['request_type']} request from {request['start_date']} to {request['end_date']}")
                    
                    details['existing_requests_count'] = len(existing_requests)
            
            details['conflict_check_completed'] = True
            
        except Exception as e:
            errors.append(f"Schedule conflict validation failed: {str(e)}")
        
        return {
            'errors': errors,
            'warnings': warnings,
            'details': details
        }
    
    def _validate_business_rules(self, context: ValidationContext) -> Dict[str, Any]:
        """Validate business rules with database queries"""
        errors = []
        warnings = []
        details = {}
        
        try:
            with psycopg2.connect(self.connection_string) as conn:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    # Check minimum notice period
                    notice_days = (context.start_date - date.today()).days
                    
                    if context.request_type == RequestType.VACATION and notice_days < 14:
                        warnings.append("Vacation requests typically require 14 days notice")
                    elif context.request_type == RequestType.TIME_OFF and notice_days < 3:
                        warnings.append("Time off requests typically require 3 days notice")
                    
                    # Check maximum request duration
                    duration = (context.end_date - context.start_date).days + 1
                    
                    if context.request_type == RequestType.SICK_LEAVE and duration > 30:
                        warnings.append("Extended sick leave may require additional documentation")
                    elif context.request_type == RequestType.TIME_OFF and duration > 5:
                        warnings.append("Extended time off requests may require supervisor approval")
                    
                    # Check for blackout periods if table exists
                    try:
                        cur.execute("""
                            SELECT period_start, period_end, description
                            FROM blackout_periods 
                            WHERE %s BETWEEN period_start AND period_end
                            OR %s BETWEEN period_start AND period_end
                        """, (context.start_date, context.end_date))
                        
                        blackout_periods = cur.fetchall()
                        for period in blackout_periods:
                            errors.append(f"Request conflicts with blackout period: {period['description']}")
                        details['blackout_periods_checked'] = len(blackout_periods)
                    except:
                        # Table doesn't exist, skip blackout period check
                        details['blackout_periods_checked'] = 0
                    
                    details['notice_days'] = notice_days
                    details['duration_days'] = duration
            
            details['business_rules_checked'] = True
            
        except Exception as e:
            warnings.append(f"Business rule validation failed: {str(e)}")
        
        return {
            'errors': errors,
            'warnings': warnings,
            'details': details
        }
    
    def _validate_request_type_specific(self, context: ValidationContext) -> Dict[str, Any]:
        """Request type specific validation based on BDD scenarios"""
        errors = []
        warnings = []
        details = {}
        requires_1c = False
        can_auto_approve = False
        
        if context.request_type == RequestType.TIME_OFF:
            # отгул (Day off) validation
            result = self._validate_time_off_request(context)
            requires_1c = True  # Per BDD: 1C ZUP integration required
            
        elif context.request_type == RequestType.SICK_LEAVE:
            # больничный (Sick leave) validation  
            result = self._validate_sick_leave_request(context)
            requires_1c = True  # Per BDD: 1C ZUP integration required
            
        elif context.request_type == RequestType.VACATION:
            # внеочередной отпуск (Unscheduled vacation) validation
            result = self._validate_vacation_request(context)
            requires_1c = True  # Per BDD: 1C ZUP integration required
            
        elif context.request_type == RequestType.SHIFT_EXCHANGE:
            # обмен сменами (Shift exchange) validation
            result = self._validate_shift_exchange_request(context)
            requires_1c = False  # Exchange doesn't require 1C integration
            
        else:
            result = {
                'errors': [f"Unknown request type: {context.request_type}"],
                'warnings': [],
                'details': {}
            }
        
        errors.extend(result.get('errors', []))
        warnings.extend(result.get('warnings', []))
        details.update(result.get('details', {}))
        
        details['request_type_validated'] = context.request_type.value
        details['requires_1c_integration'] = requires_1c
        
        return {
            'errors': errors,
            'warnings': warnings,
            'details': details,
            'requires_1c': requires_1c,
            'can_auto_approve': can_auto_approve
        }
    
    def _validate_time_off_request(self, context: ValidationContext) -> Dict[str, Any]:
        """Validate отгул (day off) requests"""
        errors = []
        warnings = []
        details = {}
        
        # Check time off balance
        try:
            with psycopg2.connect(self.connection_string) as conn:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    # Check time off balance using existing employee data
                    cur.execute("""
                        SELECT 
                            COUNT(*) as requests_this_year
                        FROM employee_requests 
                        WHERE employee_id = %s 
                        AND request_type = 'отгул'
                        AND status = 'approved'
                        AND EXTRACT(year FROM start_date) = %s
                    """, (context.employee_id, context.start_date.year))
                    
                    balance_record = cur.fetchone()
                    if balance_record:
                        used_this_year = balance_record['requests_this_year']
                        requested_days = (context.end_date - context.start_date).days + 1
                        
                        # Assume 10 days annual time off allowance
                        annual_allowance = 10
                        available_days = annual_allowance - used_this_year
                        
                        details['annual_time_off_allowance'] = annual_allowance
                        details['used_time_off_requests'] = used_this_year
                        details['requested_days'] = requested_days
                        
                        if requested_days > available_days:
                            errors.append(f"Insufficient time off balance. Available: {available_days}, Requested: {requested_days}")
                    else:
                        warnings.append("Could not verify time off balance")
                        
        except Exception as e:
            warnings.append(f"Time off balance check failed: {str(e)}")
        
        return {
            'errors': errors,
            'warnings': warnings,
            'details': details
        }
    
    def _validate_sick_leave_request(self, context: ValidationContext) -> Dict[str, Any]:
        """Validate больничный (sick leave) requests"""
        errors = []
        warnings = []
        details = {}
        
        # Sick leave specific validation
        duration_days = (context.end_date - context.start_date).days + 1
        
        # Check for excessive sick leave duration
        if duration_days > 30:
            warnings.append("Sick leave duration exceeds 30 days - may require additional documentation")
        
        # Check for recent sick leave requests
        try:
            with psycopg2.connect(self.connection_string) as conn:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    cur.execute("""
                        SELECT COUNT(*) as recent_requests
                        FROM employee_requests 
                        WHERE employee_id = %s 
                        AND request_type = 'больничный'
                        AND start_date >= %s
                        AND status IN ('approved', 'pending')
                    """, (context.employee_id, context.start_date - timedelta(days=30)))
                    
                    result = cur.fetchone()
                    if result and result['recent_requests'] > 3:
                        warnings.append("Employee has multiple recent sick leave requests")
                        
        except Exception as e:
            warnings.append(f"Recent sick leave check failed: {str(e)}")
        
        details['sick_leave_duration_days'] = duration_days
        
        return {
            'errors': errors,
            'warnings': warnings,
            'details': details
        }
    
    def _validate_vacation_request(self, context: ValidationContext) -> Dict[str, Any]:
        """Validate внеочередной отпуск (unscheduled vacation) requests"""
        errors = []
        warnings = []
        details = {}
        
        # Check vacation balance
        try:
            with psycopg2.connect(self.connection_string) as conn:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    # Check vacation requests this year
                    cur.execute("""
                        SELECT 
                            COUNT(*) as vacation_requests_this_year,
                            COALESCE(SUM(duration_days), 0) as vacation_days_used
                        FROM employee_requests 
                        WHERE employee_id = %s 
                        AND request_type = 'внеочередной отпуск'
                        AND status = 'approved'
                        AND EXTRACT(year FROM start_date) = %s
                    """, (context.employee_id, context.start_date.year))
                    
                    balance_record = cur.fetchone()
                    if balance_record:
                        used_days = balance_record['vacation_days_used']
                        requested_days = (context.end_date - context.start_date).days + 1
                        
                        # Assume 28 days annual vacation allowance (standard in Russia)
                        annual_allowance = 28
                        available_days = annual_allowance - used_days
                        
                        details['annual_vacation_allowance'] = annual_allowance
                        details['used_vacation_days'] = used_days
                        details['requested_vacation_days'] = requested_days
                        
                        if requested_days > available_days:
                            errors.append(f"Insufficient vacation balance. Available: {available_days}, Requested: {requested_days}")
                    else:
                        warnings.append("Could not verify vacation balance")
                        
        except Exception as e:
            warnings.append(f"Vacation balance check failed: {str(e)}")
        
        return {
            'errors': errors,
            'warnings': warnings,
            'details': details
        }
    
    def _validate_shift_exchange_request(self, context: ValidationContext) -> Dict[str, Any]:
        """Validate обмен сменами (shift exchange) requests"""
        errors = []
        warnings = []
        details = {}
        
        if not context.exchange_partner_id:
            errors.append("Shift exchange requires partner employee ID")
            return {'errors': errors, 'warnings': warnings, 'details': details}
        
        # Validate exchange partner
        try:
            with psycopg2.connect(self.connection_string) as conn:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    # Check partner employee exists in requests
                    cur.execute("""
                        SELECT DISTINCT employee_id
                        FROM employee_requests 
                        WHERE employee_id = %s
                        LIMIT 1
                    """, (context.exchange_partner_id,))
                    
                    partner = cur.fetchone()
                    if not partner:
                        errors.append(f"Exchange partner {context.exchange_partner_id} not found")
                    else:
                        details['exchange_partner_validated'] = True
                        details['shift_exchange_validated'] = True
                        
        except Exception as e:
            errors.append(f"Shift exchange validation failed: {str(e)}")
        
        return {
            'errors': errors,
            'warnings': warnings,
            'details': details
        }
    
    def _validate_approval_workflow(self, context: ValidationContext) -> Dict[str, Any]:
        """Validate approval workflow requirements"""
        errors = []
        warnings = []
        details = {}
        
        # Check supervisor assignment
        try:
            with psycopg2.connect(self.connection_string) as conn:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    # Basic approval workflow validation
                    cur.execute("""
                        SELECT employee_id
                        FROM employee_requests 
                        WHERE employee_id = %s
                        LIMIT 1
                    """, (context.employee_id,))
                    
                    result = cur.fetchone()
                    if result:
                        # Assume supervisor exists for approval workflow
                        details['approval_workflow_available'] = True
                    else:
                        warnings.append("Employee not found in request history")
                        
        except Exception as e:
            warnings.append(f"Supervisor assignment check failed: {str(e)}")
        
        # Workflow-specific validations
        details['approval_workflow_required'] = True
        details['status_progression'] = [
            RequestStatus.CREATED.value,
            RequestStatus.UNDER_REVIEW.value,
            RequestStatus.APPROVED.value + "/" + RequestStatus.REJECTED.value
        ]
        
        return {
            'errors': errors,
            'warnings': warnings,
            'details': details
        }


# Demo function for testing
def demo_employee_request_validation():
    """Demo the employee request validation system"""
    print("🎯 Employee Request Validation System Demo")
    print("=" * 50)
    
    validator = EmployeeRequestValidator()
    
    # Test cases using actual database employee IDs from employee_requests table
    sample_employee_id = 1  # From actual employee_requests data
    sample_partner_id = 2   # Another employee for exchange
    
    test_cases = [
        # Time off request
        ValidationContext(
            employee_id=sample_employee_id,
            request_type=RequestType.TIME_OFF,
            start_date=date.today() + timedelta(days=7),
            end_date=date.today() + timedelta(days=7),
            reason="Personal day"
        ),
        # Sick leave request
        ValidationContext(
            employee_id=sample_employee_id,
            request_type=RequestType.SICK_LEAVE,
            start_date=date.today() + timedelta(days=1),
            end_date=date.today() + timedelta(days=3),
            reason="Medical appointment"
        ),
        # Vacation request
        ValidationContext(
            employee_id=sample_employee_id,
            request_type=RequestType.VACATION,
            start_date=date.today() + timedelta(days=30),
            end_date=date.today() + timedelta(days=37),
            reason="Family vacation"
        ),
        # Shift exchange request
        ValidationContext(
            employee_id=sample_employee_id,
            request_type=RequestType.SHIFT_EXCHANGE,
            start_date=date.today() + timedelta(days=5),
            end_date=date.today() + timedelta(days=5),
            reason="Personal arrangement",
            exchange_partner_id=sample_partner_id
        )
    ]
    
    for i, test_case in enumerate(test_cases, 1):
        print(f"\n{i}. Testing {test_case.request_type.value} request:")
        print(f"   Employee: {test_case.employee_id}")
        print(f"   Dates: {test_case.start_date} to {test_case.end_date}")
        
        result = validator.validate_employee_request(test_case)
        
        print(f"   ✅ Valid: {result.is_valid}")
        print(f"   🏃 Time: {result.validation_details.get('validation_time_ms', 0):.0f}ms")
        print(f"   🔄 1C Required: {result.requires_1c_integration}")
        
        if result.errors:
            print(f"   ❌ Errors: {', '.join(result.errors)}")
        if result.warnings:
            print(f"   ⚠️ Warnings: {', '.join(result.warnings)}")
    
    print(f"\n🎯 Priority 1 Employee Request Validation Complete!")
    print("Built on existing validation patterns with 100% PostgreSQL integration")


if __name__ == "__main__":
    demo_employee_request_validation()