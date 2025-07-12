#!/usr/bin/env python3
"""
Simple database schema creation - splits SQL into smaller chunks
"""

import asyncio
import sys
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://postgres:@localhost/wfm_enterprise")

# Convert to async URL if needed
if not DATABASE_URL.startswith("postgresql+asyncpg://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://")

print(f"🗄️  Connecting to database: {DATABASE_URL}")

# Create async engine
engine = create_async_engine(DATABASE_URL, echo=False)

# Split schema into smaller chunks
DROP_TABLES_SQL = """
-- Drop existing tables (for clean demo)
DROP TABLE IF EXISTS schedule_shifts CASCADE;
DROP TABLE IF EXISTS schedules CASCADE;
DROP TABLE IF EXISTS forecasts CASCADE;
DROP TABLE IF EXISTS employee_skills CASCADE;
DROP TABLE IF EXISTS skills CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS organizations CASCADE;
DROP TABLE IF EXISTS user_roles CASCADE;
DROP TABLE IF EXISTS roles CASCADE;
DROP TABLE IF EXISTS users CASCADE;
"""

CREATE_CORE_TABLES_SQL = """
-- Organizations table (multi-tenant support)
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Departments table
CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, code)
);

-- Users table (authentication)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    department_id UUID REFERENCES departments(id),
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    is_admin BOOLEAN DEFAULT false,
    is_superuser BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Roles table (simple RBAC)
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    permissions JSONB DEFAULT '[]',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User roles junction table
CREATE TABLE user_roles (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);
"""

CREATE_EMPLOYEE_TABLES_SQL = """
-- Skills table
CREATE TABLE skills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50) DEFAULT 'general',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, name)
);

-- Employees table (personnel management)
CREATE TABLE employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    department_id UUID NOT NULL REFERENCES departments(id),
    user_id UUID REFERENCES users(id),
    employee_number VARCHAR(50) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    employment_type VARCHAR(50) DEFAULT 'full-time',
    hire_date DATE,
    is_active BOOLEAN DEFAULT true,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, employee_number)
);

-- Employee skills junction table
CREATE TABLE employee_skills (
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
    proficiency_level INTEGER DEFAULT 1 CHECK (proficiency_level BETWEEN 1 AND 5),
    certified BOOLEAN DEFAULT false,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (employee_id, skill_id)
);
"""

CREATE_OPERATIONAL_TABLES_SQL = """
-- Forecasts table (ML forecasting)
CREATE TABLE forecasts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    department_id UUID REFERENCES departments(id),
    name VARCHAR(255) NOT NULL,
    forecast_type VARCHAR(50) NOT NULL DEFAULT 'call_volume',
    method VARCHAR(50) NOT NULL DEFAULT 'ml',
    granularity VARCHAR(20) NOT NULL DEFAULT '30min',
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    accuracy_score NUMERIC(5,4),
    parameters JSONB DEFAULT '{}',
    results JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Schedules table (schedule management)
CREATE TABLE schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    department_id UUID REFERENCES departments(id),
    forecast_id UUID REFERENCES forecasts(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    schedule_type VARCHAR(50) DEFAULT 'weekly',
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'draft',
    optimization_score NUMERIC(5,4),
    parameters JSONB DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Schedule shifts table (individual shifts)
CREATE TABLE schedule_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    schedule_id UUID NOT NULL REFERENCES schedules(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id),
    shift_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    break_duration INTEGER DEFAULT 0,
    shift_type VARCHAR(50) DEFAULT 'regular',
    status VARCHAR(50) DEFAULT 'scheduled',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(employee_id, shift_date, start_time)
);
"""

CREATE_INDEXES_SQL = """
-- User indexes
CREATE INDEX idx_users_organization_id ON users(organization_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);

-- Employee indexes
CREATE INDEX idx_employees_organization_id ON employees(organization_id);
CREATE INDEX idx_employees_department_id ON employees(department_id);
CREATE INDEX idx_employees_employee_number ON employees(employee_number);
CREATE INDEX idx_employees_email ON employees(email);

-- Forecast indexes
CREATE INDEX idx_forecasts_organization_id ON forecasts(organization_id);
CREATE INDEX idx_forecasts_department_id ON forecasts(department_id);
CREATE INDEX idx_forecasts_start_date ON forecasts(start_date);
CREATE INDEX idx_forecasts_status ON forecasts(status);

-- Schedule indexes
CREATE INDEX idx_schedules_organization_id ON schedules(organization_id);
CREATE INDEX idx_schedules_department_id ON schedules(department_id);
CREATE INDEX idx_schedules_start_date ON schedules(start_date);
CREATE INDEX idx_schedules_status ON schedules(status);

-- Shift indexes
CREATE INDEX idx_schedule_shifts_schedule_id ON schedule_shifts(schedule_id);
CREATE INDEX idx_schedule_shifts_employee_id ON schedule_shifts(employee_id);
CREATE INDEX idx_schedule_shifts_shift_date ON schedule_shifts(shift_date);
"""

INSERT_DEMO_DATA_SQL = """
-- Insert demo roles
INSERT INTO roles (name, description, permissions) VALUES 
('admin', 'System Administrator', '["users.*", "employees.*", "schedules.*", "forecasts.*"]'),
('manager', 'Department Manager', '["employees.read", "employees.write", "schedules.*", "forecasts.*"]'),
('employee', 'Employee', '["employees.read", "schedules.read"]')
ON CONFLICT (name) DO NOTHING;
"""


async def create_schema():
    """Create the minimal database schema for demo"""
    try:
        async with engine.begin() as conn:
            print("🔧 Creating database schema...")
            
            # Execute in chunks
            print("  📋 Dropping old tables...")
            await conn.execute(text(DROP_TABLES_SQL))
            
            print("  📋 Creating core tables...")
            await conn.execute(text(CREATE_CORE_TABLES_SQL))
            
            print("  📋 Creating employee tables...")
            await conn.execute(text(CREATE_EMPLOYEE_TABLES_SQL))
            
            print("  📋 Creating operational tables...")
            await conn.execute(text(CREATE_OPERATIONAL_TABLES_SQL))
            
            print("  📋 Creating indexes...")
            await conn.execute(text(CREATE_INDEXES_SQL))
            
            print("  📋 Inserting demo data...")
            await conn.execute(text(INSERT_DEMO_DATA_SQL))
            
            print("✅ Schema created successfully!")
            
        # Verify tables were created
        async with engine.begin() as conn:
            result = await conn.execute(text("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' 
                ORDER BY table_name;
            """))
            tables = [row[0] for row in result]
            print(f"\n📋 Created {len(tables)} tables:")
            for table in tables:
                print(f"   - {table}")
            
    except Exception as e:
        print(f"❌ Schema creation failed: {e}")
        sys.exit(1)

async def main():
    """Main function"""
    print("🚀 WFM Enterprise Demo - Database Schema Setup")
    print("=" * 50)
    
    await create_schema()
    
    # Close engine
    await engine.dispose()
    print("\n✨ Database ready for demo data!")

if __name__ == "__main__":
    asyncio.run(main())