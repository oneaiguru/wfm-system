from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.core.database import get_db
from src.api.v1.schemas.status import AgentStatusUpdate
from src.api.services.status_service import StatusService
from src.api.utils.validators import validate_timestamp

router = APIRouter()


@router.post("/api/rest/status")
async def update_agent_status(
    status_update: AgentStatusUpdate,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
):
    """
    Receive real-time agent status changes.
    Fire-and-forget pattern for high throughput.
    No response body required.
    """
    try:
        validate_timestamp(status_update.timestamp)
        
        service = StatusService(db)
        
        # Process asynchronously in background
        background_tasks.add_task(
            service.process_status_update,
            status_update
        )
        
        return {"status": "accepted"}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")