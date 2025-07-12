from sqlalchemy.orm import Session
from sqlalchemy import and_, func
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any, BinaryIO
import pandas as pd
import asyncio
import logging
import uuid
import json
from pathlib import Path
import tempfile
import os

from ..utils.cache import cache_with_timeout
from ..utils.validators import validate_file_extension, validate_business_rules

logger = logging.getLogger(__name__)


class WorkflowService:
    """
    PHASE 2: Enhanced Workflow Service
    
    Handles Excel uploads, file validation, historical data processing,
    and forecast data import with business rule validation.
    """
    
    def __init__(self, db: Session):
        self.db = db
        self.upload_dir = Path(tempfile.gettempdir()) / "wfm_uploads"
        self.upload_dir.mkdir(exist_ok=True)
        
        # Track workflow statuses
        self.workflow_status = {}
    
    async def process_excel_upload(
        self, 
        file: BinaryIO, 
        filename: str, 
        upload_type: str = "historical"
    ) -> Dict[str, Any]:
        """
        Process Excel file upload with validation.
        
        Args:
            file: File binary data
            filename: Original filename
            upload_type: Type of upload (historical, forecast, personnel)
            
        Returns:
            Upload processing result
        """
        try:
            # Validate file extension
            if not validate_file_extension(filename, ['.xlsx', '.xls']):
                raise ValueError(f"Invalid file type. Only Excel files are allowed.")
            
            # Generate unique workflow ID
            workflow_id = str(uuid.uuid4())
            
            # Save file temporarily
            file_path = self.upload_dir / f"{workflow_id}_{filename}"
            with open(file_path, 'wb') as f:
                f.write(file.read())
            
            # Initialize workflow status
            self.workflow_status[workflow_id] = {
                "status": "processing",
                "progress": 0,
                "filename": filename,
                "upload_type": upload_type,
                "created_at": datetime.utcnow(),
                "stages": []
            }
            
            # Process file based on type
            if upload_type == "historical":
                result = await self._process_historical_excel(workflow_id, file_path)
            elif upload_type == "forecast":
                result = await self._process_forecast_excel(workflow_id, file_path)
            elif upload_type == "personnel":
                result = await self._process_personnel_excel(workflow_id, file_path)
            else:
                raise ValueError(f"Unknown upload type: {upload_type}")
            
            # Clean up temp file
            os.remove(file_path)
            
            return {
                "status": "success",
                "workflow_id": workflow_id,
                "message": "File uploaded and processing started",
                "result": result,
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error processing Excel upload: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "timestamp": datetime.utcnow().isoformat()
            }
    
    async def _process_historical_excel(self, workflow_id: str, file_path: Path) -> Dict[str, Any]:
        """Process historical data Excel file."""
        try:
            # Update status
            self.workflow_status[workflow_id]["stages"].append({
                "stage": "reading_file",
                "status": "started",
                "timestamp": datetime.utcnow()
            })
            
            # Read Excel file
            df = pd.read_excel(file_path)
            
            # Validate columns
            required_columns = ['timestamp', 'service_id', 'group_id', 'calls_received', 'calls_handled']
            missing_columns = [col for col in required_columns if col not in df.columns]
            
            if missing_columns:
                raise ValueError(f"Missing required columns: {missing_columns}")
            
            # Data validation
            self.workflow_status[workflow_id]["stages"].append({
                "stage": "validation",
                "status": "started",
                "timestamp": datetime.utcnow()
            })
            
            # Convert timestamps
            df['timestamp'] = pd.to_datetime(df['timestamp'])
            
            # Validate data quality
            validation_result = self._validate_historical_data(df)
            
            if validation_result["errors"]:
                self.workflow_status[workflow_id]["status"] = "validation_failed"
                self.workflow_status[workflow_id]["errors"] = validation_result["errors"]
                return {
                    "status": "validation_failed",
                    "errors": validation_result["errors"],
                    "warnings": validation_result["warnings"]
                }
            
            # Process data
            self.workflow_status[workflow_id]["stages"].append({
                "stage": "processing",
                "status": "started",
                "timestamp": datetime.utcnow()
            })
            
            processed_records = 0
            batch_size = 1000
            
            for i in range(0, len(df), batch_size):
                batch = df.iloc[i:i+batch_size]
                await self._save_historical_batch(batch)
                processed_records += len(batch)
                
                # Update progress
                progress = (processed_records / len(df)) * 100
                self.workflow_status[workflow_id]["progress"] = progress
            
            # Complete
            self.workflow_status[workflow_id]["status"] = "completed"
            self.workflow_status[workflow_id]["progress"] = 100
            self.workflow_status[workflow_id]["completed_at"] = datetime.utcnow()
            
            return {
                "status": "completed",
                "records_processed": processed_records,
                "validation_warnings": validation_result["warnings"],
                "processing_time": (datetime.utcnow() - self.workflow_status[workflow_id]["created_at"]).total_seconds()
            }
            
        except Exception as e:
            self.workflow_status[workflow_id]["status"] = "error"
            self.workflow_status[workflow_id]["error"] = str(e)
            raise
    
    async def _process_forecast_excel(self, workflow_id: str, file_path: Path) -> Dict[str, Any]:
        """Process forecast data Excel file."""
        try:
            # Update status
            self.workflow_status[workflow_id]["stages"].append({
                "stage": "reading_file",
                "status": "started",
                "timestamp": datetime.utcnow()
            })
            
            # Read Excel file
            df = pd.read_excel(file_path)
            
            # Validate forecast columns
            required_columns = ['date', 'service_id', 'group_id', 'forecast_calls', 'forecast_aht']
            missing_columns = [col for col in required_columns if col not in df.columns]
            
            if missing_columns:
                raise ValueError(f"Missing required columns: {missing_columns}")
            
            # Convert dates
            df['date'] = pd.to_datetime(df['date'])
            
            # Validate forecast data
            validation_result = self._validate_forecast_data(df)
            
            if validation_result["errors"]:
                self.workflow_status[workflow_id]["status"] = "validation_failed"
                return {
                    "status": "validation_failed",
                    "errors": validation_result["errors"]
                }
            
            # Process forecast data
            processed_records = await self._save_forecast_data(df)
            
            self.workflow_status[workflow_id]["status"] = "completed"
            self.workflow_status[workflow_id]["progress"] = 100
            
            return {
                "status": "completed",
                "records_processed": processed_records,
                "forecast_period": {
                    "start": df['date'].min().isoformat(),
                    "end": df['date'].max().isoformat()
                }
            }
            
        except Exception as e:
            self.workflow_status[workflow_id]["status"] = "error"
            self.workflow_status[workflow_id]["error"] = str(e)
            raise
    
    async def _process_personnel_excel(self, workflow_id: str, file_path: Path) -> Dict[str, Any]:
        """Process personnel data Excel file."""
        try:
            # Read Excel file
            df = pd.read_excel(file_path)
            
            # Validate personnel columns
            required_columns = ['agent_id', 'name', 'group_id', 'service_id']
            missing_columns = [col for col in required_columns if col not in df.columns]
            
            if missing_columns:
                raise ValueError(f"Missing required columns: {missing_columns}")
            
            # Process personnel data
            processed_records = await self._save_personnel_data(df)
            
            self.workflow_status[workflow_id]["status"] = "completed"
            self.workflow_status[workflow_id]["progress"] = 100
            
            return {
                "status": "completed",
                "records_processed": processed_records
            }
            
        except Exception as e:
            self.workflow_status[workflow_id]["status"] = "error"
            self.workflow_status[workflow_id]["error"] = str(e)
            raise
    
    def _validate_historical_data(self, df: pd.DataFrame) -> Dict[str, Any]:
        """Validate historical data quality."""
        errors = []
        warnings = []
        
        # Check for missing timestamps
        if df['timestamp'].isnull().any():
            errors.append("Missing timestamps found")
        
        # Check for negative values
        numeric_columns = ['calls_received', 'calls_handled']
        for col in numeric_columns:
            if (df[col] < 0).any():
                errors.append(f"Negative values found in {col}")
        
        # Check for impossible values
        if (df['calls_handled'] > df['calls_received']).any():
            errors.append("Calls handled cannot exceed calls received")
        
        # Check for data gaps
        df_sorted = df.sort_values('timestamp')
        time_gaps = df_sorted['timestamp'].diff()
        large_gaps = time_gaps[time_gaps > timedelta(hours=1)]
        
        if len(large_gaps) > 0:
            warnings.append(f"Found {len(large_gaps)} time gaps larger than 1 hour")
        
        return {
            "errors": errors,
            "warnings": warnings
        }
    
    def _validate_forecast_data(self, df: pd.DataFrame) -> Dict[str, Any]:
        """Validate forecast data quality."""
        errors = []
        warnings = []
        
        # Check for future dates only
        today = datetime.now().date()
        if (df['date'].dt.date <= today).any():
            warnings.append("Forecast contains historical dates")
        
        # Check for negative forecasts
        if (df['forecast_calls'] < 0).any():
            errors.append("Negative forecast values found")
        
        # Check for unrealistic values
        if (df['forecast_calls'] > 10000).any():
            warnings.append("Very high forecast values detected (>10,000 calls)")
        
        return {
            "errors": errors,
            "warnings": warnings
        }
    
    async def _save_historical_batch(self, batch: pd.DataFrame):
        """Save historical data batch to database."""
        # Implementation would save to ServiceGroupMetrics table
        # This is a placeholder for the actual database insert
        pass
    
    async def _save_forecast_data(self, df: pd.DataFrame) -> int:
        """Save forecast data to database."""
        # Implementation would save to forecast tables
        # This is a placeholder
        return len(df)
    
    async def _save_personnel_data(self, df: pd.DataFrame) -> int:
        """Save personnel data to database."""
        # Implementation would save to Agent/Group tables
        # This is a placeholder
        return len(df)
    
    async def process_historical_import(self, workflow_id: str) -> Dict[str, Any]:
        """
        Process historical data import asynchronously.
        
        Args:
            workflow_id: Workflow identifier
            
        Returns:
            Import processing result
        """
        try:
            if workflow_id not in self.workflow_status:
                raise ValueError(f"Workflow {workflow_id} not found")
            
            # This would be implemented to process large historical datasets
            # in background with progress tracking
            
            return {
                "status": "processing",
                "workflow_id": workflow_id,
                "message": "Historical import processing started",
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error processing historical import: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "timestamp": datetime.utcnow().isoformat()
            }
    
    async def validate_import(self, workflow_id: str) -> Dict[str, Any]:
        """
        Validate import data against business rules.
        
        Args:
            workflow_id: Workflow identifier
            
        Returns:
            Validation result
        """
        try:
            if workflow_id not in self.workflow_status:
                raise ValueError(f"Workflow {workflow_id} not found")
            
            workflow = self.workflow_status[workflow_id]
            
            # Business rule validation
            validation_result = validate_business_rules(workflow)
            
            return {
                "status": "success",
                "workflow_id": workflow_id,
                "validation_result": validation_result,
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error validating import: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "timestamp": datetime.utcnow().isoformat()
            }
    
    async def save_import(self, workflow_id: str) -> Dict[str, Any]:
        """
        Save validated import data with transactional persistence.
        
        Args:
            workflow_id: Workflow identifier
            
        Returns:
            Save result
        """
        try:
            if workflow_id not in self.workflow_status:
                raise ValueError(f"Workflow {workflow_id} not found")
            
            workflow = self.workflow_status[workflow_id]
            
            if workflow["status"] != "completed":
                raise ValueError(f"Workflow {workflow_id} not ready for saving")
            
            # Transactional save
            try:
                self.db.begin()
                
                # Save logic would go here
                # This is a placeholder for actual database operations
                
                self.db.commit()
                
                workflow["status"] = "saved"
                workflow["saved_at"] = datetime.utcnow()
                
                return {
                    "status": "success",
                    "workflow_id": workflow_id,
                    "message": "Import data saved successfully",
                    "timestamp": datetime.utcnow().isoformat()
                }
                
            except Exception as e:
                self.db.rollback()
                raise
            
        except Exception as e:
            logger.error(f"Error saving import: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "timestamp": datetime.utcnow().isoformat()
            }
    
    async def get_workflow_status(self, workflow_id: str) -> Dict[str, Any]:
        """
        Get workflow progress tracking status.
        
        Args:
            workflow_id: Workflow identifier
            
        Returns:
            Workflow status
        """
        try:
            if workflow_id not in self.workflow_status:
                return {
                    "status": "not_found",
                    "message": f"Workflow {workflow_id} not found",
                    "timestamp": datetime.utcnow().isoformat()
                }
            
            workflow = self.workflow_status[workflow_id]
            
            return {
                "status": "success",
                "data": {
                    "workflow_id": workflow_id,
                    "status": workflow["status"],
                    "progress": workflow["progress"],
                    "filename": workflow["filename"],
                    "upload_type": workflow["upload_type"],
                    "created_at": workflow["created_at"].isoformat(),
                    "stages": workflow["stages"],
                    "errors": workflow.get("errors", []),
                    "completed_at": workflow.get("completed_at", {}).isoformat() if workflow.get("completed_at") else None
                },
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error getting workflow status: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "timestamp": datetime.utcnow().isoformat()
            }