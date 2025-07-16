"""
Enterprise Integration API - Task 74: Data Transformation Engine
POST /api/v1/integration/data/transform

Features:
- ETL processing with mapping and validation
- Field mapping and data format conversion
- Real-time and batch transformation
- Database: transformation_rules, field_mappings, data_formats
"""

from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks, Query
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, validator
from typing import List, Optional, Dict, Any, Union
from datetime import datetime, timedelta
from enum import Enum
import asyncpg
import asyncio
import json
import uuid
import re
import hashlib
from decimal import Decimal
import pandas as pd
import io

# Database connection
from ...core.database import get_db_connection

security = HTTPBearer()

router = APIRouter(prefix="/api/v1/integration/data", tags=["Enterprise Integration - Data Transformation"])

class TransformationType(str, Enum):
    ETL = "etl"
    FIELD_MAPPING = "field_mapping"
    FORMAT_CONVERSION = "format_conversion"
    DATA_VALIDATION = "data_validation"
    AGGREGATION = "aggregation"
    ENRICHMENT = "enrichment"

class DataFormat(str, Enum):
    JSON = "json"
    XML = "xml"
    CSV = "csv"
    EXCEL = "excel"
    FIXED_WIDTH = "fixed_width"
    DELIMITED = "delimited"
    ARGUS_FORMAT = "argus_format"
    WFM_STANDARD = "wfm_standard"

class ValidationRule(str, Enum):
    REQUIRED = "required"
    NUMERIC = "numeric"
    DATE = "date"
    EMAIL = "email"
    REGEX = "regex"
    RANGE = "range"
    ENUM = "enum"
    UNIQUE = "unique"

class TransformationRequest(BaseModel):
    """Data transformation request"""
    transformation_name: str
    source_system_id: Optional[str] = None
    target_system_id: Optional[str] = None
    transformation_type: TransformationType
    source_format: DataFormat
    target_format: DataFormat
    source_data: Union[str, Dict[str, Any], List[Dict[str, Any]]]
    field_mappings: List[Dict[str, Any]]
    validation_rules: Optional[List[Dict[str, Any]]] = []
    transformation_rules: Optional[List[Dict[str, Any]]] = []
    batch_size: Optional[int] = 1000
    preserve_source: bool = True
    
    @validator('field_mappings')
    def validate_field_mappings(cls, v):
        required_keys = {'source_field', 'target_field'}
        for mapping in v:
            if not required_keys.issubset(mapping.keys()):
                raise ValueError('Each field mapping must have source_field and target_field')
        return v

class TransformationResponse(BaseModel):
    """Data transformation response"""
    transformation_id: str
    status: str
    records_processed: int
    records_successful: int
    records_failed: int
    transformed_data: Optional[Union[str, List[Dict[str, Any]]]] = None
    validation_errors: List[Dict[str, Any]]
    transformation_summary: Dict[str, Any]
    execution_time_ms: int
    created_at: datetime

class FieldMapping(BaseModel):
    """Field mapping configuration"""
    mapping_id: str
    rule_id: str
    source_field: str
    target_field: str
    transformation_function: Optional[str] = None
    default_value: Optional[Any] = None
    validation_rules: List[str]
    active: bool
    created_at: datetime

class TransformationRule(BaseModel):
    """Transformation rule configuration"""
    rule_id: str
    rule_name: str
    description: Optional[str] = None
    transformation_type: TransformationType
    source_format: DataFormat
    target_format: DataFormat
    field_mappings: List[Dict[str, Any]]
    validation_rules: List[Dict[str, Any]]
    transformation_logic: Dict[str, Any]
    active: bool
    created_by: str
    created_at: datetime
    updated_at: datetime

async def verify_enterprise_auth(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    """Verify enterprise authentication"""
    token = credentials.credentials
    if not token or len(token) < 20:
        raise HTTPException(status_code=401, detail="Invalid authentication token")
    return token

def apply_field_transformation(value: Any, transformation_function: str, params: Dict[str, Any] = None) -> Any:
    """Apply transformation function to field value"""
    if value is None:
        return None
    
    params = params or {}
    
    try:
        if transformation_function == "uppercase":
            return str(value).upper()
        elif transformation_function == "lowercase":
            return str(value).lower()
        elif transformation_function == "trim":
            return str(value).strip()
        elif transformation_function == "date_format":
            from datetime import datetime
            if isinstance(value, str):
                # Parse string date
                source_format = params.get('source_format', '%Y-%m-%d')
                target_format = params.get('target_format', '%Y-%m-%d %H:%M:%S')
                dt = datetime.strptime(value, source_format)
                return dt.strftime(target_format)
            return value
        elif transformation_function == "numeric":
            return float(value) if '.' in str(value) else int(value)
        elif transformation_function == "concatenate":
            separator = params.get('separator', '')
            fields = params.get('fields', [])
            return separator.join(str(f) for f in fields if f is not None)
        elif transformation_function == "substring":
            start = params.get('start', 0)
            length = params.get('length')
            if length:
                return str(value)[start:start+length]
            return str(value)[start:]
        elif transformation_function == "replace":
            old_value = params.get('old', '')
            new_value = params.get('new', '')
            return str(value).replace(old_value, new_value)
        elif transformation_function == "regex_extract":
            pattern = params.get('pattern', '')
            group = params.get('group', 0)
            match = re.search(pattern, str(value))
            return match.group(group) if match else None
        elif transformation_function == "argus_time_format":
            # Convert Argus time format to WFM standard
            if isinstance(value, str) and ':' in value:
                # Assume HH:MM format, convert to minutes
                hours, minutes = map(int, value.split(':'))
                return hours * 60 + minutes
            return value
        else:
            return value
    except Exception:
        return value

def validate_field_value(value: Any, validation_rules: List[Dict[str, Any]]) -> List[str]:
    """Validate field value against rules"""
    errors = []
    
    for rule in validation_rules:
        rule_type = rule.get('type')
        
        if rule_type == 'required' and (value is None or value == ''):
            errors.append("Field is required")
        elif rule_type == 'numeric' and value is not None:
            try:
                float(value)
            except (ValueError, TypeError):
                errors.append("Field must be numeric")
        elif rule_type == 'date' and value is not None:
            try:
                from datetime import datetime
                format_str = rule.get('format', '%Y-%m-%d')
                datetime.strptime(str(value), format_str)
            except (ValueError, TypeError):
                errors.append(f"Field must be valid date in format {rule.get('format', '%Y-%m-%d')}")
        elif rule_type == 'email' and value is not None:
            email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
            if not re.match(email_pattern, str(value)):
                errors.append("Field must be valid email")
        elif rule_type == 'regex' and value is not None:
            pattern = rule.get('pattern', '')
            if not re.match(pattern, str(value)):
                errors.append(f"Field must match pattern: {pattern}")
        elif rule_type == 'range' and value is not None:
            try:
                num_value = float(value)
                min_val = rule.get('min')
                max_val = rule.get('max')
                if min_val is not None and num_value < min_val:
                    errors.append(f"Field must be >= {min_val}")
                if max_val is not None and num_value > max_val:
                    errors.append(f"Field must be <= {max_val}")
            except (ValueError, TypeError):
                errors.append("Field must be numeric for range validation")
        elif rule_type == 'enum' and value is not None:
            allowed_values = rule.get('values', [])
            if value not in allowed_values:
                errors.append(f"Field must be one of: {', '.join(map(str, allowed_values))}")
    
    return errors

async def parse_source_data(source_data: Union[str, Dict, List], source_format: DataFormat) -> List[Dict[str, Any]]:
    """Parse source data based on format"""
    
    if source_format == DataFormat.JSON:
        if isinstance(source_data, str):
            data = json.loads(source_data)
        else:
            data = source_data
        
        if isinstance(data, dict):
            return [data]
        elif isinstance(data, list):
            return data
        else:
            raise ValueError("JSON data must be object or array")
    
    elif source_format == DataFormat.CSV:
        if isinstance(source_data, str):
            # Parse CSV string
            import csv
            import io
            csv_reader = csv.DictReader(io.StringIO(source_data))
            return list(csv_reader)
        else:
            raise ValueError("CSV data must be string")
    
    elif source_format == DataFormat.ARGUS_FORMAT:
        # Custom Argus format parsing
        if isinstance(source_data, str):
            # Parse Argus-specific format (simplified)
            lines = source_data.strip().split('\n')
            if len(lines) < 2:
                raise ValueError("Argus format must have header and data rows")
            
            headers = lines[0].split('\t')
            data = []
            for line in lines[1:]:
                values = line.split('\t')
                if len(values) == len(headers):
                    data.append(dict(zip(headers, values)))
            return data
        else:
            raise ValueError("Argus format data must be string")
    
    else:
        # Default: assume it's already parsed
        if isinstance(source_data, dict):
            return [source_data]
        elif isinstance(source_data, list):
            return source_data
        else:
            return [{"data": source_data}]

async def format_output_data(data: List[Dict[str, Any]], target_format: DataFormat) -> Union[str, List[Dict[str, Any]]]:
    """Format output data according to target format"""
    
    if target_format == DataFormat.JSON:
        return data
    
    elif target_format == DataFormat.CSV:
        if not data:
            return ""
        
        import csv
        import io
        
        output = io.StringIO()
        if data:
            writer = csv.DictWriter(output, fieldnames=data[0].keys())
            writer.writeheader()
            for row in data:
                writer.writerow(row)
        
        return output.getvalue()
    
    elif target_format == DataFormat.WFM_STANDARD:
        # Convert to WFM standard format
        formatted_data = []
        for row in data:
            formatted_row = {}
            for key, value in row.items():
                # Apply WFM standard naming conventions
                wfm_key = key.lower().replace(' ', '_').replace('-', '_')
                formatted_row[wfm_key] = value
            formatted_data.append(formatted_row)
        return formatted_data
    
    else:
        return data

async def transform_data_records(records: List[Dict[str, Any]], field_mappings: List[Dict[str, Any]], 
                               validation_rules: List[Dict[str, Any]], 
                               transformation_rules: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Transform data records using field mappings and rules"""
    
    transformed_records = []
    validation_errors = []
    processing_stats = {
        "records_processed": len(records),
        "records_successful": 0,
        "records_failed": 0,
        "field_transformations": 0,
        "validation_failures": 0
    }
    
    for record_idx, record in enumerate(records):
        try:
            transformed_record = {}
            record_errors = []
            
            # Apply field mappings
            for mapping in field_mappings:
                source_field = mapping['source_field']
                target_field = mapping['target_field']
                transformation_func = mapping.get('transformation_function')
                default_value = mapping.get('default_value')
                
                # Get source value
                source_value = record.get(source_field, default_value)
                
                # Apply transformation
                if transformation_func:
                    try:
                        transformed_value = apply_field_transformation(
                            source_value, 
                            transformation_func, 
                            mapping.get('transformation_params', {})
                        )
                        processing_stats["field_transformations"] += 1
                    except Exception as e:
                        transformed_value = source_value
                        record_errors.append({
                            "field": target_field,
                            "error": f"Transformation failed: {str(e)}",
                            "value": source_value
                        })
                else:
                    transformed_value = source_value
                
                transformed_record[target_field] = transformed_value
                
                # Validate transformed value
                field_validation_rules = [
                    rule for rule in validation_rules 
                    if rule.get('field') == target_field
                ]
                
                if field_validation_rules:
                    field_errors = validate_field_value(transformed_value, field_validation_rules)
                    if field_errors:
                        processing_stats["validation_failures"] += len(field_errors)
                        for error in field_errors:
                            record_errors.append({
                                "field": target_field,
                                "error": error,
                                "value": transformed_value
                            })
            
            # Apply record-level transformation rules
            for rule in transformation_rules:
                rule_type = rule.get('type')
                if rule_type == 'calculated_field':
                    field_name = rule.get('field_name')
                    expression = rule.get('expression')
                    try:
                        # Simple expression evaluation (in production, use a proper expression engine)
                        calculated_value = eval(expression, {"__builtins__": {}}, transformed_record)
                        transformed_record[field_name] = calculated_value
                    except Exception as e:
                        record_errors.append({
                            "field": field_name,
                            "error": f"Calculation failed: {str(e)}",
                            "expression": expression
                        })
            
            if record_errors:
                validation_errors.append({
                    "record_index": record_idx,
                    "errors": record_errors,
                    "original_record": record
                })
                processing_stats["records_failed"] += 1
            else:
                transformed_records.append(transformed_record)
                processing_stats["records_successful"] += 1
                
        except Exception as e:
            validation_errors.append({
                "record_index": record_idx,
                "errors": [{"error": f"Record processing failed: {str(e)}"}],
                "original_record": record
            })
            processing_stats["records_failed"] += 1
    
    return {
        "transformed_records": transformed_records,
        "validation_errors": validation_errors,
        "processing_stats": processing_stats
    }

@router.post("/transform", response_model=TransformationResponse)
async def transform_data(
    transformation_request: TransformationRequest,
    background_tasks: BackgroundTasks,
    user_id: str = Depends(verify_enterprise_auth)
):
    """
    Transform data with comprehensive ETL processing
    
    - Field mapping and transformation
    - Data validation and enrichment
    - Format conversion and standardization
    - Real-time and batch processing
    """
    
    start_time = datetime.utcnow()
    transformation_id = str(uuid.uuid4())
    
    conn = await get_db_connection()
    try:
        # Parse source data
        source_records = await parse_source_data(
            transformation_request.source_data,
            transformation_request.source_format
        )
        
        # Transform data
        transformation_result = await transform_data_records(
            source_records,
            transformation_request.field_mappings,
            transformation_request.validation_rules or [],
            transformation_request.transformation_rules or []
        )
        
        # Format output
        transformed_data = await format_output_data(
            transformation_result["transformed_records"],
            transformation_request.target_format
        )
        
        # Calculate execution time
        end_time = datetime.utcnow()
        execution_time_ms = int((end_time - start_time).total_seconds() * 1000)
        
        # Store transformation record
        await conn.execute("""
            INSERT INTO transformation_logs (
                transformation_id, transformation_name, source_system_id, target_system_id,
                transformation_type, source_format, target_format, records_processed,
                records_successful, records_failed, execution_time_ms, validation_errors,
                transformation_summary, created_by, created_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
        """, 
        transformation_id, transformation_request.transformation_name,
        transformation_request.source_system_id, transformation_request.target_system_id,
        transformation_request.transformation_type.value,
        transformation_request.source_format.value, transformation_request.target_format.value,
        transformation_result["processing_stats"]["records_processed"],
        transformation_result["processing_stats"]["records_successful"],
        transformation_result["processing_stats"]["records_failed"],
        execution_time_ms, json.dumps(transformation_result["validation_errors"]),
        json.dumps(transformation_result["processing_stats"]),
        user_id, start_time)
        
        # Schedule cleanup if needed
        if not transformation_request.preserve_source:
            background_tasks.add_task(cleanup_transformation_data, transformation_id)
        
        return TransformationResponse(
            transformation_id=transformation_id,
            status="completed" if transformation_result["processing_stats"]["records_failed"] == 0 else "completed_with_errors",
            records_processed=transformation_result["processing_stats"]["records_processed"],
            records_successful=transformation_result["processing_stats"]["records_successful"],
            records_failed=transformation_result["processing_stats"]["records_failed"],
            transformed_data=transformed_data,
            validation_errors=transformation_result["validation_errors"],
            transformation_summary=transformation_result["processing_stats"],
            execution_time_ms=execution_time_ms,
            created_at=start_time
        )
        
    except Exception as e:
        # Log error
        await conn.execute("""
            INSERT INTO transformation_logs (
                transformation_id, transformation_name, transformation_type,
                source_format, target_format, records_processed, records_successful,
                records_failed, execution_time_ms, error_message, created_by, created_at
            ) VALUES ($1, $2, $3, $4, $5, 0, 0, 1, $6, $7, $8, $9)
        """, 
        transformation_id, transformation_request.transformation_name,
        transformation_request.transformation_type.value,
        transformation_request.source_format.value, transformation_request.target_format.value,
        int((datetime.utcnow() - start_time).total_seconds() * 1000),
        str(e), user_id, start_time)
        
        raise HTTPException(status_code=500, detail=f"Data transformation failed: {str(e)}")
    finally:
        await conn.close()

@router.get("/transform/rules", response_model=List[TransformationRule])
async def list_transformation_rules(
    transformation_type: Optional[TransformationType] = Query(None),
    source_format: Optional[DataFormat] = Query(None),
    target_format: Optional[DataFormat] = Query(None),
    user_id: str = Depends(verify_enterprise_auth)
):
    """List available transformation rules"""
    
    conn = await get_db_connection()
    try:
        query = """
            SELECT rule_id, rule_name, description, transformation_type, source_format,
                   target_format, field_mappings, validation_rules, transformation_logic,
                   active, created_by, created_at, updated_at
            FROM transformation_rules
            WHERE active = true
        """
        
        params = []
        param_count = 0
        
        if transformation_type:
            param_count += 1
            query += f" AND transformation_type = ${param_count}"
            params.append(transformation_type.value)
        
        if source_format:
            param_count += 1
            query += f" AND source_format = ${param_count}"
            params.append(source_format.value)
        
        if target_format:
            param_count += 1
            query += f" AND target_format = ${param_count}"
            params.append(target_format.value)
        
        query += " ORDER BY rule_name"
        
        rules = await conn.fetch(query, *params)
        
        return [
            TransformationRule(
                rule_id=rule['rule_id'],
                rule_name=rule['rule_name'],
                description=rule['description'],
                transformation_type=TransformationType(rule['transformation_type']),
                source_format=DataFormat(rule['source_format']),
                target_format=DataFormat(rule['target_format']),
                field_mappings=json.loads(rule['field_mappings']),
                validation_rules=json.loads(rule['validation_rules']),
                transformation_logic=json.loads(rule['transformation_logic']),
                active=rule['active'],
                created_by=rule['created_by'],
                created_at=rule['created_at'],
                updated_at=rule['updated_at']
            )
            for rule in rules
        ]
        
    finally:
        await conn.close()

@router.post("/transform/rules")
async def create_transformation_rule(
    rule_data: Dict[str, Any],
    user_id: str = Depends(verify_enterprise_auth)
):
    """Create new transformation rule"""
    
    conn = await get_db_connection()
    try:
        rule_id = str(uuid.uuid4())
        
        await conn.execute("""
            INSERT INTO transformation_rules (
                rule_id, rule_name, description, transformation_type, source_format,
                target_format, field_mappings, validation_rules, transformation_logic,
                active, created_by, created_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, true, $10, $11, $12)
        """, 
        rule_id, rule_data['rule_name'], rule_data.get('description'),
        rule_data['transformation_type'], rule_data['source_format'], rule_data['target_format'],
        json.dumps(rule_data['field_mappings']), json.dumps(rule_data.get('validation_rules', [])),
        json.dumps(rule_data.get('transformation_logic', {})),
        user_id, datetime.utcnow(), datetime.utcnow())
        
        return {"rule_id": rule_id, "message": "Transformation rule created successfully"}
        
    finally:
        await conn.close()

@router.get("/transform/history")
async def get_transformation_history(
    transformation_type: Optional[TransformationType] = Query(None),
    source_system_id: Optional[str] = Query(None),
    limit: int = Query(50, le=200),
    user_id: str = Depends(verify_enterprise_auth)
):
    """Get transformation execution history"""
    
    conn = await get_db_connection()
    try:
        query = """
            SELECT transformation_id, transformation_name, transformation_type,
                   source_format, target_format, records_processed, records_successful,
                   records_failed, execution_time_ms, created_at
            FROM transformation_logs
            WHERE created_by = $1
        """
        
        params = [user_id]
        param_count = 1
        
        if transformation_type:
            param_count += 1
            query += f" AND transformation_type = ${param_count}"
            params.append(transformation_type.value)
        
        if source_system_id:
            param_count += 1
            query += f" AND source_system_id = ${param_count}"
            params.append(source_system_id)
        
        param_count += 1
        query += f" ORDER BY created_at DESC LIMIT ${param_count}"
        params.append(limit)
        
        history = await conn.fetch(query, *params)
        
        return {
            "transformations": [
                {
                    "transformation_id": row['transformation_id'],
                    "transformation_name": row['transformation_name'],
                    "transformation_type": row['transformation_type'],
                    "source_format": row['source_format'],
                    "target_format": row['target_format'],
                    "records_processed": row['records_processed'],
                    "records_successful": row['records_successful'],
                    "records_failed": row['records_failed'],
                    "execution_time_ms": row['execution_time_ms'],
                    "created_at": row['created_at']
                }
                for row in history
            ]
        }
        
    finally:
        await conn.close()

async def cleanup_transformation_data(transformation_id: str):
    """Background task to cleanup transformation data"""
    # Implementation for cleanup logic
    pass