"""
Forecasting Import API - Task 30
Real PostgreSQL implementation for importing forecast data from various formats
"""

from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from typing import Optional, Dict, List, Any
from datetime import datetime, date
import psycopg2
from psycopg2.extras import RealDictCursor, execute_values
import os
import csv
import json
import io
import uuid
from xml.etree import ElementTree as ET

router = APIRouter()

def get_db_connection():
    """Get database connection"""
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        database=os.getenv('DB_NAME', 'wfm_enterprise'),
        user=os.getenv('DB_USER', 'postgres'),
        password=os.getenv('DB_PASSWORD', 'postgres'),
        port=os.getenv('DB_PORT', '5432')
    )

@router.post("/api/v1/forecasting/import")
async def import_forecasting_data(
    file: UploadFile = File(..., description="File containing forecast data"),
    file_format: str = Form(..., description="File format: csv, json, xml"),
    import_mode: str = Form("append", description="Import mode: append, replace, update"),
    service_id: Optional[int] = Form(None, description="Default service ID for imported data"),
    validate_only: bool = Form(False, description="Only validate data without importing"),
    date_format: str = Form("%Y-%m-%d", description="Date format for parsing dates"),
    mapping_config: Optional[str] = Form(None, description="JSON string for column mapping")
):
    """
    Import forecast data from uploaded file in various formats
    
    Supported formats:
    - CSV: Comma-separated values
    - JSON: JavaScript Object Notation  
    - XML: Extensible Markup Language
    
    Import modes:
    - append: Add new records
    - replace: Delete existing data and import new
    - update: Update existing records, add new ones
    
    Returns import statistics and validation results
    """
    
    try:
        # Read file content
        file_content = await file.read()
        
        # Parse data based on format
        if file_format.lower() == "csv":
            data = parse_csv_data(file_content, date_format)
        elif file_format.lower() == "json":
            data = parse_json_data(file_content, date_format)
        elif file_format.lower() == "xml":
            data = parse_xml_data(file_content, date_format)
        else:
            raise HTTPException(status_code=400, detail=f"Unsupported file format: {file_format}")
        
        # Apply column mapping if provided
        if mapping_config:
            try:
                mapping = json.loads(mapping_config)
                data = apply_column_mapping(data, mapping)
            except json.JSONDecodeError:
                raise HTTPException(status_code=400, detail="Invalid mapping configuration JSON")
        
        # Validate data
        validation_result = validate_forecast_data(data, service_id)
        
        if not validation_result["is_valid"]:
            return {
                "status": "validation_failed",
                "validation_result": validation_result,
                "records_processed": 0
            }
        
        # If validation only, return validation results
        if validate_only:
            return {
                "status": "validation_success",
                "validation_result": validation_result,
                "records_to_import": len(data),
                "sample_data": data[:5] if len(data) > 5 else data
            }
        
        # Import data to database
        import_result = import_data_to_database(data, import_mode, service_id)
        
        return {
            "status": "import_success",
            "import_result": import_result,
            "validation_result": validation_result,
            "file_info": {
                "filename": file.filename,
                "file_size": len(file_content),
                "format": file_format,
                "import_mode": import_mode
            }
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Import error: {str(e)}")

def parse_csv_data(file_content: bytes, date_format: str) -> List[Dict]:
    """Parse CSV file content into list of dictionaries"""
    
    try:
        content_str = file_content.decode('utf-8')
        csv_reader = csv.DictReader(io.StringIO(content_str))
        
        data = []
        for row in csv_reader:
            # Clean and process row data
            processed_row = {}
            for key, value in row.items():
                if value.strip():  # Skip empty values
                    processed_row[key.strip()] = value.strip()
            
            if processed_row:  # Only add non-empty rows
                data.append(processed_row)
        
        return data
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"CSV parsing error: {str(e)}")

def parse_json_data(file_content: bytes, date_format: str) -> List[Dict]:
    """Parse JSON file content into list of dictionaries"""
    
    try:
        content_str = file_content.decode('utf-8')
        json_data = json.loads(content_str)
        
        # Handle different JSON structures
        if isinstance(json_data, list):
            return json_data
        elif isinstance(json_data, dict):
            # Look for common array keys
            for key in ['forecast_data', 'data', 'forecasts', 'records']:
                if key in json_data and isinstance(json_data[key], list):
                    return json_data[key]
            # If no array found, treat the dict as single record
            return [json_data]
        else:
            raise HTTPException(status_code=400, detail="Invalid JSON structure - expected array or object")
            
    except json.JSONDecodeError as e:
        raise HTTPException(status_code=400, detail=f"JSON parsing error: {str(e)}")

def parse_xml_data(file_content: bytes, date_format: str) -> List[Dict]:
    """Parse XML file content into list of dictionaries"""
    
    try:
        content_str = file_content.decode('utf-8')
        root = ET.fromstring(content_str)
        
        data = []
        
        # Look for forecast records in XML
        for forecast_element in root.findall('.//forecast'):
            record = {}
            for child in forecast_element:
                record[child.tag] = child.text
            if record:
                data.append(record)
        
        # If no forecast elements found, try other common structures
        if not data:
            for record_element in root.findall('.//record'):
                record = {}
                for child in record_element:
                    record[child.tag] = child.text
                if record:
                    data.append(record)
        
        return data
        
    except ET.ParseError as e:
        raise HTTPException(status_code=400, detail=f"XML parsing error: {str(e)}")

def apply_column_mapping(data: List[Dict], mapping: Dict[str, str]) -> List[Dict]:
    """Apply column mapping to transform data field names"""
    
    mapped_data = []
    for row in data:
        mapped_row = {}
        for source_col, target_col in mapping.items():
            if source_col in row:
                mapped_row[target_col] = row[source_col]
        
        # Keep unmapped columns as-is
        for col, value in row.items():
            if col not in mapping and col not in mapped_row:
                mapped_row[col] = value
        
        mapped_data.append(mapped_row)
    
    return mapped_data

def validate_forecast_data(data: List[Dict], default_service_id: Optional[int]) -> Dict:
    """Validate forecast data for database import"""
    
    validation_errors = []
    warnings = []
    valid_records = 0
    
    required_fields = ['forecast_date', 'call_volume']
    
    for i, record in enumerate(data):
        record_errors = []
        
        # Check required fields
        for field in required_fields:
            if field not in record or not record[field]:
                record_errors.append(f"Missing required field: {field}")
        
        # Validate data types and values
        if 'forecast_date' in record:
            try:
                # Try to parse date
                if isinstance(record['forecast_date'], str):
                    datetime.strptime(record['forecast_date'], '%Y-%m-%d')
            except ValueError:
                record_errors.append(f"Invalid date format: {record['forecast_date']}")
        
        if 'call_volume' in record:
            try:
                call_volume = int(record['call_volume'])
                if call_volume < 0:
                    record_errors.append("Call volume cannot be negative")
            except ValueError:
                record_errors.append(f"Invalid call volume: {record['call_volume']}")
        
        if 'average_handle_time' in record:
            try:
                aht = int(record['average_handle_time'])
                if aht <= 0:
                    record_errors.append("Average handle time must be positive")
            except ValueError:
                record_errors.append(f"Invalid average handle time: {record['average_handle_time']}")
        
        if 'service_level_target' in record:
            try:
                slt = float(record['service_level_target'])
                if slt < 0 or slt > 100:
                    warnings.append(f"Row {i+1}: Service level target outside typical range (0-100%)")
            except ValueError:
                record_errors.append(f"Invalid service level target: {record['service_level_target']}")
        
        # Check service_id
        if 'service_id' not in record and not default_service_id:
            record_errors.append("Service ID not provided and no default specified")
        
        if record_errors:
            validation_errors.append({
                "row": i + 1,
                "errors": record_errors,
                "data": record
            })
        else:
            valid_records += 1
    
    return {
        "is_valid": len(validation_errors) == 0,
        "total_records": len(data),
        "valid_records": valid_records,
        "invalid_records": len(validation_errors),
        "errors": validation_errors,
        "warnings": warnings
    }

def import_data_to_database(data: List[Dict], import_mode: str, default_service_id: Optional[int]) -> Dict:
    """Import validated data into the database"""
    
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Start transaction
        cur.execute("BEGIN")
        
        # Handle import mode
        if import_mode == "replace":
            # Delete existing data (be careful with this in production!)
            if default_service_id:
                cur.execute("DELETE FROM forecast_data WHERE service_id = %s", [default_service_id])
            else:
                # This is dangerous - only for demo purposes
                cur.execute("DELETE FROM forecast_data WHERE created_at::date = CURRENT_DATE")
        
        # Prepare data for insertion
        insert_data = []
        for record in data:
            # Set default values
            service_id = record.get('service_id', default_service_id)
            forecast_date = record.get('forecast_date')
            interval_start = record.get('interval_start', '09:00:00')
            call_volume = int(record.get('call_volume', 0))
            average_handle_time = int(record.get('average_handle_time', 300))  # Default 5 minutes
            service_level_target = float(record.get('service_level_target', 80.0)) if record.get('service_level_target') else None
            
            insert_data.append((
                service_id,
                forecast_date,
                interval_start,
                call_volume,
                average_handle_time,
                service_level_target,
                datetime.now()
            ))
        
        # Insert data
        if import_mode == "update":
            # Handle updates - for simplicity, we'll do upsert
            insert_query = """
                INSERT INTO forecast_data 
                (service_id, forecast_date, interval_start, call_volume, average_handle_time, service_level_target, created_at)
                VALUES %s
                ON CONFLICT (service_id, forecast_date, interval_start) 
                DO UPDATE SET 
                    call_volume = EXCLUDED.call_volume,
                    average_handle_time = EXCLUDED.average_handle_time,
                    service_level_target = EXCLUDED.service_level_target,
                    created_at = EXCLUDED.created_at
            """
        else:
            # Regular insert
            insert_query = """
                INSERT INTO forecast_data 
                (service_id, forecast_date, interval_start, call_volume, average_handle_time, service_level_target, created_at)
                VALUES %s
            """
        
        # Execute bulk insert
        execute_values(cur, insert_query, insert_data, template=None, page_size=100)
        
        # Get import statistics
        cur.execute("SELECT COUNT(*) as count FROM forecast_data WHERE created_at > %s", [datetime.now() - datetime.timedelta(minutes=1)])
        recent_count = cur.fetchone()['count']
        
        # Commit transaction
        cur.execute("COMMIT")
        
        # Create import audit record
        audit_id = str(uuid.uuid4())
        audit_query = """
            INSERT INTO import_audit 
            (id, import_type, records_imported, import_mode, imported_at, status)
            VALUES (%s, %s, %s, %s, %s, %s)
        """
        
        # Create audit table if it doesn't exist
        create_audit_table = """
            CREATE TABLE IF NOT EXISTS import_audit (
                id UUID PRIMARY KEY,
                import_type VARCHAR(50) NOT NULL,
                records_imported INTEGER NOT NULL,
                import_mode VARCHAR(20) NOT NULL,
                imported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                status VARCHAR(20) DEFAULT 'success',
                details JSONB
            )
        """
        
        cur.execute(create_audit_table)
        cur.execute(audit_query, [
            audit_id,
            'forecast_data',
            len(insert_data),
            import_mode,
            datetime.now(),
            'success'
        ])
        
        cur.close()
        conn.close()
        
        return {
            "records_imported": len(insert_data),
            "import_mode": import_mode,
            "audit_id": audit_id,
            "database_status": "success",
            "import_timestamp": datetime.now().isoformat()
        }
        
    except psycopg2.Error as e:
        cur.execute("ROLLBACK")
        cur.close()
        conn.close()
        raise HTTPException(status_code=500, detail=f"Database import error: {str(e)}")
    except Exception as e:
        cur.execute("ROLLBACK")
        cur.close()
        conn.close()
        raise HTTPException(status_code=500, detail=f"Import processing error: {str(e)}")