-- =====================================================================================
-- Organizational Structure & Roles Schema
-- Module: Multi-site organization hierarchy with RBAC
-- Created for: DATABASE-OPUS Agent
-- Purpose: Enable proper approval routing, access control, and multi-site support
-- BDD Sources: 16-personnel-management-organizational-structure.feature
--              26-roles-access-control.feature
-- =====================================================================================

BEGIN;

-- =====================================================================================
-- 1. ORGANIZATIONAL HIERARCHY
-- =====================================================================================

-- Departments/Sites hierarchy with multi-level support
CREATE TABLE IF NOT EXISTS departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    department_code VARCHAR(50) UNIQUE,
    parent_id INTEGER REFERENCES departments(department_id),
    department_type VARCHAR(50) CHECK (department_type IN (
        'company', 'region', 'site', 'department', 'team', 'group'
    )),
    manager_id INTEGER,
    deputy_manager_id INTEGER,
    cost_center_code VARCHAR(50),
    location VARCHAR(255),
    time_zone VARCHAR(50) DEFAULT 'Europe/Moscow',
    participates_in_approval BOOLEAN DEFAULT TRUE,
    scheduling_authority_level VARCHAR(20) DEFAULT 'LIMITED' CHECK (scheduling_authority_level IN (
        'FULL', 'LIMITED', 'VIEW_ONLY', 'NONE'
    )),
    hierarchy_path TEXT, -- Materialized path for efficient queries (e.g., /1/5/12/)
    hierarchy_level INTEGER NOT NULL DEFAULT 0,
    employee_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT no_self_parent CHECK (department_id != parent_id),
    CONSTRAINT valid_hierarchy CHECK (hierarchy_level >= 0 AND hierarchy_level <= 10)
);

-- Indexes for department queries
CREATE INDEX idx_departments_parent ON departments(parent_id) WHERE is_active = TRUE;
CREATE INDEX idx_departments_manager ON departments(manager_id);
CREATE INDEX idx_departments_hierarchy ON departments(hierarchy_path);
CREATE INDEX idx_departments_type ON departments(department_type);
CREATE INDEX idx_departments_code ON departments(department_code) WHERE is_active = TRUE;

-- Sites/Locations for multi-site support
CREATE TABLE IF NOT EXISTS sites (
    site_id SERIAL PRIMARY KEY,
    site_code VARCHAR(50) UNIQUE NOT NULL,
    site_name VARCHAR(100) NOT NULL,
    site_type VARCHAR(50) CHECK (site_type IN (
        'headquarters', 'branch', 'call_center', 'remote'
    )),
    address TEXT,
    city VARCHAR(100),
    region VARCHAR(100),
    country VARCHAR(100) DEFAULT 'Russia',
    time_zone VARCHAR(50) NOT NULL,
    phone VARCHAR(50),
    primary_department_id INTEGER REFERENCES departments(department_id),
    capacity_seats INTEGER,
    operating_hours JSONB, -- {"monday": {"start": "09:00", "end": "18:00"}, ...}
    is_24x7 BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_sites_code ON sites(site_code) WHERE is_active = TRUE;
CREATE INDEX idx_sites_department ON sites(primary_department_id);

-- Department deputies for delegation
CREATE TABLE IF NOT EXISTS department_deputies (
    deputy_id SERIAL PRIMARY KEY,
    department_id INTEGER NOT NULL REFERENCES departments(department_id),
    deputy_employee_id INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason VARCHAR(255),
    delegation_scope VARCHAR(50) DEFAULT 'FULL' CHECK (delegation_scope IN (
        'FULL', 'APPROVALS_ONLY', 'VIEWING_ONLY', 'SCHEDULING_ONLY'
    )),
    created_by INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_deputy_period CHECK (end_date > start_date),
    CONSTRAINT max_deputy_duration CHECK (end_date - start_date <= 365)
);

CREATE INDEX idx_deputies_department ON department_deputies(department_id);
CREATE INDEX idx_deputies_active ON department_deputies(start_date, end_date) 
    WHERE CURRENT_DATE BETWEEN start_date AND end_date;

-- =====================================================================================
-- 2. POSITIONS AND JOB ROLES
-- =====================================================================================

-- Position catalog
CREATE TABLE IF NOT EXISTS positions (
    position_id SERIAL PRIMARY KEY,
    position_code VARCHAR(50) UNIQUE,
    position_name VARCHAR(100) NOT NULL,
    position_name_en VARCHAR(100),
    position_category VARCHAR(50) CHECK (position_category IN (
        'management', 'supervisor', 'specialist', 'operator', 'support', 'technical'
    )),
    min_grade INTEGER DEFAULT 1,
    max_grade INTEGER DEFAULT 10,
    requires_certification BOOLEAN DEFAULT FALSE,
    default_permissions JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_positions_category ON positions(position_category) WHERE is_active = TRUE;

-- =====================================================================================
-- 3. EMPLOYEE ORGANIZATIONAL ASSIGNMENTS
-- =====================================================================================

-- Extend employees table with organizational data
ALTER TABLE employees ADD COLUMN IF NOT EXISTS department_id INTEGER REFERENCES departments(department_id);
ALTER TABLE employees ADD COLUMN IF NOT EXISTS position_id INTEGER REFERENCES positions(position_id);
ALTER TABLE employees ADD COLUMN IF NOT EXISTS site_id INTEGER REFERENCES sites(site_id);
ALTER TABLE employees ADD COLUMN IF NOT EXISTS direct_manager_id INTEGER REFERENCES employees(employee_id);
ALTER TABLE employees ADD COLUMN IF NOT EXISTS personnel_number VARCHAR(50) UNIQUE;
ALTER TABLE employees ADD COLUMN IF NOT EXISTS grade INTEGER DEFAULT 1;
ALTER TABLE employees ADD COLUMN IF NOT EXISTS hire_date DATE;
ALTER TABLE employees ADD COLUMN IF NOT EXISTS termination_date DATE;
ALTER TABLE employees ADD COLUMN IF NOT EXISTS work_schedule_type VARCHAR(50);

-- Employee organizational history
CREATE TABLE IF NOT EXISTS employee_org_history (
    history_id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employees(employee_id),
    department_id INTEGER REFERENCES departments(department_id),
    position_id INTEGER REFERENCES positions(position_id),
    site_id INTEGER REFERENCES sites(site_id),
    manager_id INTEGER REFERENCES employees(employee_id),
    change_date DATE NOT NULL,
    change_type VARCHAR(50) CHECK (change_type IN (
        'hire', 'transfer', 'promotion', 'demotion', 'reorganization', 'termination'
    )),
    change_reason TEXT,
    created_by INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_emp_org_history_employee ON employee_org_history(employee_id);
CREATE INDEX idx_emp_org_history_date ON employee_org_history(change_date DESC);

-- =====================================================================================
-- 4. ROLES AND PERMISSIONS (RBAC)
-- =====================================================================================

-- Role definitions
CREATE TABLE IF NOT EXISTS roles (
    role_id SERIAL PRIMARY KEY,
    role_code VARCHAR(50) UNIQUE NOT NULL,
    role_name VARCHAR(100) NOT NULL,
    role_name_en VARCHAR(100),
    description TEXT,
    role_type VARCHAR(20) DEFAULT 'custom' CHECK (role_type IN (
        'system', 'business', 'custom'
    )),
    is_default BOOLEAN DEFAULT FALSE,
    priority INTEGER DEFAULT 100, -- Lower number = higher priority for conflicts
    max_assignments INTEGER, -- NULL = unlimited
    requires_approval BOOLEAN DEFAULT FALSE,
    valid_from DATE,
    valid_until DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT role_name_length CHECK (LENGTH(role_name) BETWEEN 3 AND 100)
);

-- Insert system roles
INSERT INTO roles (role_code, role_name, role_name_en, description, role_type, priority) VALUES
    ('ADMIN', 'Администратор', 'Administrator', 'Full system access', 'system', 1),
    ('SENIOR_OPERATOR', 'Старший оператор', 'Senior Operator', 'Advanced operations access', 'system', 10),
    ('OPERATOR', 'Оператор', 'Operator', 'Basic operations access', 'system', 20),
    ('SUPERVISOR', 'Супервизор', 'Supervisor', 'Team management access', 'business', 30),
    ('MANAGER', 'Менеджер', 'Manager', 'Department management access', 'business', 25),
    ('HR_MANAGER', 'HR Менеджер', 'HR Manager', 'Personnel management access', 'business', 35),
    ('ANALYST', 'Аналитик', 'Analyst', 'Reporting and analytics access', 'business', 40),
    ('VIEWER', 'Наблюдатель', 'Viewer', 'Read-only access', 'system', 100)
ON CONFLICT (role_code) DO NOTHING;

-- Permission definitions
CREATE TABLE IF NOT EXISTS permissions (
    permission_id SERIAL PRIMARY KEY,
    permission_code VARCHAR(100) UNIQUE NOT NULL,
    permission_group VARCHAR(50) NOT NULL,
    permission_name VARCHAR(100) NOT NULL,
    description TEXT,
    resource_type VARCHAR(50), -- 'menu', 'api', 'report', 'data'
    is_dangerous BOOLEAN DEFAULT FALSE, -- Requires extra confirmation
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert standard permissions
INSERT INTO permissions (permission_code, permission_group, permission_name, resource_type) VALUES
    -- User Management
    ('users.view', 'USER_MANAGEMENT', 'View users', 'data'),
    ('users.create', 'USER_MANAGEMENT', 'Create users', 'data'),
    ('users.edit', 'USER_MANAGEMENT', 'Edit users', 'data'),
    ('users.delete', 'USER_MANAGEMENT', 'Delete users', 'data'),
    ('users.reset_password', 'USER_MANAGEMENT', 'Reset passwords', 'data'),
    
    -- System Configuration
    ('system.view_config', 'SYSTEM', 'View configuration', 'menu'),
    ('system.edit_config', 'SYSTEM', 'Edit configuration', 'menu'),
    ('system.view_logs', 'SYSTEM', 'View system logs', 'data'),
    
    -- Planning
    ('planning.view', 'PLANNING', 'View planning', 'menu'),
    ('planning.edit', 'PLANNING', 'Edit planning', 'data'),
    ('planning.approve', 'PLANNING', 'Approve plans', 'data'),
    ('planning.publish', 'PLANNING', 'Publish schedules', 'data'),
    
    -- Reporting
    ('reports.view', 'REPORTING', 'View reports', 'menu'),
    ('reports.export', 'REPORTING', 'Export reports', 'data'),
    ('reports.schedule', 'REPORTING', 'Schedule reports', 'data'),
    ('reports.create_custom', 'REPORTING', 'Create custom reports', 'data'),
    
    -- Monitoring
    ('monitoring.view_all', 'MONITORING', 'View all monitoring', 'menu'),
    ('monitoring.view_team', 'MONITORING', 'View team monitoring', 'menu'),
    ('monitoring.view_personal', 'MONITORING', 'View personal data only', 'menu'),
    
    -- Personnel
    ('personnel.view', 'PERSONNEL', 'View personnel', 'data'),
    ('personnel.edit', 'PERSONNEL', 'Edit personnel', 'data'),
    ('personnel.approve_requests', 'PERSONNEL', 'Approve requests', 'data'),
    
    -- Organizational
    ('org.view_structure', 'ORGANIZATION', 'View org structure', 'menu'),
    ('org.edit_structure', 'ORGANIZATION', 'Edit org structure', 'data'),
    ('org.manage_deputies', 'ORGANIZATION', 'Manage deputies', 'data')
ON CONFLICT (permission_code) DO NOTHING;

-- Role-Permission mapping
CREATE TABLE IF NOT EXISTS role_permissions (
    role_permission_id SERIAL PRIMARY KEY,
    role_id INTEGER NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
    permission_id INTEGER NOT NULL REFERENCES permissions(permission_id),
    granted_at TIMESTAMPTZ DEFAULT NOW(),
    granted_by INTEGER,
    
    UNIQUE(role_id, permission_id)
);

CREATE INDEX idx_role_permissions_role ON role_permissions(role_id);
CREATE INDEX idx_role_permissions_permission ON role_permissions(permission_id);

-- Assign permissions to system roles
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_code = 'ADMIN'
ON CONFLICT DO NOTHING;

-- Employee role assignments
CREATE TABLE IF NOT EXISTS employee_roles (
    employee_role_id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employees(employee_id),
    role_id INTEGER NOT NULL REFERENCES roles(role_id),
    department_scope INTEGER REFERENCES departments(department_id), -- NULL = all departments
    site_scope INTEGER REFERENCES sites(site_id), -- NULL = all sites
    assigned_date TIMESTAMPTZ DEFAULT NOW(),
    assigned_by INTEGER REFERENCES employees(employee_id),
    valid_from DATE DEFAULT CURRENT_DATE,
    valid_until DATE,
    assignment_reason TEXT,
    is_temporary BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    CONSTRAINT unique_active_role UNIQUE(employee_id, role_id, department_scope, site_scope),
    CONSTRAINT valid_assignment_period CHECK (valid_until IS NULL OR valid_until > valid_from)
);

CREATE INDEX idx_employee_roles_employee ON employee_roles(employee_id) WHERE is_active = TRUE;
CREATE INDEX idx_employee_roles_role ON employee_roles(role_id);
CREATE INDEX idx_employee_roles_validity ON employee_roles(valid_from, valid_until);

-- =====================================================================================
-- 5. ACCESS CONTROL AND DELEGATION
-- =====================================================================================

-- Feature access rules based on roles
CREATE TABLE IF NOT EXISTS feature_access_rules (
    rule_id SERIAL PRIMARY KEY,
    feature_code VARCHAR(100) NOT NULL,
    feature_name VARCHAR(100) NOT NULL,
    required_permission VARCHAR(100) REFERENCES permissions(permission_code),
    department_restriction VARCHAR(50) CHECK (department_restriction IN (
        'own_only', 'own_and_subordinates', 'all'
    )),
    time_restriction JSONB, -- {"allowed_hours": {"start": "08:00", "end": "20:00"}}
    data_scope_restriction VARCHAR(50) CHECK (data_scope_restriction IN (
        'personal', 'team', 'department', 'site', 'organization'
    )),
    is_active BOOLEAN DEFAULT TRUE
);

-- Delegation rules
CREATE TABLE IF NOT EXISTS delegation_rules (
    rule_id SERIAL PRIMARY KEY,
    delegator_id INTEGER NOT NULL REFERENCES employees(employee_id),
    delegate_id INTEGER NOT NULL REFERENCES employees(employee_id),
    delegation_type VARCHAR(50) CHECK (delegation_type IN (
        'full', 'approvals', 'scheduling', 'reporting', 'specific_permissions'
    )),
    specific_permissions TEXT[], -- Array of permission codes
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    auto_extend BOOLEAN DEFAULT FALSE,
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER REFERENCES employees(employee_id),
    
    CONSTRAINT no_self_delegation CHECK (delegator_id != delegate_id),
    CONSTRAINT valid_delegation_period CHECK (end_date > start_date)
);

CREATE INDEX idx_delegation_active ON delegation_rules(delegator_id, start_date, end_date)
    WHERE NOW() BETWEEN start_date AND end_date;

-- =====================================================================================
-- 6. AUDIT AND COMPLIANCE
-- =====================================================================================

-- Role assignment audit
CREATE TABLE IF NOT EXISTS role_assignment_audit (
    audit_id BIGSERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL,
    role_id INTEGER NOT NULL,
    action VARCHAR(20) CHECK (action IN ('ASSIGNED', 'REVOKED', 'MODIFIED', 'EXPIRED')),
    performed_by INTEGER REFERENCES employees(employee_id),
    performed_at TIMESTAMPTZ DEFAULT NOW(),
    reason TEXT,
    previous_values JSONB,
    new_values JSONB,
    ip_address INET,
    session_id VARCHAR(100)
);

CREATE INDEX idx_role_audit_employee ON role_assignment_audit(employee_id);
CREATE INDEX idx_role_audit_timestamp ON role_assignment_audit(performed_at DESC);

-- Access violation log
CREATE TABLE IF NOT EXISTS access_violations (
    violation_id BIGSERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employees(employee_id),
    attempted_action VARCHAR(255) NOT NULL,
    required_permission VARCHAR(100),
    violation_type VARCHAR(50) CHECK (violation_type IN (
        'insufficient_permissions', 'expired_role', 'department_restriction', 
        'time_restriction', 'delegation_expired'
    )),
    occurred_at TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT,
    additional_context JSONB
);

CREATE INDEX idx_violations_employee ON access_violations(employee_id);
CREATE INDEX idx_violations_timestamp ON access_violations(occurred_at DESC);

-- =====================================================================================
-- 7. VIEWS FOR COMMON QUERIES
-- =====================================================================================

-- Effective permissions view
CREATE OR REPLACE VIEW v_employee_effective_permissions AS
WITH RECURSIVE dept_hierarchy AS (
    -- Get all parent departments for scope calculation
    SELECT d.department_id, d.department_id as scope_dept_id
    FROM departments d
    UNION
    SELECT dh.department_id, d.parent_id
    FROM dept_hierarchy dh
    JOIN departments d ON dh.scope_dept_id = d.department_id
    WHERE d.parent_id IS NOT NULL
)
SELECT DISTINCT
    e.employee_id,
    e.full_name,
    e.department_id,
    p.permission_code,
    p.permission_group,
    p.permission_name,
    r.role_name,
    er.department_scope,
    er.site_scope,
    CASE 
        WHEN er.department_scope IS NULL THEN 'organization'
        WHEN er.department_scope = e.department_id THEN 'own_department'
        WHEN EXISTS (
            SELECT 1 FROM dept_hierarchy 
            WHERE department_id = e.department_id 
            AND scope_dept_id = er.department_scope
        ) THEN 'parent_department'
        ELSE 'specific_department'
    END as scope_type
FROM employees e
JOIN employee_roles er ON e.employee_id = er.employee_id 
    AND er.is_active = TRUE
    AND CURRENT_DATE BETWEEN COALESCE(er.valid_from, CURRENT_DATE) 
    AND COALESCE(er.valid_until, CURRENT_DATE + 1)
JOIN roles r ON er.role_id = r.role_id AND r.is_active = TRUE
JOIN role_permissions rp ON r.role_id = rp.role_id
JOIN permissions p ON rp.permission_id = p.permission_id AND p.is_active = TRUE
WHERE e.is_active = TRUE;

-- Department hierarchy with managers
CREATE OR REPLACE VIEW v_department_hierarchy AS
WITH RECURSIVE dept_tree AS (
    SELECT 
        d.department_id,
        d.department_name,
        d.department_code,
        d.parent_id,
        d.department_type,
        d.hierarchy_level,
        d.hierarchy_path,
        m.full_name as manager_name,
        dm.full_name as deputy_manager_name,
        d.employee_count,
        d.scheduling_authority_level
    FROM departments d
    LEFT JOIN employees m ON d.manager_id = m.employee_id
    LEFT JOIN employees dm ON d.deputy_manager_id = dm.employee_id
    WHERE d.is_active = TRUE
)
SELECT 
    dt.*,
    (SELECT COUNT(*) FROM departments WHERE parent_id = dt.department_id) as child_count,
    COALESCE(dt.hierarchy_path, '/') as full_path
FROM dept_tree dt
ORDER BY dt.hierarchy_path;

-- Active delegations view
CREATE OR REPLACE VIEW v_active_delegations AS
SELECT 
    dr.*,
    delegator.full_name as delegator_name,
    delegate.full_name as delegate_name,
    CASE 
        WHEN dr.end_date < NOW() THEN 'expired'
        WHEN dr.start_date > NOW() THEN 'future'
        ELSE 'active'
    END as delegation_status
FROM delegation_rules dr
JOIN employees delegator ON dr.delegator_id = delegator.employee_id
JOIN employees delegate ON dr.delegate_id = delegate.employee_id
WHERE dr.start_date <= NOW() + INTERVAL '30 days';

-- Organization summary dashboard
CREATE OR REPLACE VIEW v_organization_summary AS
SELECT 
    (SELECT COUNT(*) FROM departments WHERE is_active = TRUE) as total_departments,
    (SELECT COUNT(*) FROM sites WHERE is_active = TRUE) as total_sites,
    (SELECT COUNT(*) FROM employees WHERE is_active = TRUE) as total_employees,
    (SELECT COUNT(*) FROM roles WHERE is_active = TRUE AND role_type = 'custom') as custom_roles,
    (SELECT COUNT(DISTINCT employee_id) FROM employee_roles WHERE is_active = TRUE) as employees_with_roles,
    (SELECT COUNT(*) FROM department_deputies WHERE CURRENT_DATE BETWEEN start_date AND end_date) as active_deputies,
    (SELECT COUNT(*) FROM delegation_rules WHERE NOW() BETWEEN start_date AND end_date) as active_delegations;

-- =====================================================================================
-- 8. FUNCTIONS AND TRIGGERS
-- =====================================================================================

-- Function to update department hierarchy path
CREATE OR REPLACE FUNCTION update_department_hierarchy() 
RETURNS TRIGGER AS $$
DECLARE
    v_parent_path TEXT;
    v_parent_level INTEGER;
BEGIN
    IF NEW.parent_id IS NULL THEN
        NEW.hierarchy_path := '/' || NEW.department_id || '/';
        NEW.hierarchy_level := 0;
    ELSE
        SELECT hierarchy_path, hierarchy_level 
        INTO v_parent_path, v_parent_level
        FROM departments 
        WHERE department_id = NEW.parent_id;
        
        IF v_parent_path IS NULL THEN
            RAISE EXCEPTION 'Parent department % not found', NEW.parent_id;
        END IF;
        
        NEW.hierarchy_path := v_parent_path || NEW.department_id || '/';
        NEW.hierarchy_level := v_parent_level + 1;
        
        -- Check for circular reference
        IF NEW.hierarchy_path LIKE '%/' || NEW.department_id || '/%' THEN
            RAISE EXCEPTION 'Circular reference detected in department hierarchy';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER maintain_department_hierarchy
    BEFORE INSERT OR UPDATE OF parent_id ON departments
    FOR EACH ROW EXECUTE FUNCTION update_department_hierarchy();

-- Function to check user permission
CREATE OR REPLACE FUNCTION check_user_permission(
    p_employee_id INTEGER,
    p_permission_code VARCHAR,
    p_target_department_id INTEGER DEFAULT NULL,
    p_target_site_id INTEGER DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_has_permission BOOLEAN := FALSE;
BEGIN
    -- Check direct permissions
    SELECT EXISTS (
        SELECT 1
        FROM v_employee_effective_permissions
        WHERE employee_id = p_employee_id
            AND permission_code = p_permission_code
            AND (
                department_scope IS NULL OR 
                department_scope = p_target_department_id OR
                p_target_department_id IN (
                    SELECT department_id FROM departments 
                    WHERE hierarchy_path LIKE '%/' || department_scope || '/%'
                )
            )
            AND (site_scope IS NULL OR site_scope = p_target_site_id)
    ) INTO v_has_permission;
    
    -- Check delegations if no direct permission
    IF NOT v_has_permission THEN
        SELECT EXISTS (
            SELECT 1
            FROM delegation_rules dr
            WHERE dr.delegate_id = p_employee_id
                AND NOW() BETWEEN dr.start_date AND dr.end_date
                AND (
                    dr.delegation_type = 'full' OR
                    p_permission_code = ANY(dr.specific_permissions)
                )
        ) INTO v_has_permission;
    END IF;
    
    -- Log access violation if permission denied
    IF NOT v_has_permission THEN
        INSERT INTO access_violations (
            employee_id, attempted_action, required_permission, violation_type
        ) VALUES (
            p_employee_id, 
            'Attempted to use permission: ' || p_permission_code,
            p_permission_code,
            'insufficient_permissions'
        );
    END IF;
    
    RETURN v_has_permission;
END;
$$ LANGUAGE plpgsql;

-- Function to get employee's subordinates
CREATE OR REPLACE FUNCTION get_employee_subordinates(
    p_employee_id INTEGER,
    p_include_indirect BOOLEAN DEFAULT TRUE
) RETURNS TABLE (
    employee_id INTEGER,
    full_name VARCHAR,
    department_id INTEGER,
    department_name VARCHAR,
    level INTEGER
) AS $$
BEGIN
    IF p_include_indirect THEN
        -- Get all subordinates recursively
        RETURN QUERY
        WITH RECURSIVE subordinates AS (
            -- Direct reports
            SELECT 
                e.employee_id,
                e.full_name,
                e.department_id,
                d.department_name,
                1 as level
            FROM employees e
            JOIN departments d ON e.department_id = d.department_id
            WHERE e.direct_manager_id = p_employee_id
                AND e.is_active = TRUE
            
            UNION ALL
            
            -- Indirect reports
            SELECT 
                e.employee_id,
                e.full_name,
                e.department_id,
                d.department_name,
                s.level + 1
            FROM employees e
            JOIN departments d ON e.department_id = d.department_id
            JOIN subordinates s ON e.direct_manager_id = s.employee_id
            WHERE e.is_active = TRUE
        )
        SELECT * FROM subordinates
        ORDER BY level, department_name, full_name;
    ELSE
        -- Direct reports only
        RETURN QUERY
        SELECT 
            e.employee_id,
            e.full_name,
            e.department_id,
            d.department_name,
            1 as level
        FROM employees e
        JOIN departments d ON e.department_id = d.department_id
        WHERE e.direct_manager_id = p_employee_id
            AND e.is_active = TRUE
        ORDER BY department_name, full_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to assign role with validation
CREATE OR REPLACE FUNCTION assign_employee_role(
    p_employee_id INTEGER,
    p_role_code VARCHAR,
    p_assigned_by INTEGER,
    p_department_scope INTEGER DEFAULT NULL,
    p_site_scope INTEGER DEFAULT NULL,
    p_valid_until DATE DEFAULT NULL,
    p_reason TEXT DEFAULT NULL
) RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    employee_role_id INTEGER
) AS $$
DECLARE
    v_role_id INTEGER;
    v_employee_role_id INTEGER;
    v_existing_count INTEGER;
    v_max_assignments INTEGER;
BEGIN
    -- Validate role exists
    SELECT role_id, max_assignments 
    INTO v_role_id, v_max_assignments
    FROM roles 
    WHERE role_code = p_role_code AND is_active = TRUE;
    
    IF v_role_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Role not found: ' || p_role_code, NULL::INTEGER;
        RETURN;
    END IF;
    
    -- Check maximum assignments limit
    IF v_max_assignments IS NOT NULL THEN
        SELECT COUNT(*) INTO v_existing_count
        FROM employee_roles
        WHERE role_id = v_role_id AND is_active = TRUE;
        
        IF v_existing_count >= v_max_assignments THEN
            RETURN QUERY SELECT FALSE, 
                'Maximum assignments reached for role: ' || p_role_code, 
                NULL::INTEGER;
            RETURN;
        END IF;
    END IF;
    
    -- Check if assignment already exists
    IF EXISTS (
        SELECT 1 FROM employee_roles
        WHERE employee_id = p_employee_id 
            AND role_id = v_role_id
            AND COALESCE(department_scope, -1) = COALESCE(p_department_scope, -1)
            AND COALESCE(site_scope, -1) = COALESCE(p_site_scope, -1)
            AND is_active = TRUE
    ) THEN
        RETURN QUERY SELECT FALSE, 'Role already assigned', NULL::INTEGER;
        RETURN;
    END IF;
    
    -- Create assignment
    INSERT INTO employee_roles (
        employee_id, role_id, department_scope, site_scope,
        assigned_by, valid_until, assignment_reason
    ) VALUES (
        p_employee_id, v_role_id, p_department_scope, p_site_scope,
        p_assigned_by, p_valid_until, p_reason
    ) RETURNING employee_roles.employee_role_id INTO v_employee_role_id;
    
    -- Audit log
    INSERT INTO role_assignment_audit (
        employee_id, role_id, action, performed_by, reason,
        new_values
    ) VALUES (
        p_employee_id, v_role_id, 'ASSIGNED', p_assigned_by, p_reason,
        jsonb_build_object(
            'department_scope', p_department_scope,
            'site_scope', p_site_scope,
            'valid_until', p_valid_until
        )
    );
    
    RETURN QUERY SELECT TRUE, 'Role assigned successfully', v_employee_role_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- 9. INITIAL CONFIGURATION
-- =====================================================================================

-- Create root department if not exists
INSERT INTO departments (
    department_id, department_name, department_code, 
    department_type, hierarchy_level, hierarchy_path
) VALUES (
    1, 'Company', 'ROOT', 'company', 0, '/1/'
) ON CONFLICT (department_id) DO NOTHING;

-- Grant basic permissions to standard roles
-- Operator role: basic viewing permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_code = 'OPERATOR'
    AND p.permission_code IN (
        'planning.view', 'reports.view', 'monitoring.view_personal',
        'personnel.view', 'org.view_structure'
    )
ON CONFLICT DO NOTHING;

-- Supervisor role: team management permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_code = 'SUPERVISOR'
    AND p.permission_code IN (
        'planning.view', 'planning.edit', 'reports.view', 'reports.export',
        'monitoring.view_team', 'personnel.view', 'personnel.approve_requests',
        'org.view_structure'
    )
ON CONFLICT DO NOTHING;

-- =====================================================================================
-- 10. SECURITY AND PERFORMANCE
-- =====================================================================================

-- Row-level security policies
ALTER TABLE employee_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_assignment_audit ENABLE ROW LEVEL SECURITY;
ALTER TABLE access_violations ENABLE ROW LEVEL SECURITY;

-- Add table comments
COMMENT ON TABLE departments IS 'Organizational hierarchy supporting multi-level structures';
COMMENT ON TABLE sites IS 'Physical locations for multi-site workforce management';
COMMENT ON TABLE roles IS 'System and custom roles for access control';
COMMENT ON TABLE permissions IS 'Granular permissions for features and data access';
COMMENT ON TABLE employee_roles IS 'Role assignments with department and site scoping';
COMMENT ON TABLE delegation_rules IS 'Temporary permission delegation between employees';

-- Create update trigger for all tables
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_departments_timestamp 
    BEFORE UPDATE ON departments 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_roles_timestamp 
    BEFORE UPDATE ON roles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

COMMIT;

-- =====================================================================================
-- USAGE EXAMPLES
-- =====================================================================================

/*
-- Create organizational structure
INSERT INTO departments (department_name, department_code, parent_id, department_type) VALUES
    ('Operations', 'OPS', 1, 'department'),
    ('Call Center Moscow', 'CC_MSK', 2, 'site'),
    ('Call Center SPB', 'CC_SPB', 2, 'site');

-- Assign manager to department
UPDATE departments SET manager_id = 1001 WHERE department_code = 'CC_MSK';

-- Create site
INSERT INTO sites (site_code, site_name, site_type, time_zone, primary_department_id) VALUES
    ('MSK01', 'Moscow Call Center', 'call_center', 'Europe/Moscow', 3);

-- Assign role to employee
SELECT * FROM assign_employee_role(
    1025,           -- employee_id
    'SUPERVISOR',   -- role_code
    1000,           -- assigned_by
    3,              -- department_scope (Call Center Moscow)
    1,              -- site_scope
    NULL,           -- valid_until (permanent)
    'Promoted to team supervisor'
);

-- Check user permission
SELECT check_user_permission(1025, 'planning.edit', 3, 1);

-- Get employee subordinates
SELECT * FROM get_employee_subordinates(1001, TRUE);

-- View effective permissions
SELECT * FROM v_employee_effective_permissions WHERE employee_id = 1025;

-- Department hierarchy
SELECT * FROM v_department_hierarchy;
*/