from typing import Dict, Any
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.core.database import get_db
from src.api.v1.schemas.workflows import (
    ExcelImportResponse,
    ImportValidationRequest,
    ImportValidationResponse,
    ImportSaveRequest,
    ImportSaveResponse,
    WorkflowStatusResponse
)
from src.api.services.workflow_service import WorkflowService

excel_import_router = APIRouter()
validation_router = APIRouter()


@excel_import_router.post("/historical", response_model=ExcelImportResponse)
async def import_historical_data(
    file: UploadFile = File(...),
    background_tasks: BackgroundTasks = BackgroundTasks(),
    db: AsyncSession = Depends(get_db),
):
    """
    Import historical data from Excel file.
    Automates Argus manual UI workflow: gear → Import → Save.
    """
    try:
        if not file.filename.endswith(('.xlsx', '.xls')):
            raise ValueError("File must be Excel format (.xlsx or .xls)")
        
        service = WorkflowService(db)
        
        # Process file upload
        upload_id = await service.process_excel_upload(file)
        
        # Start async processing
        background_tasks.add_task(
            service.process_historical_import,
            upload_id,
            await file.read()
        )
        
        return ExcelImportResponse(
            upload_id=upload_id,
            status="processing",
            message="Historical data import started"
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@excel_import_router.post("/forecasts", response_model=ExcelImportResponse)
async def import_forecast_data(
    file: UploadFile = File(...),
    background_tasks: BackgroundTasks = BackgroundTasks(),
    db: AsyncSession = Depends(get_db),
):
    """
    Import forecast data from Excel file.
    Automates manual forecast upload process.
    """
    try:
        if not file.filename.endswith(('.xlsx', '.xls')):
            raise ValueError("File must be Excel format (.xlsx or .xls)")
        
        service = WorkflowService(db)
        
        # Process file upload
        upload_id = await service.process_excel_upload(file)
        
        # Start async processing
        background_tasks.add_task(
            service.process_forecast_import,
            upload_id,
            await file.read()
        )
        
        return ExcelImportResponse(
            upload_id=upload_id,
            status="processing",
            message="Forecast data import started"
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@validation_router.post("/import/{upload_id}", response_model=ImportValidationResponse)
async def validate_import(
    upload_id: str,
    request: ImportValidationRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Validate imported data before saving.
    Provides detailed validation results.
    """
    try:
        service = WorkflowService(db)
        result = await service.validate_import(upload_id, request)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@validation_router.post("/save/{upload_id}", response_model=ImportSaveResponse)
async def save_import(
    upload_id: str,
    request: ImportSaveRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Save validated import data to database.
    Final step in import workflow.
    """
    try:
        service = WorkflowService(db)
        result = await service.save_import(upload_id, request)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@excel_import_router.get("/status/{upload_id}", response_model=WorkflowStatusResponse)
async def get_workflow_status(
    upload_id: str,
    db: AsyncSession = Depends(get_db),
):
    """
    Get status of import workflow.
    """
    try:
        service = WorkflowService(db)
        result = await service.get_workflow_status(upload_id)
        return result
    except ValueError as e:
        raise HTTPException(status_code=404, detail="Upload not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")