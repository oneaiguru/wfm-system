"""
Create backup and recovery management tables
"""

import asyncio
import asyncpg
from src.api.core.config import settings

async def create_backup_recovery_tables():
    """Create backup and recovery related tables"""
    
    # Parse DATABASE_URL for asyncpg
    db_url = settings.DATABASE_URL.replace("postgresql://", "").replace("postgresql+asyncpg://", "")
    if "@" in db_url:
        auth, rest = db_url.split("@", 1)
        user, password = auth.split(":", 1)
        host_db = rest.split("/", 1)
        if len(host_db) == 2:
            host, database = host_db
        else:
            host = host_db[0]
            database = "wfm_db"
    else:
        user = "postgres"
        password = "postgres"
        host = "localhost"
        database = "wfm_db"
    
    # Connect to database
    conn = await asyncpg.connect(
        user=user,
        password=password,
        host=host.split(":")[0],
        port=int(host.split(":")[1]) if ":" in host else 5432,
        database=database
    )
    
    try:
        # Create backup_configurations table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS backup_configurations (
                id VARCHAR(100) PRIMARY KEY,
                backup_type VARCHAR(50) NOT NULL,
                frequency VARCHAR(50) NOT NULL,
                retention_days INTEGER NOT NULL,
                storage_location VARCHAR(50) NOT NULL,
                compression_enabled BOOLEAN DEFAULT TRUE,
                encryption_enabled BOOLEAN DEFAULT TRUE,
                validation_enabled BOOLEAN DEFAULT TRUE,
                notification_emails JSONB DEFAULT '[]'::jsonb,
                active BOOLEAN DEFAULT TRUE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                created_by VARCHAR(100),
                updated_at TIMESTAMP,
                updated_by VARCHAR(100),
                metadata JSONB DEFAULT '{}'::jsonb
            )
        """)
        print("✓ Created backup_configurations table")
        
        # Create recovery_procedures table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS recovery_procedures (
                id VARCHAR(100) PRIMARY KEY,
                scenario VARCHAR(50) NOT NULL,
                rto_hours NUMERIC(5,2) NOT NULL,
                rpo_hours NUMERIC(5,2) NOT NULL,
                procedure_steps JSONB NOT NULL,
                validation_steps JSONB NOT NULL,
                notification_contacts JSONB DEFAULT '[]'::jsonb,
                active BOOLEAN DEFAULT TRUE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                created_by VARCHAR(100),
                updated_at TIMESTAMP,
                updated_by VARCHAR(100),
                metadata JSONB DEFAULT '{}'::jsonb
            )
        """)
        print("✓ Created recovery_procedures table")
        
        # Create backup_jobs table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS backup_jobs (
                id VARCHAR(100) PRIMARY KEY,
                configuration_id VARCHAR(100),
                backup_type VARCHAR(50) NOT NULL,
                status VARCHAR(50) NOT NULL,
                started_at TIMESTAMP NOT NULL,
                completed_at TIMESTAMP,
                size_bytes BIGINT,
                files_count INTEGER,
                storage_location VARCHAR(50) NOT NULL,
                storage_path TEXT,
                checksum VARCHAR(255),
                compression_ratio NUMERIC(4,2),
                encryption_key_id VARCHAR(100),
                error_message TEXT,
                retry_count INTEGER DEFAULT 0,
                initiated_by VARCHAR(100),
                metadata JSONB DEFAULT '{}'::jsonb,
                FOREIGN KEY (configuration_id) REFERENCES backup_configurations(id)
            )
        """)
        print("✓ Created backup_jobs table")
        
        # Create recovery_jobs table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS recovery_jobs (
                id VARCHAR(100) PRIMARY KEY,
                backup_id VARCHAR(100) NOT NULL,
                recovery_scenario VARCHAR(50) NOT NULL,
                target_environment VARCHAR(50) NOT NULL,
                restore_point TIMESTAMP,
                validation_required BOOLEAN DEFAULT TRUE,
                dry_run BOOLEAN DEFAULT FALSE,
                status VARCHAR(50) NOT NULL,
                initiated_at TIMESTAMP NOT NULL,
                started_at TIMESTAMP,
                completed_at TIMESTAMP,
                data_recovered_bytes BIGINT,
                objects_recovered INTEGER,
                validation_result VARCHAR(50),
                error_message TEXT,
                initiated_by VARCHAR(100),
                metadata JSONB DEFAULT '{}'::jsonb,
                FOREIGN KEY (backup_id) REFERENCES backup_jobs(id)
            )
        """)
        print("✓ Created recovery_jobs table")
        
        # Create backup_validations table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS backup_validations (
                id VARCHAR(100) PRIMARY KEY,
                validation_type VARCHAR(50) NOT NULL,
                schedule VARCHAR(50) NOT NULL,
                method VARCHAR(100) NOT NULL,
                success_criteria JSONB NOT NULL,
                test_environment_id VARCHAR(100),
                active BOOLEAN DEFAULT TRUE,
                last_run_at TIMESTAMP,
                last_run_result VARCHAR(50),
                next_run_at TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                created_by VARCHAR(100),
                notification_settings JSONB DEFAULT '{}'::jsonb,
                metadata JSONB DEFAULT '{}'::jsonb
            )
        """)
        print("✓ Created backup_validations table")
        
        # Create validation_results table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS validation_results (
                id VARCHAR(100) PRIMARY KEY,
                validation_id VARCHAR(100) NOT NULL,
                backup_job_id VARCHAR(100),
                validation_date TIMESTAMP NOT NULL,
                result VARCHAR(50) NOT NULL,
                duration_seconds INTEGER,
                files_validated INTEGER,
                errors_found INTEGER,
                error_details JSONB DEFAULT '[]'::jsonb,
                success_criteria_met BOOLEAN,
                test_environment_used VARCHAR(100),
                metadata JSONB DEFAULT '{}'::jsonb,
                FOREIGN KEY (validation_id) REFERENCES backup_validations(id),
                FOREIGN KEY (backup_job_id) REFERENCES backup_jobs(id)
            )
        """)
        print("✓ Created validation_results table")
        
        # Create backup_schedules table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS backup_schedules (
                id VARCHAR(100) PRIMARY KEY,
                configuration_id VARCHAR(100) NOT NULL,
                schedule_name VARCHAR(255) NOT NULL,
                cron_expression VARCHAR(100),
                next_run_at TIMESTAMP NOT NULL,
                last_run_at TIMESTAMP,
                active BOOLEAN DEFAULT TRUE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                metadata JSONB DEFAULT '{}'::jsonb,
                FOREIGN KEY (configuration_id) REFERENCES backup_configurations(id)
            )
        """)
        print("✓ Created backup_schedules table")
        
        # Create indexes
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_backup_jobs_status 
            ON backup_jobs(status)
        """)
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_backup_jobs_type 
            ON backup_jobs(backup_type)
        """)
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_backup_jobs_started_at 
            ON backup_jobs(started_at DESC)
        """)
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_recovery_jobs_status 
            ON recovery_jobs(status)
        """)
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_recovery_jobs_scenario 
            ON recovery_jobs(recovery_scenario)
        """)
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_validation_results_date 
            ON validation_results(validation_date DESC)
        """)
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_backup_schedules_next_run 
            ON backup_schedules(next_run_at)
        """)
        print("✓ Created indexes for backup and recovery tables")
        
        # Insert default backup configurations based on BDD specs
        await conn.execute("""
            INSERT INTO backup_configurations 
            (id, backup_type, frequency, retention_days, storage_location, 
             compression_enabled, encryption_enabled, validation_enabled, 
             notification_emails, created_at, metadata)
            VALUES 
            ('default_full_backup', 'full', 'daily', 30, 'offsite', 
             true, true, true, '["admin@wfm.local"]'::jsonb, CURRENT_TIMESTAMP,
             '{"description": "Daily full database backup at 2 AM", "purpose": "Complete recovery"}'::jsonb),
            ('default_incremental', 'incremental', '6hours', 7, 'local',
             true, true, false, '[]'::jsonb, CURRENT_TIMESTAMP,
             '{"description": "Incremental backup every 6 hours", "purpose": "Point-in-time recovery"}'::jsonb),
            ('default_app_backup', 'application', 'on_demand', 10, 'version_control',
             false, false, true, '["devops@wfm.local"]'::jsonb, CURRENT_TIMESTAMP,
             '{"description": "Application backup before updates", "purpose": "Rollback capability"}'::jsonb),
            ('default_config_backup', 'configuration', 'on_demand', 20, 'secure_repository',
             false, true, true, '["admin@wfm.local"]'::jsonb, CURRENT_TIMESTAMP,
             '{"description": "Configuration backup after changes", "purpose": "System recovery"}'::jsonb)
            ON CONFLICT (id) DO NOTHING
        """)
        print("✓ Inserted default backup configurations")
        
        # Insert default recovery procedures based on BDD specs
        await conn.execute("""
            INSERT INTO recovery_procedures
            (id, scenario, rto_hours, rpo_hours, procedure_steps, validation_steps,
             notification_contacts, created_at, metadata)
            VALUES
            ('proc_db_corruption', 'database_corruption', 4, 1,
             '[{"step": 1, "action": "Stop affected services"},
               {"step": 2, "action": "Validate backup integrity"},
               {"step": 3, "action": "Restore from latest full backup"},
               {"step": 4, "action": "Apply incremental backups"},
               {"step": 5, "action": "Verify data integrity"}]'::jsonb,
             '[{"step": 1, "check": "Database consistency check"},
               {"step": 2, "check": "Application connectivity test"},
               {"step": 3, "check": "Data integrity verification"}]'::jsonb,
             '["dba@wfm.local", "ops@wfm.local"]'::jsonb, CURRENT_TIMESTAMP,
             '{"description": "Database corruption recovery procedure"}'::jsonb),
            ('proc_app_failure', 'application_failure', 0.5, 0,
             '[{"step": 1, "action": "Identify failed service"},
               {"step": 2, "action": "Attempt service restart"},
               {"step": 3, "action": "If failed, rollback to previous version"},
               {"step": 4, "action": "Verify functionality"}]'::jsonb,
             '[{"step": 1, "check": "Service health check"},
               {"step": 2, "check": "Functionality test"}]'::jsonb,
             '["devops@wfm.local"]'::jsonb, CURRENT_TIMESTAMP,
             '{"description": "Application failure recovery procedure"}'::jsonb),
            ('proc_system_loss', 'complete_system_loss', 24, 6,
             '[{"step": 1, "action": "Provision new infrastructure"},
               {"step": 2, "action": "Install base system"},
               {"step": 3, "action": "Restore from offsite backup"},
               {"step": 4, "action": "Configure networking"},
               {"step": 5, "action": "Restore application stack"},
               {"step": 6, "action": "Import data"},
               {"step": 7, "action": "Validate full system"}]'::jsonb,
             '[{"step": 1, "check": "Infrastructure readiness"},
               {"step": 2, "check": "Network connectivity"},
               {"step": 3, "check": "Application stack verification"},
               {"step": 4, "check": "End-to-end testing"}]'::jsonb,
             '["cto@wfm.local", "ops@wfm.local", "security@wfm.local"]'::jsonb, CURRENT_TIMESTAMP,
             '{"description": "Complete system loss recovery procedure"}'::jsonb),
            ('proc_security_breach', 'security_breach', 2, 0,
             '[{"step": 1, "action": "Isolate affected systems"},
               {"step": 2, "action": "Forensic backup creation"},
               {"step": 3, "action": "Clean restore from secure backup"},
               {"step": 4, "action": "Reset all credentials"},
               {"step": 5, "action": "Security validation"}]'::jsonb,
             '[{"step": 1, "check": "Security scan"},
               {"step": 2, "check": "Access control verification"},
               {"step": 3, "check": "Audit log review"}]'::jsonb,
             '["security@wfm.local", "ciso@wfm.local", "legal@wfm.local"]'::jsonb, CURRENT_TIMESTAMP,
             '{"description": "Security breach recovery procedure"}'::jsonb)
            ON CONFLICT (id) DO NOTHING
        """)
        print("✓ Inserted default recovery procedures")
        
    finally:
        await conn.close()
    
    print("\n✅ Backup and recovery tables created successfully!")

if __name__ == "__main__":
    asyncio.run(create_backup_recovery_tables())