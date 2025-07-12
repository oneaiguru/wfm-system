from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.core.database import get_db
from src.api.v1.schemas.personnel import PersonnelResponse, Service, Agent
from src.api.services.personnel_service import PersonnelService
from src.api.utils.cache import cache_decorator

router = APIRouter()


@router.get("", response_model=PersonnelResponse)
@cache_decorator(expire=3600)
async def get_personnel(
    service_ids: Optional[str] = Query(None, description="Comma-separated service IDs"),
    group_ids: Optional[str] = Query(None, description="Comma-separated group IDs"),
    agent_ids: Optional[str] = Query(None, description="Comma-separated agent IDs"),
    db: AsyncSession = Depends(get_db),
):
    """
    Retrieve personnel and organizational structure data.
    
    Returns services array and agents array with detailed object structures.
    All agents must have group assignments to be included.
    """
    try:
        service = PersonnelService(db)
        
        service_id_list = [int(id.strip()) for id in service_ids.split(",")] if service_ids else None
        group_id_list = [int(id.strip()) for id in group_ids.split(",")] if group_ids else None
        agent_id_list = [int(id.strip()) for id in agent_ids.split(",")] if agent_ids else None
        
        result = await service.get_personnel_data(
            service_ids=service_id_list,
            group_ids=group_id_list,
            agent_ids=agent_id_list
        )
        
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid parameter format: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")