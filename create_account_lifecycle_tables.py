"""
Create account lifecycle management tables
"""

import asyncio
import asyncpg
from src.api.core.config import settings

async def create_account_lifecycle_tables():
    """Create account lifecycle related tables"""
    
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
        # Add columns to users table
        await conn.execute("""
            ALTER TABLE users 
            ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN DEFAULT FALSE,
            ADD COLUMN IF NOT EXISTS password_changed_at TIMESTAMP,
            ADD COLUMN IF NOT EXISTS password_history JSONB DEFAULT '[]'::jsonb,
            ADD COLUMN IF NOT EXISTS failed_login_attempts INTEGER DEFAULT 0,
            ADD COLUMN IF NOT EXISTS last_failed_login TIMESTAMP,
            ADD COLUMN IF NOT EXISTS is_locked BOOLEAN DEFAULT FALSE,
            ADD COLUMN IF NOT EXISTS locked_until TIMESTAMP,
            ADD COLUMN IF NOT EXISTS locked_at TIMESTAMP,
            ADD COLUMN IF NOT EXISTS deactivated_at TIMESTAMP,
            ADD COLUMN IF NOT EXISTS deactivated_by VARCHAR(100)
        """)
        print("✓ Updated users table with lifecycle columns")
        
        # Create provisioning_workflows table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS provisioning_workflows (
                id VARCHAR(100) PRIMARY KEY,
                user_id VARCHAR(100) NOT NULL,
                status VARCHAR(50) NOT NULL,
                current_step VARCHAR(50) NOT NULL,
                requested_roles JSONB NOT NULL,
                justification TEXT,
                hr_approved_by VARCHAR(100),
                hr_approved_at TIMESTAMP,
                manager_approved_by VARCHAR(100),
                manager_approved_at TIMESTAMP,
                completed_at TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                created_by VARCHAR(100),
                metadata JSONB DEFAULT '{}'::jsonb
            )
        """)
        print("✓ Created provisioning_workflows table")
        
        # Create user_sessions table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS user_sessions (
                id VARCHAR(100) PRIMARY KEY,
                user_id VARCHAR(100) NOT NULL,
                session_token VARCHAR(255) UNIQUE NOT NULL,
                ip_address VARCHAR(45),
                user_agent TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                expires_at TIMESTAMP,
                active BOOLEAN DEFAULT TRUE,
                revoked BOOLEAN DEFAULT FALSE,
                revoked_at TIMESTAMP,
                revoked_by VARCHAR(100)
            )
        """)
        print("✓ Created user_sessions table")
        
        # Create security_events table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS security_events (
                id VARCHAR(100) PRIMARY KEY,
                event_type VARCHAR(50) NOT NULL,
                user_id VARCHAR(100) NOT NULL,
                details JSONB,
                severity VARCHAR(20) NOT NULL,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                handled BOOLEAN DEFAULT FALSE,
                handled_at TIMESTAMP,
                handled_by VARCHAR(100),
                escalated BOOLEAN DEFAULT FALSE,
                metadata JSONB DEFAULT '{}'::jsonb
            )
        """)
        print("✓ Created security_events table")
        
        # Create access_reviews table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS access_reviews (
                id VARCHAR(100) PRIMARY KEY,
                review_period VARCHAR(50) NOT NULL,
                reviewer_id VARCHAR(100) NOT NULL,
                department_id VARCHAR(100),
                users_count INTEGER DEFAULT 0,
                completed_count INTEGER DEFAULT 0,
                status VARCHAR(50) DEFAULT 'in_progress',
                due_date TIMESTAMP,
                completed_at TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                created_by VARCHAR(100),
                metadata JSONB DEFAULT '{}'::jsonb
            )
        """)
        print("✓ Created access_reviews table")
        
        # Create indexes
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_provisioning_workflows_user_id 
            ON provisioning_workflows(user_id)
        """)
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_provisioning_workflows_status 
            ON provisioning_workflows(status)
        """)
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id 
            ON user_sessions(user_id)
        """)
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_user_sessions_token 
            ON user_sessions(session_token)
        """)
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_security_events_user_id 
            ON security_events(user_id)
        """)
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_security_events_type 
            ON security_events(event_type)
        """)
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_security_events_timestamp 
            ON security_events(timestamp DESC)
        """)
        print("✓ Created indexes for lifecycle tables")
        
    finally:
        await conn.close()
    
    print("\n✅ Account lifecycle tables created successfully!")

if __name__ == "__main__":
    asyncio.run(create_account_lifecycle_tables())