from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.core.database import get_db
from src.api.v1.schemas.online import (
    AgentStatusResponse,
    GroupOnlineLoadResponse
)
from src.api.services.online_service import OnlineService
from src.api.utils.cache import cache_decorator

router = APIRouter()


@router.get("/agentStatus", response_model=List[AgentStatusResponse])
@cache_decorator(expire=10)
async def get_agent_status(
    agent_ids: Optional[str] = Query(None, description="Comma-separated agent IDs"),
    group_ids: Optional[str] = Query(None, description="Comma-separated group IDs"),
    db: AsyncSession = Depends(get_db),
):
    """
    Retrieve current agent status information.
    Real-time data with 10-second cache for performance.
    """
    try:
        agent_id_list = [int(id.strip()) for id in agent_ids.split(",")] if agent_ids else None
        group_id_list = [int(id.strip()) for id in group_ids.split(",")] if group_ids else None
        
        service = OnlineService(db)
        result = await service.get_agent_status(
            agent_ids=agent_id_list,
            group_ids=group_id_list
        )
        
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid parameter format: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@router.get("/groupsOnlineLoad", response_model=List[GroupOnlineLoadResponse])
@cache_decorator(expire=10)
async def get_groups_online_load(
    group_ids: Optional[str] = Query(None, description="Comma-separated group IDs"),
    service_ids: Optional[str] = Query(None, description="Comma-separated service IDs"),
    db: AsyncSession = Depends(get_db),
):
    """
    Retrieve real-time group metrics and queue statistics.
    Includes current load, SLA performance, and queue depth.
    """
    try:
        group_id_list = [int(id.strip()) for id in group_ids.split(",")] if group_ids else None
        service_id_list = [int(id.strip()) for id in service_ids.split(",")] if service_ids else None
        
        service = OnlineService(db)
        result = await service.get_groups_online_load(
            group_ids=group_id_list,
            service_ids=service_id_list
        )
        
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid parameter format: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")