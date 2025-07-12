"""
Time Tracking BDD Implementation
Implements 20 scenarios for comprehensive time tracking and attendance management
"""

from fastapi import APIRouter, HTTPException, Depends, Query, Body
from datetime import datetime, date, time, timedelta
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field, validator
from enum import Enum
import asyncpg
from ....core.database import get_db_connection
from ....auth.dependencies import get_current_user
from ....models.user import User

router = APIRouter(prefix="/time-tracking", tags=["time-tracking"])

# Enums
class ClockEventType(str, Enum):
    CLOCK_IN = "clock_in"
    CLOCK_OUT = "clock_out"
    BREAK_START = "break_start"
    BREAK_END = "break_end"
    LUNCH_START = "lunch_start"
    LUNCH_END = "lunch_end"

class AttendanceStatus(str, Enum):
    PRESENT = "present"
    ABSENT = "absent"
    LATE = "late"
    EARLY_DEPARTURE = "early_departure"
    ON_BREAK = "on_break"
    ON_LUNCH = "on_lunch"

class TimeRequestType(str, Enum):
    CORRECTION = "correction"
    MISSING_PUNCH = "missing_punch"
    OVERTIME_APPROVAL = "overtime_approval"
    BREAK_EXTENSION = "break_extension"

class ApprovalStatus(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"

# Models
class ClockEvent(BaseModel):
    employee_id: int
    event_type: ClockEventType
    timestamp: datetime
    location_id: Optional[int] = None
    ip_address: Optional[str] = None
    device_id: Optional[str] = None
    notes: Optional[str] = None

class ClockEventResponse(BaseModel):
    id: int
    employee_id: int
    event_type: ClockEventType
    timestamp: datetime
    location_id: Optional[int]
    status: str
    duration_since_last: Optional[int]  # minutes

class BreakTracking(BaseModel):
    employee_id: int
    break_type: str
    scheduled_duration: int  # minutes
    actual_duration: Optional[int]
    start_time: datetime
    end_time: Optional[datetime]
    is_paid: bool = False

class OvertimeRequest(BaseModel):
    employee_id: int
    date: date
    regular_hours: float
    overtime_hours: float
    overtime_reason: str
    requires_approval: bool = True
    approver_id: Optional[int]

class TimeCorrection(BaseModel):
    employee_id: int
    original_timestamp: datetime
    corrected_timestamp: datetime
    event_type: ClockEventType
    reason: str
    supporting_documents: Optional[List[str]]

class AttendanceReport(BaseModel):
    employee_id: int
    date: date
    scheduled_start: time
    scheduled_end: time
    actual_start: Optional[datetime]
    actual_end: Optional[datetime]
    total_hours: float
    regular_hours: float
    overtime_hours: float
    break_minutes: int
    status: AttendanceStatus
    exceptions: List[str] = []

class BulkClockIn(BaseModel):
    employee_ids: List[int]
    timestamp: datetime
    location_id: int
    supervisor_id: int
    reason: str

# Scenario 1: Basic Clock In
@router.post("/clock-in", response_model=ClockEventResponse)
async def clock_in(
    event: ClockEvent = Body(...),
    current_user: User = Depends(get_current_user),
    conn: asyncpg.Connection = Depends(get_db_connection)
):
    """
    BDD Scenario 1: Employee clocks in at start of shift
    Given an employee arrives at work
    When they clock in using their credentials
    Then the system records the clock-in time and validates against schedule
    """
    # Check if already clocked in
    existing = await conn.fetchval("""
        SELECT id FROM time_tracking_events
        WHERE employee_id = $1 
        AND event_type = 'clock_in'
        AND date(timestamp) = date($2)
        AND NOT EXISTS (
            SELECT 1 FROM time_tracking_events
            WHERE employee_id = $1
            AND event_type = 'clock_out'
            AND date(timestamp) = date($2)
            AND timestamp > time_tracking_events.timestamp
        )
    """, event.employee_id, event.timestamp)
    
    if existing:
        raise HTTPException(400, "Employee already clocked in")
    
    # Insert clock-in event
    result = await conn.fetchrow("""
        INSERT INTO time_tracking_events 
        (employee_id, event_type, timestamp, location_id, ip_address, device_id, notes)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING id, employee_id, event_type, timestamp, location_id
    """, event.employee_id, event.event_type, event.timestamp, 
        event.location_id, event.ip_address, event.device_id, event.notes)
    
    return ClockEventResponse(
        id=result['id'],
        employee_id=result['employee_id'],
        event_type=result['event_type'],
        timestamp=result['timestamp'],
        location_id=result['location_id'],
        status="clocked_in",
        duration_since_last=None
    )

# Scenario 2: Basic Clock Out
@router.post("/clock-out", response_model=ClockEventResponse)
async def clock_out(
    event: ClockEvent = Body(...),
    current_user: User = Depends(get_current_user),
    conn: asyncpg.Connection = Depends(get_db_connection)
):
    """
    BDD Scenario 2: Employee clocks out at end of shift
    Given an employee has completed their shift
    When they clock out
    Then the system calculates total hours worked and checks for overtime
    """
    # Get last clock-in
    last_clock_in = await conn.fetchrow("""
        SELECT id, timestamp FROM time_tracking_events
        WHERE employee_id = $1 
        AND event_type = 'clock_in'
        AND date(timestamp) = date($2)
        ORDER BY timestamp DESC
        LIMIT 1
    """, event.employee_id, event.timestamp)
    
    if not last_clock_in:
        raise HTTPException(400, "No clock-in found for today")
    
    # Calculate duration
    duration = int((event.timestamp - last_clock_in['timestamp']).total_seconds() / 60)
    
    # Insert clock-out event
    result = await conn.fetchrow("""
        INSERT INTO time_tracking_events 
        (employee_id, event_type, timestamp, location_id, ip_address, device_id, notes)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING id, employee_id, event_type, timestamp, location_id
    """, event.employee_id, event.event_type, event.timestamp,
        event.location_id, event.ip_address, event.device_id, event.notes)
    
    return ClockEventResponse(
        id=result['id'],
        employee_id=result['employee_id'],
        event_type=result['event_type'],
        timestamp=result['timestamp'],
        location_id=result['location_id'],
        status="clocked_out",
        duration_since_last=duration
    )

# Scenario 3: Break Time Tracking
@router.post("/break/start", response_model=Dict[str, Any])
async def start_break(
    break_data: BreakTracking = Body(...),
    current_user: User = Depends(get_current_user),
    conn: asyncpg.Connection = Depends(get_db_connection)
):
    """
    BDD Scenario 3: Employee takes a scheduled break
    Given an employee needs to take a break
    When they start their break
    Then the system tracks break duration against allowed limits
    """
    # Check if clocked in
    is_clocked_in = await conn.fetchval("""
        SELECT EXISTS(
            SELECT 1 FROM time_tracking_events
            WHERE employee_id = $1
            AND event_type = 'clock_in'
            AND date(timestamp) = current_date
            AND NOT EXISTS (
                SELECT 1 FROM time_tracking_events t2
                WHERE t2.employee_id = $1
                AND t2.event_type = 'clock_out'
                AND date(t2.timestamp) = current_date
                AND t2.timestamp > time_tracking_events.timestamp
            )
        )
    """, break_data.employee_id)
    
    if not is_clocked_in:
        raise HTTPException(400, "Employee must be clocked in to start break")
    
    # Record break start
    await conn.execute("""
        INSERT INTO time_tracking_events
        (employee_id, event_type, timestamp)
        VALUES ($1, $2, $3)
    """, break_data.employee_id, ClockEventType.BREAK_START, break_data.start_time)
    
    return {
        "status": "break_started",
        "employee_id": break_data.employee_id,
        "start_time": break_data.start_time,
        "scheduled_duration": break_data.scheduled_duration
    }

# Scenario 4: Break End Tracking
@router.post("/break/end", response_model=Dict[str, Any])
async def end_break(
    employee_id: int = Body(...),
    end_time: datetime = Body(...),
    current_user: User = Depends(get_current_user),
    conn: asyncpg.Connection = Depends(get_db_connection)
):
    """
    BDD Scenario 4: Employee returns from break
    Given an employee is on break
    When they return from break
    Then the system validates break duration and flags violations
    """
    # Get break start time
    break_start = await conn.fetchrow("""
        SELECT timestamp FROM time_tracking_events
        WHERE employee_id = $1
        AND event_type = 'break_start'
        AND date(timestamp) = date($2)
        ORDER BY timestamp DESC
        LIMIT 1
    """, employee_id, end_time)
    
    if not break_start:
        raise HTTPException(400, "No active break found")
    
    # Calculate break duration
    duration = int((end_time - break_start['timestamp']).total_seconds() / 60)
    
    # Record break end
    await conn.execute("""
        INSERT INTO time_tracking_events
        (employee_id, event_type, timestamp)
        VALUES ($1, $2, $3)
    """, employee_id, ClockEventType.BREAK_END, end_time)
    
    # Check if break exceeded limits (assuming 15 min standard)
    violation = duration > 15
    
    return {
        "status": "break_ended",
        "employee_id": employee_id,
        "duration_minutes": duration,
        "violation": violation,
        "excess_minutes": max(0, duration - 15) if violation else 0
    }

# Scenario 5: Overtime Calculation
@router.get("/overtime/{employee_id}", response_model=Dict[str, Any])
async def calculate_overtime(
    employee_id: int,
    date: date = Query(...),
    current_user: User = Depends(get_current_user),
    conn: asyncpg.Connection = Depends(get_db_connection)
):
    """
    BDD Scenario 5: System calculates overtime hours
    Given an employee has worked beyond regular hours
    When daily hours are calculated
    Then the system identifies overtime requiring approval
    """
    # Get all clock events for the day
    events = await conn.fetch("""
        SELECT event_type, timestamp
        FROM time_tracking_events
        WHERE employee_id = $1
        AND date(timestamp) = $2
        ORDER BY timestamp
    """, employee_id, date)
    
    total_minutes = 0
    clock_in_time = None
    
    for event in events:
        if event['event_type'] == 'clock_in':
            clock_in_time = event['timestamp']
        elif event['event_type'] == 'clock_out' and clock_in_time:
            total_minutes += (event['timestamp'] - clock_in_time).total_seconds() / 60
            clock_in_time = None
    
    total_hours = total_minutes / 60
    regular_hours = min(8, total_hours)
    overtime_hours = max(0, total_hours - 8)
    
    return {
        "employee_id": employee_id,
        "date": date,
        "total_hours": round(total_hours, 2),
        "regular_hours": round(regular_hours, 2),
        "overtime_hours": round(overtime_hours, 2),
        "requires_approval": overtime_hours > 0
    }

# Scenario 6: Attendance Report Generation
@router.get("/attendance/report", response_model=List[AttendanceReport])
async def generate_attendance_report(
    start_date: date = Query(...),
    end_date: date = Query(...),
    employee_id: Optional[int] = Query(None),
    current_user: User = Depends(get_current_user),
    conn: asyncpg.Connection = Depends(get_db_connection)
):
    """
    BDD Scenario 6: Generate attendance reports
    Given a date range and optional employee filter
    When attendance report is requested
    Then the system compiles comprehensive attendance data
    """
    query = """
        WITH daily_attendance AS (
            SELECT 
                e.employee_id,
                d.date,
                s.start_time as scheduled_start,
                s.end_time as scheduled_end,
                MIN(CASE WHEN te.event_type = 'clock_in' THEN te.timestamp END) as actual_start,
                MAX(CASE WHEN te.event_type = 'clock_out' THEN te.timestamp END) as actual_end,
                COUNT(CASE WHEN te.event_type IN ('break_start', 'lunch_start') THEN 1 END) as break_count
            FROM employees e
            CROSS JOIN generate_series($1::date, $2::date, '1 day'::interval) d(date)
            LEFT JOIN schedules s ON s.employee_id = e.employee_id AND s.date = d.date
            LEFT JOIN time_tracking_events te ON te.employee_id = e.employee_id AND date(te.timestamp) = d.date
            WHERE ($3::int IS NULL OR e.employee_id = $3)
            GROUP BY e.employee_id, d.date, s.start_time, s.end_time
        )
        SELECT * FROM daily_attendance
        ORDER BY employee_id, date
    """
    
    records = await conn.fetch(query, start_date, end_date, employee_id)
    
    reports = []
    for record in records:
        # Calculate hours and status
        if record['actual_start'] and record['actual_end']:
            total_hours = (record['actual_end'] - record['actual_start']).total_seconds() / 3600
            status = AttendanceStatus.PRESENT
            
            # Check for late arrival
            if record['scheduled_start'] and record['actual_start'].time() > record['scheduled_start']:
                status = AttendanceStatus.LATE
        else:
            total_hours = 0
            status = AttendanceStatus.ABSENT
        
        regular_hours = min(8, total_hours)
        overtime_hours = max(0, total_hours - 8)
        
        reports.append(AttendanceReport(
            employee_id=record['employee_id'],
            date=record['date'],
            scheduled_start=record['scheduled_start'] or time(9, 0),
            scheduled_end=record['scheduled_end'] or time(17, 0),
            actual_start=record['actual_start'],
            actual_end=record['actual_end'],
            total_hours=round(total_hours, 2),
            regular_hours=round(regular_hours, 2),
            overtime_hours=round(overtime_hours, 2),
            break_minutes=record['break_count'] * 15,  # Assuming 15 min breaks
            status=status,
            exceptions=[]
        ))
    
    return reports

# Scenario 7: Time Correction Request
@router.post("/correction/request", response_model=Dict[str, Any])
async def request_time_correction(
    correction: TimeCorrection = Body(...),
    current_user: User = Depends(get_current_user),
    conn: asyncpg.Connection = Depends(get_db_connection)
):
    """
    BDD Scenario 7: Employee requests time correction
    Given an employee forgot to clock in/out
    When they submit a correction request
    Then the system creates an approval workflow
    """
    # Create correction request
    request_id = await conn.fetchval("""
        INSERT INTO time_correction_requests
        (employee_id, original_timestamp, corrected_timestamp, event_type, 
         reason, status, requested_at, requested_by)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING id
    """, correction.employee_id, correction.original_timestamp, 
        correction.corrected_timestamp, correction.event_type,
        correction.reason, ApprovalStatus.PENDING, datetime.now(), current_user.id)
    
    # Notify supervisor
    await conn.execute("""
        INSERT INTO notifications
        (user_id, type, title, message, created_at)
        SELECT supervisor_id, 'time_correction', 'Time Correction Request',
               $2, $3
        FROM employee_supervisors
        WHERE employee_id = $1
    """, correction.employee_id, 
        f"Time correction requested for employee {correction.employee_id}",
        datetime.now())
    
    return {
        "request_id": request_id,
        "status": "pending_approval",
        "employee_id": correction.employee_id,
        "correction_type": correction.event_type
    }

# Scenario 8: Approve/Reject Time Corrections
@router.post("/correction/{request_id}/approve", response_model=Dict[str, Any])
async def approve_time_correction(
    request_id: int,
    approved: bool = Body(...),
    comments: Optional[str] = Body(None),
    current_user: User = Depends(get_current_user),
    conn: asyncpg.Connection = Depends(get_db_connection)
):
    """
    BDD Scenario 8: Supervisor approves time corrections
    Given a pending time correction request
    When supervisor reviews and approves
    Then the system updates time records accordingly
    """
    # Get correction request
    request = await conn.fetchrow("""
        SELECT * FROM time_correction_requests
        WHERE id = $1 AND status = 'pending'
    """, request_id)
    
    if not request:
        raise HTTPException(404, "Request not found or already processed")
    
    # Update request status
    new_status = ApprovalStatus.APPROVED if approved else ApprovalStatus.REJECTED
    await conn.execute("""
        UPDATE time_correction_requests
        SET status = $1, approved_by = $2, approved_at = $3, comments = $4
        WHERE id = $5
    """, new_status, current_user.id, datetime.now(), comments, request_id)
    
    # If approved, apply the correction
    if approved:
        if request['original_timestamp']:
            # Update existing event
            await conn.execute("""
                UPDATE time_tracking_events
                SET timestamp = $1, corrected = true
                WHERE employee_id = $2 
                AND event_type = $3
                AND timestamp = $4
            """, request['corrected_timestamp'], request['employee_id'],
                request['event_type'], request['original_timestamp'])
        else:
            # Insert missing event
            await conn.execute("""
                INSERT INTO time_tracking_events
                (employee_id, event_type, timestamp, corrected)
                VALUES ($1, $2, $3, true)
            """, request['employee_id'], request['event_type'],
                request['corrected_timestamp'])
    
    return {
        "request_id": request_id,
        "status": new_status,
        "applied": approved,
        "approved_by": current_user.id
    }

# Scenario 9: Bulk Clock In (Group Clock In)
@router.post("/bulk/clock-in", response_model=Dict[str, Any])
async def bulk_clock_in(
    bulk_data: BulkClockIn = Body(...),
    current_user: User = Depends(get_current_user),
    conn: asyncpg.Connection = Depends(get_db_connection)
):
    """
    BDD Scenario 9: Supervisor clocks in multiple employees
    Given a team arrives together (e.g., field workers)
    When supervisor performs bulk clock-in
    Then all employees are clocked in simultaneously
    """
    success_count = 0
    failed_employees = []
    
    for employee_id in bulk_data.employee_ids:
        try:
            # Check if already clocked in
            existing = await conn.fetchval("""
                SELECT EXISTS(
                    SELECT 1 FROM time_tracking_events
                    WHERE employee_id = $1
                    AND event_type = 'clock_in'
                    AND date(timestamp) = date($2)
                    AND NOT EXISTS (
                        SELECT 1 FROM time_tracking_events t2
                        WHERE t2.employee_id = $1
                        AND t2.event_type = 'clock_out'
                        AND date(t2.timestamp) = date($2)
                        AND t2.timestamp > time_tracking_events.timestamp
                    )
                )
            """, employee_id, bulk_data.timestamp)
            
            if not existing:
                await conn.execute("""
                    INSERT INTO time_tracking_events
                    (employee_id, event_type, timestamp, location_id, 
                     notes, bulk_entry, entered_by)
                    VALUES ($1, 'clock_in', $2, $3, $4, true, $5)
                """, employee_id, bulk_data.timestamp, bulk_data.location_id,
                    f"Bulk entry: {bulk_data.reason}", bulk_data.supervisor_id)
                success_count += 1
            else:
                failed_employees.append(employee_id)
        except Exception:
            failed_employees.append(employee_id)
    
    return {
        "total_employees": len(bulk_data.employee_ids),
        "success_count": success_count,
        "failed_count": len(failed_employees),
        "failed_employees": failed_employees,
        "timestamp": bulk_data.timestamp
    }

# Scenario 10: Real-time Attendance Dashboard
@router.get("/attendance/realtime", response_model=Dict[str, Any])
async def realtime_attendance_status(
    location_id: Optional[int] = Query(None),
    department_id: Optional[int] = Query(None),
    current_user: User = Depends(get_current_user),
    conn: asyncpg.Connection = Depends(get_db_connection)
):
    """
    BDD Scenario 10: Real-time attendance monitoring
    Given managers need current attendance status
    When they access the dashboard
    Then system shows who's present, absent, on break
    """
    # Get current attendance status
    query = """
        WITH latest_events AS (
            SELECT DISTINCT ON (employee_id)
                employee_id,
                event_type,
                timestamp,
                location_id
            FROM time_tracking_events
            WHERE date(timestamp) = current_date
            ORDER BY employee_id, timestamp DESC
        ),
        employee_status AS (
            SELECT 
                e.employee_id,
                e.name,
                e.department_id,
                le.event_type,
                le.timestamp,
                le.location_id,
                CASE 
                    WHEN le.event_type = 'clock_in' THEN 'present'
                    WHEN le.event_type = 'clock_out' THEN 'left'
                    WHEN le.event_type IN ('break_start', 'lunch_start') THEN 'on_break'
                    WHEN le.event_type IN ('break_end', 'lunch_end') THEN 'present'
                    ELSE 'absent'
                END as status
            FROM employees e
            LEFT JOIN latest_events le ON e.employee_id = le.employee_id
            WHERE ($1::int IS NULL OR e.location_id = $1)
            AND ($2::int IS NULL OR e.department_id = $2)
        )
        SELECT 
            COUNT(*) FILTER (WHERE status = 'present') as present_count,
            COUNT(*) FILTER (WHERE status = 'absent') as absent_count,
            COUNT(*) FILTER (WHERE status = 'on_break') as on_break_count,
            COUNT(*) FILTER (WHERE status = 'left') as left_count,
            json_agg(
                json_build_object(
                    'employee_id', employee_id,
                    'name', name,
                    'status', status,
                    'last_event', event_type,
                    'last_event_time', timestamp
                )
            ) as employee_details
        FROM employee_status
    """
    
    result = await conn.fetchrow(query, location_id, department_id)
    
    return {
        "timestamp": datetime.now(),
        "summary": {
            "present": result['present_count'] or 0,
            "absent": result['absent_count'] or 0,
            "on_break": result['on_break_count'] or 0,
            "left": result['left_count'] or 0,
            "total": sum([
                result['present_count'] or 0,
                result['absent_count'] or 0,
                result['on_break_count'] or 0,
                result['left_count'] or 0
            ])
        },
        "employees": result['employee_details'] or []
    }

# Scenario 11: Overtime Approval Workflow
@router.post("/overtime/request", response_model=Dict[str, Any])
async def request_overtime_approval(
    overtime: OvertimeRequest = Body(...),
    current_user: User = Depends(get_current_user),
    conn: asyncpg.Connection = Depends(get_db_connection)
):
    """
    BDD Scenario 11: Employee requests overtime approval
    Given an employee worked extra hours
    When they submit overtime for approval
    Then system creates approval workflow with notifications
    """
    # Create overtime request
    request_id = await conn.fetchval("""
        INSERT INTO overtime_requests
        (employee_id, date, regular_hours, overtime_hours, reason, 
         status, requested_at, requested_by)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING id
    """, overtime.employee_id, overtime.date, overtime.regular_hours,
        overtime.overtime_hours, overtime.overtime_reason,
        ApprovalStatus.PENDING, datetime.now(), current_user.id)
    
    # Calculate overtime cost
    hourly_rate = await conn.fetchval("""
        SELECT hourly_rate FROM employees WHERE employee_id = $1
    """, overtime.employee_id)
    
    overtime_cost = overtime.overtime_hours * hourly_rate * 1.5  # 1.5x for overtime
    
    # Notify approver
    if overtime.approver_id:
        await conn.execute("""
            INSERT INTO notifications
            (user_id, type, title, message, metadata, created_at)
            VALUES ($1, 'overtime_approval', 'Overtime Approval Request',
                    $2, $3, $4)
        """, overtime.approver_id,
            f"Overtime request for {overtime.overtime_hours} hours",
            {"request_id": request_id, "cost": overtime_cost},
            datetime.now())
    
    return {
        "request_id": request_id,
        "status": "pending_approval",
        "overtime_hours": overtime.overtime_hours,
        "estimated_cost": round(overtime_cost, 2),
        "requires_approval": overtime.requires_approval
    }

# Scenario 12: Late Arrival Tracking
@router.get("/attendance/late-arrivals", response_model=List[Dict[str, Any]])
async def track_late_arrivals(
    date: date = Query(...),
    threshold_minutes: int = Query(15, description="Minutes late to be considered tardy"),
    current_user: User = Depends(get_current_user),
    conn: asyncpg.Connection = Depends(get_db_connection)
):
    """
    BDD Scenario 12: Track and report late arrivals
    Given employees have scheduled start times
    When they clock in after scheduled time
    Then system tracks tardiness for HR reporting
    """
    late_arrivals = await conn.fetch("""
        SELECT 
            e.employee_id,
            e.name,
            s.start_time as scheduled_start,
            te.timestamp as actual_start,
            EXTRACT(EPOCH FROM (te.timestamp::time - s.start_time)) / 60 as minutes_late,
            e.department_id,
            COUNT(*) OVER (PARTITION BY e.employee_id 
                          ORDER BY date(te.timestamp) 
                          RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW) as late_count_30days
        FROM employees e
        JOIN schedules s ON s.employee_id = e.employee_id AND s.date = $1
        JOIN time_tracking_events te ON te.employee_id = e.employee_id 
            AND te.event_type = 'clock_in'
            AND date(te.timestamp) = $1
        WHERE te.timestamp::time > s.start_time + INTERVAL '%s minutes'
        ORDER BY minutes_late DESC
    """ % threshold_minutes, date)
    
    return [
        {
            "employee_id": record['employee_id'],
            "employee_name": record['name'],
            "scheduled_start": record['scheduled_start'],
            "actual_start": record['actual_start'],
            "minutes_late": round(record['minutes_late']),
            "department_id": record['department_id'],
            "late_instances_30days": record['late_count_30days'],
            "requires_action": record['late_count_30days'] > 3
        }
        for record in late_arrivals
    ]

# Scenario 13: Break Time Compliance
@router.get("/compliance/breaks", response_model=Dict[str, Any])
async def check_break_compliance(
    date: date = Query(...),
    current_user: User = Depends(get_current_user),
    conn: asyncpg.Connection = Depends(get_db_connection)
):
    """
    BDD Scenario 13: Monitor break time compliance
    Given labor laws require specific break periods
    When analyzing daily time records
    Then system identifies compliance violations
    """
    violations = await conn.fetch("""
        WITH work_periods AS (
            SELECT 
                employee_id,
                MIN(CASE WHEN event_type = 'clock_in' THEN timestamp END) as start_time,
                MAX(CASE WHEN event_type = 'clock_out' THEN timestamp END) as end_time,
                EXTRACT(EPOCH FROM (
                    MAX(CASE WHEN event_type = 'clock_out' THEN timestamp END) -
                    MIN(CASE WHEN event_type = 'clock_in' THEN timestamp END)
                )) / 3600 as total_hours
            FROM time_tracking_events
            WHERE date(timestamp) = $1
            GROUP BY employee_id
        ),
        break_times AS (
            SELECT 
                employee_id,
                COUNT(*) as break_count,
                SUM(
                    EXTRACT(EPOCH FROM (
                        lead(timestamp) OVER (PARTITION BY employee_id ORDER BY timestamp) - timestamp
                    )) / 60
                ) FILTER (WHERE event_type IN ('break_start', 'lunch_start')) as total_break_minutes
            FROM time_tracking_events
            WHERE date(timestamp) = $1
            AND event_type IN ('break_start', 'break_end', 'lunch_start', 'lunch_end')
            GROUP BY employee_id
        )
        SELECT 
            wp.employee_id,
            e.name,
            wp.total_hours,
            COALESCE(bt.break_count, 0) as break_count,
            COALESCE(bt.total_break_minutes, 0) as total_break_minutes,
            CASE 
                WHEN wp.total_hours > 6 AND COALESCE(bt.total_break_minutes, 0) < 30 THEN 'insufficient_break'
                WHEN wp.total_hours > 4 AND wp.total_hours <= 6 AND COALESCE(bt.break_count, 0) = 0 THEN 'missing_break'
                ELSE 'compliant'
            END as compliance_status
        FROM work_periods wp
        JOIN employees e ON e.employee_id = wp.employee_id
        LEFT JOIN break_times bt ON bt.employee_id = wp.employee_id
        WHERE wp.total_hours > 4  -- Only check employees who worked more than 4 hours
    """, date)
    
    violation_count = sum(1 for v in violations if v['compliance_status'] != 'compliant')
    
    return {
        "date": date,
        "total_employees_checked": len(violations),
        "violations_found": violation_count,
        "compliance_rate": round((len(violations) - violation_count) / len(violations) * 100, 2) if violations else 100,
        "violations": [
            {
                "employee_id": v['employee_id'],
                "employee_name": v['name'],
                "hours_worked": round(v['total_hours'], 2),
                "break_minutes": v['total_break_minutes'],
                "violation_type": v['compliance_status']
            }
            for v in violations if v['compliance_status'] != 'compliant'
        ]
    }

# Scenario 14: Shift Differential Tracking
@router.get("/shift-differential/{employee_id}", response_model=Dict[str, Any])
async def calculate_shift_differential(
    employee_id: int,
    start_date: date = Query(...),
    end_date: date = Query(...),
    current_user: User = Depends(get_current_user),
    conn: asyncpg.Connection = Depends(get_db_connection)
):
    """
    BDD Scenario 14: Calculate shift differential pay
    Given employees work different shifts (day/evening/night)
    When calculating payroll
    Then system applies appropriate shift differentials
    """
    # Define shift differential rates
    shift_rates = {
        "day": 1.0,      # 6 AM - 2 PM
        "evening": 1.1,  # 2 PM - 10 PM (10% extra)
        "night": 1.15    # 10 PM - 6 AM (15% extra)
    }
    
    time_records = await conn.fetch("""
        SELECT 
            date(ci.timestamp) as work_date,
            ci.timestamp as clock_in,
            co.timestamp as clock_out,
            EXTRACT(EPOCH FROM (co.timestamp - ci.timestamp)) / 3600 as hours_worked
        FROM time_tracking_events ci
        JOIN time_tracking_events co ON co.employee_id = ci.employee_id
            AND co.event_type = 'clock_out'
            AND date(co.timestamp) = date(ci.timestamp)
            AND co.timestamp > ci.timestamp
        WHERE ci.employee_id = $1
        AND ci.event_type = 'clock_in'
        AND date(ci.timestamp) BETWEEN $2 AND $3
        ORDER BY ci.timestamp
    """, employee_id, start_date, end_date)
    
    differential_hours = {"day": 0, "evening": 0, "night": 0}
    
    for record in time_records:
        # Calculate hours in each shift period
        clock_in = record['clock_in']
        clock_out = record['clock_out']
        
        # Simple calculation - in production would be more sophisticated
        hour = clock_in.hour
        if 6 <= hour < 14:
            differential_hours["day"] += record['hours_worked']
        elif 14 <= hour < 22:
            differential_hours["evening"] += record['hours_worked']
        else:
            differential_hours["night"] += record['hours_worked']
    
    base_rate = await conn.fetchval("""
        SELECT hourly_rate FROM employees WHERE employee_id = $1
    """, employee_id)
    
    total_pay = sum(hours * shift_rates[shift] * base_rate 
                   for shift, hours in differential_hours.items())
    
    return {
        "employee_id": employee_id,
        "period": f"{start_date} to {end_date}",
        "hours_by_shift": differential_hours,
        "base_hourly_rate": base_rate,
        "shift_differentials": shift_rates,
        "total_earnings": round(total_pay, 2),
        "differential_bonus": round(total_pay - sum(differential_hours.values()) * base_rate, 2)
    }

# Scenario 15: Geofencing Clock In/Out
@router.post("/clock-in/geofenced", response_model=Dict[str, Any])
async def geofenced_clock_in(
    employee_id: int = Body(...),
    latitude: float = Body(...),
    longitude: float = Body(...),
    accuracy: float = Body(...),
    current_user: User = Depends(get_current_user),
    conn: asyncpg.Connection = Depends(get_db_connection)
):
    """
    BDD Scenario 15: Geofencing-based clock in
    Given employees must be at work location to clock in
    When they attempt to clock in with location data
    Then system validates they are within authorized zone
    """
    # Get authorized locations for employee
    locations = await conn.fetch("""
        SELECT 
            l.location_id,
            l.name,
            l.latitude,
            l.longitude,
            l.radius_meters
        FROM locations l
        JOIN employee_locations el ON el.location_id = l.location_id
        WHERE el.employee_id = $1
        AND el.is_active = true
    """, employee_id)
    
    # Check if employee is within any authorized location
    authorized = False
    location_id = None
    location_name = None
    
    for loc in locations:
        # Calculate distance (simplified - in production use proper geospatial functions)
        distance = ((latitude - loc['latitude'])**2 + 
                   (longitude - loc['longitude'])**2)**0.5 * 111000  # rough meters
        
        if distance <= loc['radius_meters']:
            authorized = True
            location_id = loc['location_id']
            location_name = loc['name']
            break
    
    if not authorized:
        return {
            "success": False,
            "error": "not_in_authorized_location",
            "message": "You must be at an authorized work location to clock in",
            "nearest_location": locations[0]['name'] if locations else None
        }
    
    # Proceed with clock in
    await conn.execute("""
        INSERT INTO time_tracking_events
        (employee_id, event_type, timestamp, location_id, latitude, longitude, accuracy)
        VALUES ($1, 'clock_in', $2, $3, $4, $5, $6)
    """, employee_id, datetime.now(), location_id, latitude, longitude, accuracy)
    
    return {
        "success": True,
        "employee_id": employee_id,
        "location": location_name,
        "timestamp": datetime.now(),
        "coordinates": {"lat": latitude, "lng": longitude}
    }

# Scenario 16: Automated Lunch Deduction
@router.post("/attendance/apply-lunch-deduction", response_model=Dict[str, Any])
async def apply_automatic_lunch_deduction(
    date: date = Body(...),
    min_hours_for_deduction: float = Body(6.0),
    deduction_minutes: int = Body(30),
    current_user: User = Depends(get_current_user),
    conn: asyncpg.Connection = Depends(get_db_connection)
):
    """
    BDD Scenario 16: Automatic lunch deduction
    Given company policy auto-deducts lunch for shifts > 6 hours
    When calculating daily hours
    Then system applies lunch deduction if no lunch break recorded
    """
    # Find employees who worked > min_hours without lunch break
    employees_needing_deduction = await conn.fetch("""
        WITH daily_work AS (
            SELECT 
                employee_id,
                MIN(CASE WHEN event_type = 'clock_in' THEN timestamp END) as start_time,
                MAX(CASE WHEN event_type = 'clock_out' THEN timestamp END) as end_time,
                EXTRACT(EPOCH FROM (
                    MAX(CASE WHEN event_type = 'clock_out' THEN timestamp END) -
                    MIN(CASE WHEN event_type = 'clock_in' THEN timestamp END)
                )) / 3600 as total_hours,
                bool_or(event_type IN ('lunch_start', 'lunch_end')) as has_lunch
            FROM time_tracking_events
            WHERE date(timestamp) = $1
            GROUP BY employee_id
        )
        SELECT 
            employee_id,
            total_hours,
            has_lunch
        FROM daily_work
        WHERE total_hours > $2
        AND NOT has_lunch
    """, date, min_hours_for_deduction)
    
    deductions_applied = []
    
    for emp in employees_needing_deduction:
        # Apply automatic lunch deduction
        await conn.execute("""
            INSERT INTO time_deductions
            (employee_id, date, deduction_type, minutes, reason, auto_applied)
            VALUES ($1, $2, 'lunch', $3, 'Automatic lunch deduction', true)
        """, emp['employee_id'], date, deduction_minutes)
        
        deductions_applied.append({
            "employee_id": emp['employee_id'],
            "hours_worked": round(emp['total_hours'], 2),
            "deduction_applied": deduction_minutes
        })
    
    return {
        "date": date,
        "employees_processed": len(employees_needing_deduction),
        "total_deductions_applied": len(deductions_applied),
        "deduction_minutes": deduction_minutes,
        "deductions": deductions_applied
    }

# Scenario 17: Buddy Punch Prevention
@router.post("/clock-in/biometric", response_model=Dict[str, Any])
async def biometric_clock_in(
    employee_id: int = Body(...),
    biometric_hash: str = Body(...),
    device_id: str = Body(...),
    current_user: User = Depends(get_current_user),
    conn: asyncpg.Connection = Depends(get_db_connection)
):
    """
    BDD Scenario 17: Prevent buddy punching with biometrics
    Given system uses biometric authentication
    When employee attempts to clock in
    Then system verifies identity before recording time
    """
    # Verify biometric data
    stored_biometric = await conn.fetchval("""
        SELECT biometric_hash FROM employee_biometrics
        WHERE employee_id = $1 AND is_active = true
    """, employee_id)
    
    if not stored_biometric or stored_biometric != biometric_hash:
        # Log failed attempt
        await conn.execute("""
            INSERT INTO security_events
            (event_type, employee_id, device_id, timestamp, success, details)
            VALUES ('biometric_clock_in', $1, $2, $3, false, 'Invalid biometric')
        """, employee_id, device_id, datetime.now())
        
        return {
            "success": False,
            "error": "biometric_mismatch",
            "message": "Biometric verification failed"
        }
    
    # Check for rapid successive clock-ins (potential fraud)
    recent_clockin = await conn.fetchval("""
        SELECT EXISTS(
            SELECT 1 FROM time_tracking_events
            WHERE employee_id = $1
            AND event_type = 'clock_in'
            AND timestamp > $2 - INTERVAL '5 minutes'
        )
    """, employee_id, datetime.now())
    
    if recent_clockin:
        return {
            "success": False,
            "error": "too_soon",
            "message": "Please wait before clocking in again"
        }
    
    # Record successful clock in
    event_id = await conn.fetchval("""
        INSERT INTO time_tracking_events
        (employee_id, event_type, timestamp, device_id, biometric_verified)
        VALUES ($1, 'clock_in', $2, $3, true)
        RETURNING id
    """, employee_id, datetime.now(), device_id)
    
    return {
        "success": True,
        "event_id": event_id,
        "employee_id": employee_id,
        "timestamp": datetime.now(),
        "biometric_verified": True
    }

# Scenario 18: Time Bank/Comp Time Tracking
@router.get("/time-bank/{employee_id}", response_model=Dict[str, Any])
async def get_time_bank_balance(
    employee_id: int,
    current_user: User = Depends(get_current_user),
    conn: asyncpg.Connection = Depends(get_db_connection)
):
    """
    BDD Scenario 18: Track compensatory time balance
    Given employees can bank overtime as comp time
    When viewing time bank balance
    Then system shows accrued, used, and available comp time
    """
    # Get comp time transactions
    transactions = await conn.fetch("""
        SELECT 
            transaction_type,
            hours,
            date,
            reason,
            approved_by
        FROM comp_time_transactions
        WHERE employee_id = $1
        ORDER BY date DESC
        LIMIT 50
    """, employee_id)
    
    # Calculate balances
    accrued = sum(t['hours'] for t in transactions if t['transaction_type'] == 'accrued')
    used = sum(t['hours'] for t in transactions if t['transaction_type'] == 'used')
    expired = sum(t['hours'] for t in transactions if t['transaction_type'] == 'expired')
    
    balance = accrued - used - expired
    
    # Get policy limits
    policy = await conn.fetchrow("""
        SELECT max_comp_hours, comp_expiry_days
        FROM company_policies
        WHERE is_active = true
        LIMIT 1
    """)
    
    return {
        "employee_id": employee_id,
        "current_balance": round(balance, 2),
        "total_accrued": round(accrued, 2),
        "total_used": round(used, 2),
        "total_expired": round(expired, 2),
        "max_allowed": policy['max_comp_hours'] if policy else 40,
        "can_accrue_more": balance < (policy['max_comp_hours'] if policy else 40),
        "recent_transactions": [
            {
                "type": t['transaction_type'],
                "hours": t['hours'],
                "date": t['date'],
                "reason": t['reason']
            }
            for t in transactions[:10]
        ]
    }

# Scenario 19: Schedule vs Actual Comparison
@router.get("/attendance/schedule-adherence", response_model=Dict[str, Any])
async def analyze_schedule_adherence(
    date: date = Query(...),
    department_id: Optional[int] = Query(None),
    current_user: User = Depends(get_current_user),
    conn: asyncpg.Connection = Depends(get_db_connection)
):
    """
    BDD Scenario 19: Compare scheduled vs actual attendance
    Given employees have published schedules
    When analyzing daily attendance
    Then system calculates adherence metrics and deviations
    """
    adherence_data = await conn.fetch("""
        WITH schedule_actual AS (
            SELECT 
                e.employee_id,
                e.name,
                e.department_id,
                s.start_time as scheduled_start,
                s.end_time as scheduled_end,
                MIN(te.timestamp) FILTER (WHERE te.event_type = 'clock_in') as actual_start,
                MAX(te.timestamp) FILTER (WHERE te.event_type = 'clock_out') as actual_end,
                s.total_hours as scheduled_hours
            FROM employees e
            JOIN schedules s ON s.employee_id = e.employee_id AND s.date = $1
            LEFT JOIN time_tracking_events te ON te.employee_id = e.employee_id 
                AND date(te.timestamp) = $1
            WHERE ($2::int IS NULL OR e.department_id = $2)
            GROUP BY e.employee_id, e.name, e.department_id, s.start_time, s.end_time, s.total_hours
        )
        SELECT 
            *,
            CASE 
                WHEN actual_start IS NULL THEN 'absent'
                WHEN actual_start::time > scheduled_start + INTERVAL '5 minutes' THEN 'late'
                WHEN actual_start::time < scheduled_start - INTERVAL '5 minutes' THEN 'early'
                ELSE 'on_time'
            END as arrival_status,
            CASE
                WHEN actual_end IS NULL THEN NULL
                WHEN actual_end::time < scheduled_end - INTERVAL '5 minutes' THEN 'left_early'
                WHEN actual_end::time > scheduled_end + INTERVAL '30 minutes' THEN 'overtime'
                ELSE 'on_time'
            END as departure_status,
            EXTRACT(EPOCH FROM (actual_end - actual_start)) / 3600 as actual_hours
        FROM schedule_actual
    """, date, department_id)
    
    # Calculate metrics
    total = len(adherence_data)
    on_time = sum(1 for a in adherence_data if a['arrival_status'] == 'on_time')
    late = sum(1 for a in adherence_data if a['arrival_status'] == 'late')
    absent = sum(1 for a in adherence_data if a['arrival_status'] == 'absent')
    
    return {
        "date": date,
        "department_id": department_id,
        "metrics": {
            "total_scheduled": total,
            "on_time_arrivals": on_time,
            "late_arrivals": late,
            "absences": absent,
            "adherence_rate": round(on_time / total * 100, 2) if total > 0 else 0,
            "attendance_rate": round((total - absent) / total * 100, 2) if total > 0 else 0
        },
        "deviations": [
            {
                "employee_id": a['employee_id'],
                "employee_name": a['name'],
                "scheduled": f"{a['scheduled_start']} - {a['scheduled_end']}",
                "actual_start": a['actual_start'],
                "actual_end": a['actual_end'],
                "arrival_status": a['arrival_status'],
                "departure_status": a['departure_status'],
                "scheduled_hours": a['scheduled_hours'],
                "actual_hours": round(a['actual_hours'], 2) if a['actual_hours'] else 0
            }
            for a in adherence_data
            if a['arrival_status'] != 'on_time' or a['departure_status'] not in ['on_time', None]
        ][:20]  # Limit to 20 deviations
    }

# Scenario 20: Integration with Payroll Export
@router.get("/payroll/export", response_model=Dict[str, Any])
async def export_payroll_data(
    pay_period_start: date = Query(...),
    pay_period_end: date = Query(...),
    format: str = Query("json", regex="^(json|csv|xml)$"),
    current_user: User = Depends(get_current_user),
    conn: asyncpg.Connection = Depends(get_db_connection)
):
    """
    BDD Scenario 20: Export time data for payroll processing
    Given payroll needs processed time data
    When requesting payroll export
    Then system provides formatted data with all calculations
    """
    # Gather comprehensive time data
    payroll_data = await conn.fetch("""
        WITH time_summary AS (
            SELECT 
                e.employee_id,
                e.name,
                e.employee_code,
                e.hourly_rate,
                COUNT(DISTINCT date(te.timestamp)) as days_worked,
                SUM(
                    EXTRACT(EPOCH FROM (
                        MAX(te.timestamp) FILTER (WHERE te.event_type = 'clock_out') -
                        MIN(te.timestamp) FILTER (WHERE te.event_type = 'clock_in')
                    )) / 3600
                ) as total_hours,
                SUM(CASE WHEN ot.hours > 0 THEN ot.hours ELSE 0 END) as overtime_hours,
                SUM(COALESCE(td.minutes, 0)) / 60.0 as deduction_hours,
                SUM(COALESCE(sd.differential_hours, 0)) as differential_hours
            FROM employees e
            LEFT JOIN time_tracking_events te ON te.employee_id = e.employee_id
                AND date(te.timestamp) BETWEEN $1 AND $2
            LEFT JOIN overtime_approvals ot ON ot.employee_id = e.employee_id
                AND ot.date BETWEEN $1 AND $2
                AND ot.status = 'approved'
            LEFT JOIN time_deductions td ON td.employee_id = e.employee_id
                AND td.date BETWEEN $1 AND $2
            LEFT JOIN shift_differentials sd ON sd.employee_id = e.employee_id
                AND sd.date BETWEEN $1 AND $2
            GROUP BY e.employee_id, e.name, e.employee_code, e.hourly_rate
        )
        SELECT 
            *,
            (total_hours - overtime_hours - deduction_hours) as regular_hours,
            (total_hours - overtime_hours - deduction_hours) * hourly_rate as regular_pay,
            overtime_hours * hourly_rate * 1.5 as overtime_pay,
            differential_hours * hourly_rate * 0.1 as differential_pay
        FROM time_summary
        WHERE total_hours > 0
        ORDER BY employee_code
    """, pay_period_start, pay_period_end)
    
    # Format data based on requested format
    if format == "json":
        export_data = {
            "pay_period": {
                "start": pay_period_start,
                "end": pay_period_end
            },
            "generated_at": datetime.now(),
            "employee_count": len(payroll_data),
            "employees": [
                {
                    "employee_id": emp['employee_id'],
                    "employee_code": emp['employee_code'],
                    "name": emp['name'],
                    "days_worked": emp['days_worked'],
                    "hours": {
                        "regular": round(emp['regular_hours'] or 0, 2),
                        "overtime": round(emp['overtime_hours'] or 0, 2),
                        "total": round(emp['total_hours'] or 0, 2)
                    },
                    "earnings": {
                        "regular": round(emp['regular_pay'] or 0, 2),
                        "overtime": round(emp['overtime_pay'] or 0, 2),
                        "differential": round(emp['differential_pay'] or 0, 2),
                        "total": round((emp['regular_pay'] or 0) + 
                                     (emp['overtime_pay'] or 0) + 
                                     (emp['differential_pay'] or 0), 2)
                    }
                }
                for emp in payroll_data
            ],
            "totals": {
                "regular_hours": round(sum(emp['regular_hours'] or 0 for emp in payroll_data), 2),
                "overtime_hours": round(sum(emp['overtime_hours'] or 0 for emp in payroll_data), 2),
                "total_earnings": round(sum(
                    (emp['regular_pay'] or 0) + 
                    (emp['overtime_pay'] or 0) + 
                    (emp['differential_pay'] or 0) 
                    for emp in payroll_data
                ), 2)
            }
        }
    else:
        # For CSV/XML formats, just return metadata
        export_data = {
            "format": format,
            "status": "ready_for_download",
            "record_count": len(payroll_data),
            "download_url": f"/api/v1/payroll/download/{pay_period_start}/{pay_period_end}/{format}"
        }
    
    # Log export for audit trail
    await conn.execute("""
        INSERT INTO audit_log
        (user_id, action, entity_type, details, timestamp)
        VALUES ($1, 'payroll_export', 'time_tracking', $2, $3)
    """, current_user.id, 
        {"period": f"{pay_period_start} to {pay_period_end}", "format": format},
        datetime.now())
    
    return export_data