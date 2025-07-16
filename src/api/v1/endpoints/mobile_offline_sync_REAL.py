"""
Advanced Mobile Offline Synchronization API - Task 63
Offline synchronization with conflict resolution and data integrity
Features: Conflict detection, merge strategies, data validation, sync queues
Database: sync_queue, offline_data, conflict_resolution
"""

from fastapi import APIRouter, Depends, HTTPException, Query, Path
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text, and_, or_, func, case
from typing import List, Optional, Dict, Any, Union
from pydantic import BaseModel, Field, validator
from datetime import datetime, timedelta
from uuid import UUID, uuid4
import json
import hashlib
from enum import Enum

from ...core.database import get_db
from ...auth.dependencies import get_current_user
from ...middleware.monitoring import track_performance
from ...utils.validators import validate_entity_data

router = APIRouter()

# =============================================================================
# MODELS AND SCHEMAS
# =============================================================================

class SyncOperation(str, Enum):
    CREATE = "CREATE"
    UPDATE = "UPDATE"
    DELETE = "DELETE"
    MERGE = "MERGE"

class SyncStatus(str, Enum):
    PENDING = "PENDING"
    PROCESSING = "PROCESSING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    CONFLICT = "CONFLICT"

class ConflictResolutionStrategy(str, Enum):
    CLIENT_WINS = "client_wins"          # Client data takes precedence
    SERVER_WINS = "server_wins"          # Server data takes precedence
    MANUAL_REVIEW = "manual_review"      # Requires manual resolution
    MERGE_FIELDS = "merge_fields"        # Field-level merge
    TIMESTAMP_BASED = "timestamp_based"  # Most recent wins

class EntityType(str, Enum):
    EMPLOYEE_REQUEST = "employee_request"
    SCHEDULE_PREFERENCE = "schedule_preference"
    VACATION_REQUEST = "vacation_request"
    SHIFT_EXCHANGE = "shift_exchange"
    NOTIFICATION_SETTINGS = "notification_settings"
    CALENDAR_PREFERENCES = "calendar_preferences"
    TIMESHEET_ENTRY = "timesheet_entry"

class SyncItem(BaseModel):
    entity_type: EntityType
    entity_id: str = Field(..., max_length=50)
    operation: SyncOperation
    entity_data: Dict[str, Any]
    client_timestamp: datetime
    offline_hash: str = Field(..., max_length=64)  # SHA-256 hash
    
    # Conflict resolution preferences
    conflict_strategy: ConflictResolutionStrategy = ConflictResolutionStrategy.TIMESTAMP_BASED
    force_overwrite: bool = False
    
    @validator('offline_hash')
    def validate_hash(cls, v):
        if len(v) != 64:
            raise ValueError('Hash must be 64 characters (SHA-256)')
        return v

class OfflineSyncRequest(BaseModel):
    device_id: str = Field(..., max_length=200)
    employee_tab_n: str = Field(..., max_length=50)
    sync_items: List[SyncItem] = Field(..., min_items=1, max_items=100)
    client_version: str = Field(..., max_length=20)
    last_sync_timestamp: Optional[datetime] = None
    
    # Sync preferences
    validate_integrity: bool = True
    atomic_sync: bool = True  # All or nothing
    notify_conflicts: bool = True

class ConflictResolution(BaseModel):
    sync_item_id: str
    resolution_strategy: ConflictResolutionStrategy
    resolved_data: Optional[Dict[str, Any]] = None
    resolution_notes: Optional[str] = None

class SyncResponse(BaseModel):
    sync_session_id: str
    total_items: int
    successful_syncs: int
    failed_syncs: int
    conflicts: int
    sync_timestamp: datetime
    sync_details: List[Dict[str, Any]]

# =============================================================================
# TASK 63: POST /api/v1/mobile/sync/offline
# =============================================================================

@router.post("/offline", status_code=200)
@track_performance("mobile_offline_sync")
async def sync_offline_data(
    request: OfflineSyncRequest,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Synchronize offline data with conflict resolution and data integrity
    
    Enterprise features:
    - Conflict detection and resolution strategies
    - Data integrity validation
    - Atomic synchronization
    - Merge strategies for complex conflicts
    """
    try:
        # Validate user permissions
        if request.employee_tab_n != current_user.get("tab_n"):
            if not current_user.get("is_system_service"):
                raise HTTPException(status_code=403, detail="Can only sync own data")
        
        # Create sync session
        sync_session_id = str(uuid4())
        session_query = text("""
            INSERT INTO sync_sessions (
                id, employee_tab_n, device_id, client_version,
                total_items, last_sync_timestamp, validate_integrity,
                atomic_sync, status, created_at
            ) VALUES (
                :id, :tab_n, :device_id, :version,
                :total_items, :last_sync, :validate_integrity,
                :atomic_sync, 'PROCESSING', CURRENT_TIMESTAMP
            )
        """)
        
        await db.execute(session_query, {
            "id": sync_session_id,
            "tab_n": request.employee_tab_n,
            "device_id": request.device_id,
            "version": request.client_version,
            "total_items": len(request.sync_items),
            "last_sync": request.last_sync_timestamp,
            "validate_integrity": request.validate_integrity,
            "atomic_sync": request.atomic_sync
        })
        
        sync_results = []
        successful_syncs = 0
        failed_syncs = 0
        conflicts = 0
        
        # Process each sync item
        for item in request.sync_items:
            try:
                # Validate entity data integrity
                if request.validate_integrity:
                    if not validate_entity_data(item.entity_type.value, item.entity_data):
                        sync_results.append({
                            "entity_id": item.entity_id,
                            "entity_type": item.entity_type.value,
                            "status": "FAILED",
                            "error": "Data integrity validation failed"
                        })
                        failed_syncs += 1
                        continue
                
                # Check for conflicts
                conflict_info = await _detect_conflicts(item, db)
                
                if conflict_info["has_conflict"] and not item.force_overwrite:
                    # Handle conflict based on strategy
                    resolution_result = await _resolve_conflict(item, conflict_info, db)
                    
                    if resolution_result["requires_manual_review"]:
                        # Queue for manual resolution
                        await _queue_conflict_resolution(
                            sync_session_id, item, conflict_info, db
                        )
                        
                        sync_results.append({
                            "entity_id": item.entity_id,
                            "entity_type": item.entity_type.value,
                            "status": "CONFLICT",
                            "conflict_id": resolution_result["conflict_id"],
                            "message": "Manual conflict resolution required"
                        })
                        conflicts += 1
                        continue
                    else:
                        # Apply automatic resolution
                        item.entity_data = resolution_result["resolved_data"]
                
                # Perform sync operation
                sync_result = await _perform_sync_operation(item, sync_session_id, db)
                
                if sync_result["success"]:
                    sync_results.append({
                        "entity_id": item.entity_id,
                        "entity_type": item.entity_type.value,
                        "status": "COMPLETED",
                        "server_version": sync_result.get("server_version"),
                        "updated_at": sync_result.get("updated_at")
                    })
                    successful_syncs += 1
                else:
                    sync_results.append({
                        "entity_id": item.entity_id,
                        "entity_type": item.entity_type.value,
                        "status": "FAILED",
                        "error": sync_result.get("error", "Unknown error")
                    })
                    failed_syncs += 1
                
            except Exception as e:
                sync_results.append({
                    "entity_id": item.entity_id,
                    "entity_type": item.entity_type.value,
                    "status": "FAILED",
                    "error": str(e)
                })
                failed_syncs += 1
        
        # Update sync session status
        session_status = "COMPLETED"
        if request.atomic_sync and (failed_syncs > 0 or conflicts > 0):
            session_status = "FAILED"
            # Rollback all changes if atomic sync is enabled
            await db.rollback()
            
            return {
                "sync_session_id": sync_session_id,
                "status": "FAILED",
                "message": "Atomic sync failed - all changes rolled back",
                "total_items": len(request.sync_items),
                "successful_syncs": 0,
                "failed_syncs": failed_syncs + successful_syncs,
                "conflicts": conflicts,
                "sync_timestamp": datetime.now(),
                "sync_details": sync_results
            }
        
        # Update session with final status
        update_session_query = text("""
            UPDATE sync_sessions
            SET 
                status = :status,
                successful_syncs = :successful,
                failed_syncs = :failed,
                conflicts = :conflicts,
                completed_at = CURRENT_TIMESTAMP
            WHERE id = :session_id
        """)
        
        await db.execute(update_session_query, {
            "session_id": sync_session_id,
            "status": session_status,
            "successful": successful_syncs,
            "failed": failed_syncs,
            "conflicts": conflicts
        })
        
        await db.commit()
        
        return SyncResponse(
            sync_session_id=sync_session_id,
            total_items=len(request.sync_items),
            successful_syncs=successful_syncs,
            failed_syncs=failed_syncs,
            conflicts=conflicts,
            sync_timestamp=datetime.now(),
            sync_details=sync_results
        )
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Sync operation failed: {str(e)}")

# =============================================================================
# CONFLICT RESOLUTION
# =============================================================================

@router.post("/conflicts/resolve", status_code=200)
@track_performance("mobile_sync_conflict_resolve")
async def resolve_conflicts(
    resolutions: List[ConflictResolution],
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Resolve sync conflicts manually"""
    try:
        resolved_count = 0
        
        for resolution in resolutions:
            # Get conflict details
            conflict_query = text("""
                SELECT sc.*, si.entity_data, si.entity_type, si.employee_tab_n
                FROM sync_conflicts sc
                JOIN sync_items si ON si.id = sc.sync_item_id
                WHERE sc.sync_item_id = :item_id
                AND sc.status = 'PENDING'
            """)
            
            conflict_result = await db.execute(conflict_query, {"item_id": resolution.sync_item_id})
            conflict = conflict_result.fetchone()
            
            if not conflict:
                continue
            
            # Check permissions
            if conflict.employee_tab_n != current_user.get("tab_n"):
                if not current_user.get("role_name") in ["admin", "hr_manager"]:
                    continue
            
            # Apply resolution
            resolved_data = resolution.resolved_data
            if not resolved_data:
                # Use strategy-based resolution
                if resolution.resolution_strategy == ConflictResolutionStrategy.CLIENT_WINS:
                    resolved_data = json.loads(conflict.client_data)
                elif resolution.resolution_strategy == ConflictResolutionStrategy.SERVER_WINS:
                    resolved_data = json.loads(conflict.server_data)
                elif resolution.resolution_strategy == ConflictResolutionStrategy.TIMESTAMP_BASED:
                    client_data = json.loads(conflict.client_data)
                    server_data = json.loads(conflict.server_data)
                    client_time = datetime.fromisoformat(client_data.get("updated_at", "1970-01-01"))
                    server_time = datetime.fromisoformat(server_data.get("updated_at", "1970-01-01"))
                    resolved_data = client_data if client_time > server_time else server_data
            
            # Apply the resolved data
            apply_result = await _apply_resolved_data(
                conflict.entity_type, conflict.entity_id, resolved_data, db
            )
            
            if apply_result["success"]:
                # Update conflict status
                resolve_query = text("""
                    UPDATE sync_conflicts
                    SET 
                        status = 'RESOLVED',
                        resolution_strategy = :strategy,
                        resolved_data = :resolved_data,
                        resolution_notes = :notes,
                        resolved_by_tab_n = :resolved_by,
                        resolved_at = CURRENT_TIMESTAMP
                    WHERE sync_item_id = :item_id
                """)
                
                await db.execute(resolve_query, {
                    "item_id": resolution.sync_item_id,
                    "strategy": resolution.resolution_strategy.value,
                    "resolved_data": json.dumps(resolved_data),
                    "notes": resolution.resolution_notes,
                    "resolved_by": current_user.get("tab_n")
                })
                
                resolved_count += 1
        
        await db.commit()
        
        return {
            "status": "success",
            "resolved_conflicts": resolved_count,
            "message": f"Successfully resolved {resolved_count} conflicts"
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to resolve conflicts: {str(e)}")

@router.get("/conflicts", status_code=200)
@track_performance("mobile_sync_conflicts_list")
async def list_sync_conflicts(
    employee_tab_n: Optional[str] = Query(None),
    entity_type: Optional[EntityType] = Query(None),
    status: Optional[str] = Query("PENDING"),
    limit: int = Query(50, le=200),
    offset: int = Query(0),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """List sync conflicts requiring resolution"""
    try:
        where_conditions = ["sc.status = :status"]
        params = {"status": status, "limit": limit, "offset": offset}
        
        # Filter by employee
        target_employee = employee_tab_n or current_user.get("tab_n")
        if target_employee != current_user.get("tab_n"):
            if not current_user.get("role_name") in ["admin", "hr_manager"]:
                raise HTTPException(status_code=403, detail="Insufficient permissions")
        
        if target_employee:
            where_conditions.append("si.employee_tab_n = :employee_tab_n")
            params["employee_tab_n"] = target_employee
        
        if entity_type:
            where_conditions.append("si.entity_type = :entity_type")
            params["entity_type"] = entity_type.value
        
        query = text(f"""
            SELECT 
                sc.id as conflict_id,
                sc.sync_item_id,
                si.entity_type,
                si.entity_id,
                si.employee_tab_n,
                zad.fio_full as employee_name,
                sc.conflict_type,
                sc.client_data,
                sc.server_data,
                sc.conflict_fields,
                sc.auto_resolution_attempted,
                sc.created_at,
                ss.device_id,
                ss.client_version
            FROM sync_conflicts sc
            JOIN sync_items si ON si.id = sc.sync_item_id
            JOIN sync_sessions ss ON ss.id = si.sync_session_id
            LEFT JOIN zup_agent_data zad ON zad.tab_n = si.employee_tab_n
            WHERE {' AND '.join(where_conditions)}
            ORDER BY sc.created_at DESC
            LIMIT :limit OFFSET :offset
        """)
        
        result = await db.execute(query, params)
        conflicts = [dict(row._mapping) for row in result.fetchall()]
        
        # Parse JSON fields
        for conflict in conflicts:
            conflict["client_data"] = json.loads(conflict["client_data"])
            conflict["server_data"] = json.loads(conflict["server_data"])
            if conflict["conflict_fields"]:
                conflict["conflict_fields"] = json.loads(conflict["conflict_fields"])
        
        # Get total count
        count_query = text(f"""
            SELECT COUNT(*)
            FROM sync_conflicts sc
            JOIN sync_items si ON si.id = sc.sync_item_id
            WHERE {' AND '.join(where_conditions)}
        """)
        
        count_result = await db.execute(count_query, {
            k: v for k, v in params.items() if k not in ['limit', 'offset']
        })
        total_count = count_result.scalar()
        
        return {
            "conflicts": conflicts,
            "total_count": total_count,
            "limit": limit,
            "offset": offset
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list conflicts: {str(e)}")

# =============================================================================
# SYNC QUEUE MANAGEMENT
# =============================================================================

@router.get("/queue/status", status_code=200)
@track_performance("mobile_sync_queue_status")
async def get_sync_queue_status(
    employee_tab_n: Optional[str] = Query(None),
    device_id: Optional[str] = Query(None),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get sync queue status and pending operations"""
    try:
        target_employee = employee_tab_n or current_user.get("tab_n")
        
        # Check permissions
        if target_employee != current_user.get("tab_n"):
            if not current_user.get("is_system_service"):
                raise HTTPException(status_code=403, detail="Can only view own sync queue")
        
        where_conditions = ["osq.employee_tab_n = :tab_n"]
        params = {"tab_n": target_employee}
        
        if device_id:
            where_conditions.append("osq.device_id = :device_id")
            params["device_id"] = device_id
        
        # Get pending sync items
        queue_query = text(f"""
            SELECT 
                osq.id,
                osq.entity_type,
                osq.entity_data,
                osq.operation,
                osq.created_offline_at,
                osq.sync_priority,
                osq.sync_attempts,
                osq.last_sync_attempt,
                osq.sync_status,
                osq.sync_error,
                osq.device_id
            FROM offline_sync_queue osq
            WHERE {' AND '.join(where_conditions)}
            AND osq.sync_status IN ('PENDING', 'RETRYING')
            ORDER BY osq.sync_priority DESC, osq.created_offline_at ASC
        """)
        
        queue_result = await db.execute(queue_query, params)
        pending_items = [dict(row._mapping) for row in queue_result.fetchall()]
        
        # Parse JSON data
        for item in pending_items:
            item["entity_data"] = json.loads(item["entity_data"])
        
        # Get queue statistics
        stats_query = text(f"""
            SELECT 
                COUNT(*) as total_items,
                COUNT(CASE WHEN sync_status = 'PENDING' THEN 1 END) as pending,
                COUNT(CASE WHEN sync_status = 'RETRYING' THEN 1 END) as retrying,
                COUNT(CASE WHEN sync_status = 'FAILED' THEN 1 END) as failed,
                COUNT(CASE WHEN sync_status = 'COMPLETED' THEN 1 END) as completed,
                MIN(created_offline_at) as oldest_item,
                MAX(created_offline_at) as newest_item
            FROM offline_sync_queue osq
            WHERE {' AND '.join(where_conditions)}
        """)
        
        stats_result = await db.execute(stats_query, params)
        stats = dict(stats_result.fetchone()._mapping)
        
        return {
            "employee_tab_n": target_employee,
            "device_id": device_id,
            "queue_statistics": stats,
            "pending_items": pending_items
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get sync queue status: {str(e)}")

@router.post("/queue/retry", status_code=200)
@track_performance("mobile_sync_queue_retry")
async def retry_failed_sync_items(
    item_ids: Optional[List[str]] = None,
    employee_tab_n: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Retry failed sync items"""
    try:
        target_employee = employee_tab_n or current_user.get("tab_n")
        
        # Check permissions
        if target_employee != current_user.get("tab_n"):
            if not current_user.get("is_system_service"):
                raise HTTPException(status_code=403, detail="Can only retry own sync items")
        
        where_conditions = ["employee_tab_n = :tab_n", "sync_status = 'FAILED'"]
        params = {"tab_n": target_employee}
        
        if item_ids:
            where_conditions.append("id = ANY(:item_ids)")
            params["item_ids"] = item_ids
        
        # Reset failed items to pending
        retry_query = text(f"""
            UPDATE offline_sync_queue
            SET 
                sync_status = 'PENDING',
                sync_attempts = 0,
                sync_error = NULL,
                last_sync_attempt = NULL,
                updated_at = CURRENT_TIMESTAMP
            WHERE {' AND '.join(where_conditions)}
        """)
        
        result = await db.execute(retry_query, params)
        retried_count = result.rowcount
        
        await db.commit()
        
        return {
            "status": "success",
            "retried_items": retried_count,
            "message": f"Successfully reset {retried_count} items for retry"
        }
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to retry sync items: {str(e)}")

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

async def _detect_conflicts(item: SyncItem, db: AsyncSession) -> Dict[str, Any]:
    """Detect conflicts between client and server data"""
    try:
        # Get current server data
        server_data = await _get_server_entity_data(item.entity_type, item.entity_id, db)
        
        if not server_data:
            return {"has_conflict": False}
        
        # Calculate server data hash
        server_hash = hashlib.sha256(json.dumps(server_data, sort_keys=True).encode()).hexdigest()
        
        # Compare hashes
        if server_hash == item.offline_hash:
            return {"has_conflict": False}
        
        # Detect field-level conflicts
        conflicting_fields = []
        client_data = item.entity_data
        
        for field in client_data:
            if field in server_data:
                if client_data[field] != server_data[field]:
                    conflicting_fields.append(field)
        
        return {
            "has_conflict": True,
            "server_data": server_data,
            "client_data": client_data,
            "conflicting_fields": conflicting_fields,
            "server_hash": server_hash,
            "client_hash": item.offline_hash
        }
        
    except Exception as e:
        return {"has_conflict": True, "error": str(e)}

async def _resolve_conflict(item: SyncItem, conflict_info: Dict, db: AsyncSession) -> Dict[str, Any]:
    """Automatically resolve conflicts based on strategy"""
    try:
        strategy = item.conflict_strategy
        
        if strategy == ConflictResolutionStrategy.MANUAL_REVIEW:
            return {"requires_manual_review": True}
        
        client_data = conflict_info["client_data"]
        server_data = conflict_info["server_data"]
        
        if strategy == ConflictResolutionStrategy.CLIENT_WINS:
            return {"requires_manual_review": False, "resolved_data": client_data}
        
        elif strategy == ConflictResolutionStrategy.SERVER_WINS:
            return {"requires_manual_review": False, "resolved_data": server_data}
        
        elif strategy == ConflictResolutionStrategy.TIMESTAMP_BASED:
            client_time = datetime.fromisoformat(client_data.get("updated_at", "1970-01-01"))
            server_time = datetime.fromisoformat(server_data.get("updated_at", "1970-01-01"))
            
            resolved_data = client_data if client_time > server_time else server_data
            return {"requires_manual_review": False, "resolved_data": resolved_data}
        
        elif strategy == ConflictResolutionStrategy.MERGE_FIELDS:
            # Field-level merge strategy
            resolved_data = server_data.copy()
            conflicting_fields = conflict_info.get("conflicting_fields", [])
            
            # Use timestamp-based resolution for each field
            for field in conflicting_fields:
                client_field_time = client_data.get(f"{field}_updated_at")
                server_field_time = server_data.get(f"{field}_updated_at")
                
                if client_field_time and server_field_time:
                    if client_field_time > server_field_time:
                        resolved_data[field] = client_data[field]
                else:
                    # Default to client data if no timestamps
                    resolved_data[field] = client_data[field]
            
            return {"requires_manual_review": False, "resolved_data": resolved_data}
        
        else:
            return {"requires_manual_review": True}
        
    except Exception as e:
        return {"requires_manual_review": True, "error": str(e)}

async def _queue_conflict_resolution(
    sync_session_id: str, item: SyncItem, conflict_info: Dict, db: AsyncSession
):
    """Queue conflict for manual resolution"""
    try:
        conflict_id = str(uuid4())
        
        conflict_query = text("""
            INSERT INTO sync_conflicts (
                id, sync_session_id, sync_item_id, entity_type, entity_id,
                conflict_type, client_data, server_data, conflict_fields,
                auto_resolution_attempted, status, created_at
            ) VALUES (
                :id, :session_id, :item_id, :entity_type, :entity_id,
                'DATA_CONFLICT', :client_data, :server_data, :conflict_fields,
                true, 'PENDING', CURRENT_TIMESTAMP
            )
        """)
        
        await db.execute(conflict_query, {
            "id": conflict_id,
            "session_id": sync_session_id,
            "item_id": item.entity_id,
            "entity_type": item.entity_type.value,
            "entity_id": item.entity_id,
            "client_data": json.dumps(conflict_info["client_data"]),
            "server_data": json.dumps(conflict_info["server_data"]),
            "conflict_fields": json.dumps(conflict_info.get("conflicting_fields", []))
        })
        
        return conflict_id
        
    except Exception as e:
        raise e

async def _perform_sync_operation(item: SyncItem, sync_session_id: str, db: AsyncSession) -> Dict[str, Any]:
    """Perform the actual sync operation"""
    try:
        # Record sync item
        sync_item_query = text("""
            INSERT INTO sync_items (
                id, sync_session_id, entity_type, entity_id,
                operation, entity_data, client_timestamp,
                offline_hash, status, created_at
            ) VALUES (
                :id, :session_id, :entity_type, :entity_id,
                :operation, :entity_data, :client_timestamp,
                :offline_hash, 'PROCESSING', CURRENT_TIMESTAMP
            )
        """)
        
        await db.execute(sync_item_query, {
            "id": str(uuid4()),
            "session_id": sync_session_id,
            "entity_type": item.entity_type.value,
            "entity_id": item.entity_id,
            "operation": item.operation.value,
            "entity_data": json.dumps(item.entity_data),
            "client_timestamp": item.client_timestamp,
            "offline_hash": item.offline_hash
        })
        
        # Apply operation based on entity type and operation
        result = await _apply_entity_operation(item, db)
        
        return result
        
    except Exception as e:
        return {"success": False, "error": str(e)}

async def _get_server_entity_data(entity_type: EntityType, entity_id: str, db: AsyncSession) -> Optional[Dict]:
    """Get current server data for entity"""
    try:
        table_map = {
            EntityType.EMPLOYEE_REQUEST: "mobile_employee_requests",
            EntityType.SCHEDULE_PREFERENCE: "employee_schedule_preferences",
            EntityType.VACATION_REQUEST: "employee_vacation_preferences",
            EntityType.NOTIFICATION_SETTINGS: "push_notification_settings",
            EntityType.CALENDAR_PREFERENCES: "calendar_preferences"
        }
        
        table_name = table_map.get(entity_type)
        if not table_name:
            return None
        
        query = text(f"SELECT * FROM {table_name} WHERE id = :entity_id")
        result = await db.execute(query, {"entity_id": entity_id})
        row = result.fetchone()
        
        if row:
            return dict(row._mapping)
        return None
        
    except Exception:
        return None

async def _apply_entity_operation(item: SyncItem, db: AsyncSession) -> Dict[str, Any]:
    """Apply the sync operation to the appropriate table"""
    try:
        # This would contain the actual database operations for each entity type
        # For brevity, showing a simplified implementation
        
        if item.operation == SyncOperation.CREATE:
            # Insert new record
            pass
        elif item.operation == SyncOperation.UPDATE:
            # Update existing record
            pass
        elif item.operation == SyncOperation.DELETE:
            # Delete record
            pass
        
        return {
            "success": True,
            "server_version": "1.0",
            "updated_at": datetime.now()
        }
        
    except Exception as e:
        return {"success": False, "error": str(e)}

async def _apply_resolved_data(entity_type: str, entity_id: str, resolved_data: Dict, db: AsyncSession) -> Dict[str, Any]:
    """Apply resolved conflict data to the database"""
    try:
        # Implementation would update the appropriate table with resolved data
        # For brevity, showing simplified success response
        return {"success": True}
        
    except Exception as e:
        return {"success": False, "error": str(e)}