"""
Create integration_logs table for BDD integration service
"""

import asyncio
import asyncpg
from src.api.core.config import settings

async def create_integration_table():
    """Create integration_logs table"""
    
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
        # Create integration_logs table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS integration_logs (
                id SERIAL PRIMARY KEY,
                sync_id VARCHAR(100) UNIQUE NOT NULL,
                integration_id VARCHAR(100) NOT NULL,
                status VARCHAR(20) NOT NULL,
                request_data JSONB,
                total_records INTEGER DEFAULT 0,
                successful_records INTEGER DEFAULT 0,
                failed_records INTEGER DEFAULT 0,
                error_message TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                end_time TIMESTAMP,
                created_by VARCHAR(100),
                metadata JSONB DEFAULT '{}'::jsonb
            )
        """)
        print("✓ Created integration_logs table")
        
        # Create indexes
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_integration_logs_integration_id 
            ON integration_logs(integration_id)
        """)
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_integration_logs_status 
            ON integration_logs(status)
        """)
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_integration_logs_created_at 
            ON integration_logs(created_at DESC)
        """)
        print("✓ Created indexes for integration_logs")
        
        # Create system_settings table if not exists
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS system_settings (
                id SERIAL PRIMARY KEY,
                key VARCHAR(255) UNIQUE NOT NULL,
                value TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        print("✓ Ensured system_settings table exists")
        
    finally:
        await conn.close()
    
    print("\n✅ Integration tables created successfully!")

if __name__ == "__main__":
    asyncio.run(create_integration_table())