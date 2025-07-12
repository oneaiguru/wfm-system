"""
Create security tables for BDD security implementation
"""

import asyncio
import asyncpg
from src.api.core.config import settings

async def create_security_tables():
    """Create security-related tables"""
    
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
        # Create security_roles table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS security_roles (
                id VARCHAR(100) PRIMARY KEY,
                name VARCHAR(50) UNIQUE NOT NULL,
                description TEXT,
                permissions JSONB NOT NULL,
                scope VARCHAR(50) NOT NULL,
                limitations JSONB,
                requires_audit BOOLEAN DEFAULT TRUE,
                requires_mfa BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                created_by VARCHAR(100),
                metadata JSONB DEFAULT '{}'::jsonb
            )
        """)
        print("✓ Created security_roles table")
        
        # Create user_role_assignments table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS user_role_assignments (
                id VARCHAR(100) PRIMARY KEY,
                user_id VARCHAR(100) NOT NULL,
                role_id VARCHAR(50) NOT NULL,
                department_id VARCHAR(100),
                team_id VARCHAR(100),
                expires_at TIMESTAMP,
                justification TEXT,
                assigned_by VARCHAR(100),
                assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                revoked_at TIMESTAMP,
                revoked_by VARCHAR(100),
                is_active BOOLEAN DEFAULT TRUE
            )
        """)
        print("✓ Created user_role_assignments table")
        
        # Create audit_logs table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS audit_logs (
                id VARCHAR(100) PRIMARY KEY,
                user_id VARCHAR(100) NOT NULL,
                action VARCHAR(50) NOT NULL,
                resource_type VARCHAR(50) NOT NULL,
                resource_id VARCHAR(100) NOT NULL,
                details JSONB,
                ip_address VARCHAR(45),
                user_agent TEXT,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                metadata JSONB DEFAULT '{}'::jsonb
            )
        """)
        print("✓ Created audit_logs table")
        
        # Create data_encryption_log table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS data_encryption_log (
                id VARCHAR(100) PRIMARY KEY,
                field_name VARCHAR(100) NOT NULL,
                classification VARCHAR(50) NOT NULL,
                encrypted_by VARCHAR(100),
                encrypted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                decryption_count INTEGER DEFAULT 0,
                last_decrypted_at TIMESTAMP,
                last_decrypted_by VARCHAR(100)
            )
        """)
        print("✓ Created data_encryption_log table")
        
        # Create indexes
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_user_role_assignments_user_id 
            ON user_role_assignments(user_id)
        """)
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_user_role_assignments_role_id 
            ON user_role_assignments(role_id)
        """)
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id 
            ON audit_logs(user_id)
        """)
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_audit_logs_action 
            ON audit_logs(action)
        """)
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp 
            ON audit_logs(timestamp DESC)
        """)
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_audit_logs_resource 
            ON audit_logs(resource_type, resource_id)
        """)
        print("✓ Created indexes for security tables")
        
        # Insert default roles
        await conn.execute("""
            INSERT INTO security_roles (id, name, description, permissions, scope, limitations, requires_audit, requires_mfa)
            VALUES 
                ('role_hr_admin', 'hr_administrator', 'Full access to all personnel data', 
                 '["create", "read", "update", "delete", "export", "bulk_operations"]'::jsonb, 
                 'all_employees', '["Audit trail required"]'::jsonb, true, true),
                ('role_dept_mgr', 'department_manager', 'Manage department employees',
                 '["read", "update_limited", "export_department"]'::jsonb,
                 'department_only', '["Own department only", "Cannot delete employees"]'::jsonb, true, false),
                ('role_team_lead', 'team_lead', 'View team members and update contact info',
                 '["read", "update_contact"]'::jsonb,
                 'team_only', '["Team members only", "Contact info updates only"]'::jsonb, true, false),
                ('role_employee', 'employee', 'Self-service access to own data',
                 '["read_self", "update_contact_self"]'::jsonb,
                 'self_only', '["Personal information only"]'::jsonb, false, false)
            ON CONFLICT (name) DO NOTHING
        """)
        print("✓ Inserted default security roles")
        
    finally:
        await conn.close()
    
    print("\n✅ Security tables created successfully!")

if __name__ == "__main__":
    asyncio.run(create_security_tables())