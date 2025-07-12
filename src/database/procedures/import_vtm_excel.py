#!/usr/bin/env python3
"""
Project ВТМ Excel Import Script
Purpose: Load VTM data from Argus Excel files into PostgreSQL staging tables
"""

import pandas as pd
import psycopg2
from psycopg2.extras import execute_values
import os
import sys
from datetime import datetime
import uuid
import logging
from typing import Dict, List, Tuple, Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class VTMExcelImporter:
    """Import VTM data from Excel files to PostgreSQL"""
    
    def __init__(self, db_config: Dict[str, str]):
        """Initialize with database configuration"""
        self.db_config = db_config
        self.conn = None
        self.cur = None
        
    def connect(self):
        """Connect to PostgreSQL database"""
        try:
            self.conn = psycopg2.connect(**self.db_config)
            self.cur = self.conn.cursor()
            logger.info("Connected to database successfully")
        except Exception as e:
            logger.error(f"Database connection failed: {e}")
            raise
            
    def disconnect(self):
        """Close database connection"""
        if self.cur:
            self.cur.close()
        if self.conn:
            self.conn.close()
        logger.info("Disconnected from database")
        
    def read_excel_file(self, file_path: str) -> pd.DataFrame:
        """Read VTM Excel file and return DataFrame"""
        try:
            # Read Excel file, skip first 2 rows to get to headers
            df = pd.read_excel(file_path, header=2)
            
            # Standardize column names
            column_mapping = {
                'Период': 'period_text',
                'Проект': 'project_name',  # May not exist in all files
                'CDO': 'cdo',
                'HC': 'hc',
                'SHC': 'shc',
                'SHC (-AC5)': 'shc_minus_ac5',
                'HC (SL)': 'hc_sl',
                'SL': 'sl',
                'SL on HC': 'sl_on_hc',
                'AC': 'ac',
                'AC(5)': 'ac5',
                'LCR': 'lcr',
                'FC': 'fc',
                'TT': 'tt',
                'OTT': 'ott',
                'HT': 'ht',
                'THT': 'tht',
                'AHT': 'aht',
                'ACW': 'acw',
                'THT (+ACW)': 'tht_plus_acw',
                'AHT (+ACW)': 'aht_plus_acw',
                'TWT (HC)': 'twt_hc',
                'AWT (HC)': 'awt_hc',
                'MWT (HC)': 'mwt_hc',
                'TWT (AC)': 'twt_ac',
                'AWT (AC)': 'awt_ac',
                'MWT (AC)': 'mwt_ac'
            }
            
            # Rename columns that exist
            df.rename(columns={k: v for k, v in column_mapping.items() if k in df.columns}, inplace=True)
            
            # Add file metadata
            df['file_name'] = os.path.basename(file_path)
            
            # Determine interval type from filename
            if '15м' in file_path:
                df['interval_type'] = '15m'
            elif '30м' in file_path:
                df['interval_type'] = '30m'
            elif '1ч' in file_path:
                df['interval_type'] = '1h'
            else:
                df['interval_type'] = 'unknown'
                
            logger.info(f"Read {len(df)} rows from {file_path}")
            return df
            
        except Exception as e:
            logger.error(f"Error reading Excel file {file_path}: {e}")
            raise
            
    def prepare_data(self, df: pd.DataFrame, batch_id: str) -> List[Tuple]:
        """Prepare DataFrame for database insertion"""
        records = []
        
        for _, row in df.iterrows():
            # Handle NaN values
            def clean_value(val, default=None):
                if pd.isna(val):
                    return default
                return val
            
            record = (
                # File metadata
                row.get('file_name', ''),
                datetime.now(),
                row.get('interval_type', ''),
                
                # Data columns
                str(row.get('period_text', '')),
                None,  # period_timestamp - will be parsed in SQL
                row.get('project_name', None),
                row.get('queue_code', None),  # For future queue-specific imports
                
                # Metrics
                int(clean_value(row.get('cdo', 0), 0)),
                int(clean_value(row.get('hc', 0), 0)),
                float(clean_value(row.get('shc', 0), 0)),
                float(clean_value(row.get('shc_minus_ac5', 0), 0)),
                int(clean_value(row.get('hc_sl', 0), 0)),
                float(clean_value(row.get('sl', 0), 0)),
                float(clean_value(row.get('sl_on_hc', 0), 0)),
                int(clean_value(row.get('ac', 0), 0)),
                int(clean_value(row.get('ac5', 0), 0)),
                float(clean_value(row.get('lcr', 0), 0)),
                int(clean_value(row.get('fc', 0), 0)),
                int(clean_value(row.get('tt', 0), 0)),
                int(clean_value(row.get('ott', 0), 0)),
                int(clean_value(row.get('ht', 0), 0)),
                int(clean_value(row.get('tht', 0), 0)),
                int(clean_value(row.get('aht', 0), 0)),
                int(clean_value(row.get('acw', 0), 0)),
                int(clean_value(row.get('tht_plus_acw', 0), 0)),
                int(clean_value(row.get('aht_plus_acw', 0), 0)),
                int(clean_value(row.get('twt_hc', 0), 0)),
                float(clean_value(row.get('awt_hc', 0), 0)),
                int(clean_value(row.get('mwt_hc', 0), 0)),
                int(clean_value(row.get('twt_ac', 0), 0)),
                float(clean_value(row.get('awt_ac'))),  # Can be NULL
                int(clean_value(row.get('mwt_ac', 0), 0)),
                
                # Processing metadata
                batch_id,
                False,  # processed
                None,   # processed_at
                None    # error_message
            )
            
            records.append(record)
            
        return records
        
    def import_to_staging(self, records: List[Tuple]) -> int:
        """Import records to staging table"""
        insert_query = """
            INSERT INTO stg_vtm_metrics (
                file_name, file_date, interval_type,
                period_text, period_timestamp, project_name, queue_code,
                cdo, hc, shc, shc_minus_ac5, hc_sl, sl, sl_on_hc,
                ac, ac5, lcr, fc, tt, ott, ht, tht, aht, acw,
                tht_plus_acw, aht_plus_acw, twt_hc, awt_hc, mwt_hc,
                twt_ac, awt_ac, mwt_ac,
                import_batch_id, processed, processed_at, error_message
            ) VALUES %s
            ON CONFLICT (period_timestamp, queue_code, interval_type) 
            DO UPDATE SET
                cdo = EXCLUDED.cdo,
                hc = EXCLUDED.hc,
                shc = EXCLUDED.shc,
                sl = EXCLUDED.sl,
                aht = EXCLUDED.aht,
                file_date = EXCLUDED.file_date,
                import_batch_id = EXCLUDED.import_batch_id
        """
        
        try:
            execute_values(self.cur, insert_query, records)
            self.conn.commit()
            logger.info(f"Imported {len(records)} records to staging table")
            return len(records)
        except Exception as e:
            self.conn.rollback()
            logger.error(f"Error importing to staging: {e}")
            raise
            
    def process_batch(self, batch_id: str) -> Dict[str, int]:
        """Process imported batch"""
        try:
            # Call SQL function to parse timestamps and validate data
            self.cur.execute(
                "SELECT * FROM import_vtm_excel_data(%s, %s, %s)",
                ('', '', False)  # Parameters handled internally by batch_id
            )
            result = self.cur.fetchone()
            
            # Process metrics batch
            self.cur.execute(
                "SELECT * FROM process_vtm_metrics_batch(%s, CURRENT_DATE)",
                (batch_id,)
            )
            metrics_result = self.cur.fetchone()
            
            self.conn.commit()
            
            return {
                'rows_imported': result[0] if result else 0,
                'rows_failed': result[1] if result else 0,
                'metrics_processed': metrics_result[0] if metrics_result else 0,
                'hourly_aggregates': metrics_result[1] if metrics_result else 0
            }
            
        except Exception as e:
            self.conn.rollback()
            logger.error(f"Error processing batch: {e}")
            raise
            
    def import_vtm_files(self, directory: str, file_pattern: str = 'ВТМ*.xlsx') -> Dict[str, any]:
        """Import all VTM Excel files from directory"""
        import glob
        
        batch_id = str(uuid.uuid4())
        results = {
            'batch_id': batch_id,
            'files_processed': 0,
            'total_rows': 0,
            'errors': []
        }
        
        # Find all VTM files
        pattern = os.path.join(directory, '**', f'*{file_pattern}*')
        files = glob.glob(pattern, recursive=True)
        
        logger.info(f"Found {len(files)} VTM files to process")
        
        for file_path in files:
            try:
                # Read Excel file
                df = self.read_excel_file(file_path)
                
                # Prepare data
                records = self.prepare_data(df, batch_id)
                
                # Import to staging
                rows_imported = self.import_to_staging(records)
                
                results['files_processed'] += 1
                results['total_rows'] += rows_imported
                
            except Exception as e:
                error_msg = f"Error processing {file_path}: {e}"
                logger.error(error_msg)
                results['errors'].append(error_msg)
                
        # Process the batch
        if results['total_rows'] > 0:
            try:
                process_results = self.process_batch(batch_id)
                results.update(process_results)
            except Exception as e:
                results['errors'].append(f"Batch processing error: {e}")
                
        return results


def main():
    """Main execution function"""
    # Database configuration
    db_config = {
        'host': os.getenv('DB_HOST', 'localhost'),
        'port': os.getenv('DB_PORT', '5432'),
        'database': os.getenv('DB_NAME', 'wfm_system'),
        'user': os.getenv('DB_USER', 'postgres'),
        'password': os.getenv('DB_PASSWORD', '')
    }
    
    # Directory containing Excel files
    excel_dir = os.getenv('EXCEL_DIR', 
        '/Users/m/Documents/wfm/WFM_Enterprise/main/agents/L-1A-Data-Analysis/data/excel-files')
    
    # Create importer instance
    importer = VTMExcelImporter(db_config)
    
    try:
        # Connect to database
        importer.connect()
        
        # Import VTM files
        results = importer.import_vtm_files(excel_dir, 'ВТМ')
        
        # Print results
        print("\nImport Results:")
        print(f"Batch ID: {results['batch_id']}")
        print(f"Files processed: {results['files_processed']}")
        print(f"Total rows imported: {results['total_rows']}")
        print(f"Metrics processed: {results.get('metrics_processed', 0)}")
        print(f"Hourly aggregates created: {results.get('hourly_aggregates', 0)}")
        
        if results['errors']:
            print("\nErrors encountered:")
            for error in results['errors']:
                print(f"  - {error}")
                
    except Exception as e:
        logger.error(f"Import failed: {e}")
        sys.exit(1)
        
    finally:
        # Disconnect from database
        importer.disconnect()


if __name__ == "__main__":
    main()