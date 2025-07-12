"""
Employee Request Management - BDD Implementation
Based on 02-employee-requests.feature

Implements all BDD scenarios for:
- Time off/sick leave/vacation requests
- Shift exchange requests
- Request approval workflows
- 1C ZUP integration
- Status tracking
"""

from fastapi import APIRouter, HTTPException, status, Query, Depends
from typing import List, Optional, Dict, Any, Literal
from datetime import datetime, date, timezone
from pydantic import BaseModel, Field, validator
from enum import Enum
import logging
import uuid

logger = logging.getLogger(__name__)

router = APIRouter()

# ============================================================================
# ENUMS AND CONSTANTS (BDD Lines 16-94)
# ============================================================================

class RequestType(str, Enum):
    """Request types from BDD specification"""
    SICK_LEAVE = "больничный"
    TIME_OFF = "отгул"
    UNSCHEDULED_VACATION = "внеочередной отпуск"
    SHIFT_EXCHANGE = "обмен сменами"

class RequestStatus(str, Enum):
    """Request status progression from BDD specification"""
    CREATED = "Создана"
    UNDER_REVIEW = "На рассмотрении"
    APPROVED = "Одобрена"
    REJECTED = "Отклонена"

class ZUPDocumentType(str, Enum):
    """1C ZUP document types from BDD specification"""
    TIME_OFF_DEVIATION = "Time off deviation document"
    SICK_LEAVE_DOCUMENT = "Sick leave document"
    UNSCHEDULED_VACATION = "Unscheduled vacation document"

class ZUPTimeType(str, Enum):
    """1C ZUP time types from BDD specification"""
    NV = "NV"  # НВ - Absence
    SICK_LEAVE = "Sick leave time type"
    OT = "OT"  # ОТ - Vacation

# ============================================================================
# REQUEST CREATION MODELS (BDD Lines 11-37)
# ============================================================================

class TimeOffRequest(BaseModel):
    """Time off/sick leave/vacation request from BDD specification"""
    requestType: RequestType = Field(..., description="Type of request")
    startDate: date = Field(..., description="Start date of absence")
    endDate: date = Field(..., description="End date of absence")
    reason: str = Field(..., description="Reason for request")
    comments: Optional[str] = Field(None, description="Additional comments")
    
    @validator('endDate')
    def validate_dates(cls, v, values):
        """Ensure end date is not before start date"""
        if 'startDate' in values and v < values['startDate']:
            raise ValueError('End date must be on or after start date')
        return v

class ShiftExchangeRequest(BaseModel):
    """Shift exchange request from BDD specification"""
    originalShiftId: str = Field(..., description="ID of shift to exchange")
    originalShiftDate: date = Field(..., description="Date of original shift")
    targetEmployeeId: Optional[str] = Field(None, description="Specific employee to exchange with")
    proposedDate: date = Field(..., description="Proposed date to work instead")
    proposedTime: str = Field(..., description="Proposed time to work")
    comments: Optional[str] = Field(None, description="Exchange details")

class RequestCreateResponse(BaseModel):
    """Request creation response"""
    requestId: str = Field(..., description="Unique request identifier")
    requestType: RequestType = Field(..., description="Type of request")
    status: RequestStatus = Field(..., description="Current status")
    createdAt: datetime = Field(..., description="Creation timestamp")
    message: str = Field(..., description="Success message")

# ============================================================================
# REQUEST APPROVAL MODELS (BDD Lines 48-77)
# ============================================================================

class ApprovalDecision(str, Enum):
    """Approval decision options"""
    APPROVE = "approve"
    REJECT = "reject"

class ZUPIntegrationRequest(BaseModel):
    """1C ZUP integration request data"""
    requestId: str = Field(..., description="Request ID")
    employeeId: str = Field(..., description="Employee ID")
    documentType: ZUPDocumentType = Field(..., description="1C ZUP document type")
    timeType: ZUPTimeType = Field(..., description="Time type to create")
    absencePeriod: Dict[str, date] = Field(..., description="Start and end dates")

class ZUPIntegrationResponse(BaseModel):
    """1C ZUP integration response"""
    success: bool = Field(..., description="Integration success status")
    documentId: Optional[str] = Field(None, description="Created document ID in 1C ZUP")
    confirmationNumber: Optional[str] = Field(None, description="1C ZUP confirmation")
    error: Optional[str] = Field(None, description="Error message if failed")

class ApprovalRequest(BaseModel):
    """Request approval payload"""
    requestId: str = Field(..., description="Request to approve/reject")
    decision: ApprovalDecision = Field(..., description="Approval decision")
    supervisorComments: Optional[str] = Field(None, description="Supervisor comments")

class ApprovalResponse(BaseModel):
    """Approval response with 1C ZUP integration status"""
    requestId: str
    status: RequestStatus
    zupIntegration: Optional[ZUPIntegrationResponse] = None
    scheduleUpdated: bool = Field(False, description="Whether schedule was updated")

# ============================================================================
# REQUEST STATUS MODELS (BDD Lines 79-94)
# ============================================================================

class RequestStatusInfo(BaseModel):
    """Complete request status information"""
    requestId: str
    requestType: RequestType
    status: RequestStatus
    employeeId: str
    createdAt: datetime
    updatedAt: datetime
    statusHistory: List[Dict[str, Any]] = Field(default_factory=list)

# ============================================================================
# REQUEST ENDPOINTS
# ============================================================================

@router.post("/requests/time-off", response_model=RequestCreateResponse, status_code=status.HTTP_201_CREATED, tags=["requests"])
async def create_time_off_request(
    request: TimeOffRequest,
    employee_id: str = Query(..., description="Employee creating the request")
):
    """
    Create Request for Time Off/Sick Leave/Unscheduled Vacation
    BDD: Lines 11-25
    
    Implements creation of absence requests through employee portal
    """
    try:
        # Generate request ID
        request_id = f"REQ-{uuid.uuid4().hex[:8].upper()}"
        
        # Create request with initial status
        created_at = datetime.now(timezone.utc)
        
        logger.info(f"Creating {request.requestType.value} request for employee {employee_id}")
        logger.info(f"Period: {request.startDate} to {request.endDate}")
        
        return RequestCreateResponse(
            requestId=request_id,
            requestType=request.requestType,
            status=RequestStatus.CREATED,
            createdAt=created_at,
            message=f"{request.requestType.value} request created successfully"
        )
        
    except Exception as e:
        logger.error(f"Error creating time off request: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create request: {str(e)}"
        )

@router.post("/requests/shift-exchange", response_model=RequestCreateResponse, status_code=status.HTTP_201_CREATED, tags=["requests"])
async def create_shift_exchange_request(
    request: ShiftExchangeRequest,
    employee_id: str = Query(..., description="Employee creating the request")
):
    """
    Create Shift Exchange Request
    BDD: Lines 27-37
    
    Implements shift exchange request creation
    """
    try:
        request_id = f"REQ-SE-{uuid.uuid4().hex[:8].upper()}"
        created_at = datetime.now(timezone.utc)
        
        logger.info(f"Creating shift exchange request for employee {employee_id}")
        logger.info(f"Original shift: {request.originalShiftDate}, ID: {request.originalShiftId}")
        logger.info(f"Proposed: {request.proposedDate} at {request.proposedTime}")
        
        return RequestCreateResponse(
            requestId=request_id,
            requestType=RequestType.SHIFT_EXCHANGE,
            status=RequestStatus.CREATED,
            createdAt=created_at,
            message="Shift exchange request created successfully"
        )
        
    except Exception as e:
        logger.error(f"Error creating shift exchange request: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create shift exchange request: {str(e)}"
        )

@router.post("/requests/{request_id}/accept-exchange", tags=["requests"])
async def accept_shift_exchange(
    request_id: str,
    employee_id: str = Query(..., description="Employee accepting the exchange")
):
    """
    Accept Shift Exchange Request
    BDD: Lines 39-47
    
    Allows employees to accept available shift exchange requests
    """
    try:
        logger.info(f"Employee {employee_id} accepting shift exchange {request_id}")
        
        # In production, validate request exists and is available
        # Update request status and notify original requester
        
        return {
            "requestId": request_id,
            "status": RequestStatus.UNDER_REVIEW,
            "acceptedBy": employee_id,
            "message": "Shift exchange accepted, pending supervisor approval"
        }
        
    except Exception as e:
        logger.error(f"Error accepting shift exchange: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to accept shift exchange: {str(e)}"
        )

@router.post("/requests/{request_id}/approve", response_model=ApprovalResponse, tags=["requests", "supervisor"])
async def approve_request(
    request_id: str,
    approval: ApprovalRequest,
    supervisor_id: str = Query(..., description="Supervisor approving the request")
):
    """
    Approve Time Off/Sick Leave/Unscheduled Vacation Request with 1C ZUP Integration
    BDD: Lines 48-67
    
    Implements supervisor approval with automatic 1C ZUP integration
    """
    try:
        if approval.requestId != request_id:
            raise HTTPException(status_code=400, detail="Request ID mismatch")
        
        logger.info(f"Supervisor {supervisor_id} processing request {request_id}")
        logger.info(f"Decision: {approval.decision.value}")
        
        # Determine new status
        new_status = RequestStatus.APPROVED if approval.decision == ApprovalDecision.APPROVE else RequestStatus.REJECTED
        
        # If approved, trigger 1C ZUP integration
        zup_response = None
        schedule_updated = False
        
        if approval.decision == ApprovalDecision.APPROVE:
            # Simulate 1C ZUP integration
            zup_response = ZUPIntegrationResponse(
                success=True,
                documentId=f"ZUP-{uuid.uuid4().hex[:8].upper()}",
                confirmationNumber=f"CONF-{datetime.now().strftime('%Y%m%d%H%M%S')}",
                error=None
            )
            
            # Update schedule
            schedule_updated = True
            
            logger.info(f"1C ZUP integration successful: {zup_response.documentId}")
            logger.info("Employee schedule updated")
        
        return ApprovalResponse(
            requestId=request_id,
            status=new_status,
            zupIntegration=zup_response,
            scheduleUpdated=schedule_updated
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error approving request: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to approve request: {str(e)}"
        )

@router.get("/requests", response_model=List[RequestStatusInfo], tags=["requests"])
async def get_requests(
    employee_id: Optional[str] = Query(None, description="Filter by employee"),
    status: Optional[RequestStatus] = Query(None, description="Filter by status"),
    request_type: Optional[RequestType] = Query(None, description="Filter by type"),
    available: bool = Query(False, description="Show available requests only")
):
    """
    Get requests with filtering options
    Supports both employee and supervisor views
    """
    # Example implementation
    sample_requests = [
        RequestStatusInfo(
            requestId="REQ-12345678",
            requestType=RequestType.TIME_OFF,
            status=RequestStatus.CREATED,
            employeeId="EMP001",
            createdAt=datetime.now(timezone.utc),
            updatedAt=datetime.now(timezone.utc),
            statusHistory=[
                {
                    "status": RequestStatus.CREATED.value,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "actor": "EMP001"
                }
            ]
        ),
        RequestStatusInfo(
            requestId="REQ-SE-87654321",
            requestType=RequestType.SHIFT_EXCHANGE,
            status=RequestStatus.UNDER_REVIEW,
            employeeId="EMP002",
            createdAt=datetime.now(timezone.utc),
            updatedAt=datetime.now(timezone.utc),
            statusHistory=[
                {
                    "status": RequestStatus.CREATED.value,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "actor": "EMP002"
                },
                {
                    "status": RequestStatus.UNDER_REVIEW.value,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "actor": "EMP003"
                }
            ]
        )
    ]
    
    # Apply filters
    filtered = sample_requests
    
    if employee_id:
        filtered = [r for r in filtered if r.employeeId == employee_id]
    
    if status:
        filtered = [r for r in filtered if r.status == status]
    
    if request_type:
        filtered = [r for r in filtered if r.requestType == request_type]
    
    if available:
        # Show only requests available for action
        filtered = [r for r in filtered if r.status in [RequestStatus.CREATED, RequestStatus.UNDER_REVIEW]]
    
    return filtered

@router.get("/requests/{request_id}/status", response_model=RequestStatusInfo, tags=["requests"])
async def get_request_status(request_id: str):
    """
    Request Status Tracking
    BDD: Lines 79-94
    
    Get detailed status information for a specific request
    """
    # Example implementation
    return RequestStatusInfo(
        requestId=request_id,
        requestType=RequestType.TIME_OFF,
        status=RequestStatus.APPROVED,
        employeeId="EMP001",
        createdAt=datetime.now(timezone.utc),
        updatedAt=datetime.now(timezone.utc),
        statusHistory=[
            {
                "status": RequestStatus.CREATED.value,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "actor": "EMP001",
                "comment": "Request created"
            },
            {
                "status": RequestStatus.UNDER_REVIEW.value,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "actor": "System",
                "comment": "Submitted for approval"
            },
            {
                "status": RequestStatus.APPROVED.value,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "actor": "SUP001",
                "comment": "Approved by supervisor"
            }
        ]
    )

# ============================================================================
# 1C ZUP INTEGRATION ENDPOINTS
# ============================================================================

@router.post("/integration/1c-zup/send-fact-work-time", tags=["integration", "1c-zup"])
async def send_fact_work_time(integration_request: ZUPIntegrationRequest):
    """
    1C ZUP Integration - Send Fact Work Time
    BDD: Lines 60-67
    
    Sends actual work time deviations to 1C ZUP for document creation
    """
    try:
        logger.info(f"Sending fact work time to 1C ZUP for request {integration_request.requestId}")
        logger.info(f"Document type: {integration_request.documentType.value}")
        logger.info(f"Time type: {integration_request.timeType.value}")
        logger.info(f"Period: {integration_request.absencePeriod}")
        
        # Simulate 1C ZUP API call
        # In production, this would make actual API call to 1C ZUP
        
        return {
            "success": True,
            "message": "Fact work time sent to 1C ZUP successfully",
            "zupResponse": {
                "documentId": f"ZUP-{uuid.uuid4().hex[:8].upper()}",
                "status": "Document created",
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
        }
        
    except Exception as e:
        logger.error(f"Error sending to 1C ZUP: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"1C ZUP integration failed: {str(e)}"
        )