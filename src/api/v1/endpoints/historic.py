from datetime import datetime
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.core.database import get_db
from src.api.v1.schemas.historic import (
    ServiceGroupDataResponse,
    AgentStatusDataResponse,
    AgentLoginDataResponse,
    AgentCallsDataResponse,
    AgentChatsWorkTimeResponse
)
from src.api.services.historic_service import HistoricService
from src.api.utils.cache import cache_decorator
from src.api.utils.validators import validate_date_range

router = APIRouter()


@router.get("/serviceGroupData", response_model=ServiceGroupDataResponse)
@cache_decorator(expire=300)
async def get_service_group_data(
    start_date: datetime = Query(..., description="Start date in ISO 8601 format"),
    end_date: datetime = Query(..., description="End date in ISO 8601 format"),
    step: int = Query(..., description="Time interval step in milliseconds"),
    group_id: int = Query(..., description="Group ID"),
    db: AsyncSession = Depends(get_db),
):
    """
    Retrieve historical metrics by service groups.
    Returns interval-based metrics including contact volumes, AHT, and service levels.
    """
    try:
        validate_date_range(start_date, end_date)
        
        service = HistoricService(db)
        result = await service.get_service_group_data(
            start_date=start_date,
            end_date=end_date,
            step=step,
            group_id=group_id
        )
        
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@router.get("/agentStatusData", response_model=List[AgentStatusDataResponse])
@cache_decorator(expire=300)
async def get_agent_status_data(
    start_date: datetime = Query(..., description="Start date in ISO 8601 format"),
    end_date: datetime = Query(..., description="End date in ISO 8601 format"),
    agent_ids: Optional[str] = Query(None, description="Comma-separated agent IDs"),
    db: AsyncSession = Depends(get_db),
):
    """
    Retrieve historical agent status tracking data.
    """
    try:
        validate_date_range(start_date, end_date)
        
        agent_id_list = [int(id.strip()) for id in agent_ids.split(",")] if agent_ids else None
        
        service = HistoricService(db)
        result = await service.get_agent_status_data(
            start_date=start_date,
            end_date=end_date,
            agent_ids=agent_id_list
        )
        
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@router.get("/agentLoginData", response_model=List[AgentLoginDataResponse])
@cache_decorator(expire=300)
async def get_agent_login_data(
    start_date: datetime = Query(..., description="Start date in ISO 8601 format"),
    end_date: datetime = Query(..., description="End date in ISO 8601 format"),
    agent_ids: Optional[str] = Query(None, description="Comma-separated agent IDs"),
    db: AsyncSession = Depends(get_db),
):
    """
    Retrieve agent session/login history data.
    """
    try:
        validate_date_range(start_date, end_date)
        
        agent_id_list = [int(id.strip()) for id in agent_ids.split(",")] if agent_ids else None
        
        service = HistoricService(db)
        result = await service.get_agent_login_data(
            start_date=start_date,
            end_date=end_date,
            agent_ids=agent_id_list
        )
        
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@router.get("/agentCallsData", response_model=List[AgentCallsDataResponse])
@cache_decorator(expire=300)
async def get_agent_calls_data(
    start_date: datetime = Query(..., description="Start date in ISO 8601 format"),
    end_date: datetime = Query(..., description="End date in ISO 8601 format"),
    agent_ids: Optional[str] = Query(None, description="Comma-separated agent IDs"),
    db: AsyncSession = Depends(get_db),
):
    """
    Retrieve individual agent performance data.
    """
    try:
        validate_date_range(start_date, end_date)
        
        agent_id_list = [int(id.strip()) for id in agent_ids.split(",")] if agent_ids else None
        
        service = HistoricService(db)
        result = await service.get_agent_calls_data(
            start_date=start_date,
            end_date=end_date,
            agent_ids=agent_id_list
        )
        
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@router.get("/agentChatsWorkTime", response_model=List[AgentChatsWorkTimeResponse])
@cache_decorator(expire=300)
async def get_agent_chats_work_time(
    start_date: datetime = Query(..., description="Start date in ISO 8601 format"),
    end_date: datetime = Query(..., description="End date in ISO 8601 format"),
    agent_ids: Optional[str] = Query(None, description="Comma-separated agent IDs"),
    db: AsyncSession = Depends(get_db),
):
    """
    Retrieve chat-specific work time tracking data.
    Handles multi-chat scenarios and excludes bot-closed chats.
    """
    try:
        validate_date_range(start_date, end_date)
        
        agent_id_list = [int(id.strip()) for id in agent_ids.split(",")] if agent_ids else None
        
        service = HistoricService(db)
        result = await service.get_agent_chats_work_time(
            start_date=start_date,
            end_date=end_date,
            agent_ids=agent_id_list
        )
        
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")