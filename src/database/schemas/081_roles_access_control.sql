-- Schema 081: Roles and Access Control Management (BDD 26)
-- Enterprise role-based access control with Russian support
-- Hierarchical permissions and business role flexibility

-- 1. System and Business Roles
CREATE TABLE roles (
    role_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_name VARCHAR(50) NOT NULL UNIQUE,
    role_name_ru VARCHAR(50),
    role_type VARCHAR(20) NOT NULL, -- system, business, custom
    description TEXT,
    description_ru TEXT,
    is_active BOOLEAN DEFAULT true,
    is_default BOOLEAN DEFAULT false, -- Auto-assigned to new users
    is_system BOOLEAN DEFAULT false, -- Cannot be deleted
    parent_role_id UUID REFERENCES roles(role_id), -- Role hierarchy
    created_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_role_name CHECK (LENGTH(role_name) BETWEEN 3 AND 50)
);

-- 2. Permission Categories
CREATE TABLE permission_categories (
    category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_name VARCHAR(100) NOT NULL UNIQUE,
    category_name_ru VARCHAR(100),
    category_code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    display_order INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. System Permissions
CREATE TABLE permissions (
    permission_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    permission_name VARCHAR(100) NOT NULL,
    permission_code VARCHAR(100) NOT NULL UNIQUE,
    category_id UUID REFERENCES permission_categories(category_id),
    resource_type VARCHAR(50), -- user, planning, reporting, system, monitoring
    action VARCHAR(50), -- view, create, edit, delete, approve, export
    description TEXT,
    description_ru TEXT,
    is_critical BOOLEAN DEFAULT false, -- Requires additional validation
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Role-Permission Assignments
CREATE TABLE role_permissions (
    assignment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id UUID REFERENCES roles(role_id) ON DELETE CASCADE,
    permission_id UUID REFERENCES permissions(permission_id),
    granted_by VARCHAR(255),
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    conditions JSONB, -- Additional conditions like time/location restrictions
    UNIQUE(role_id, permission_id)
);

-- 5. User-Role Assignments
CREATE TABLE user_roles (
    assignment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL, -- References employees/users table
    role_id UUID REFERENCES roles(role_id),
    assigned_by VARCHAR(255),
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_from DATE DEFAULT CURRENT_DATE,
    valid_until DATE,
    assignment_reason TEXT,
    is_temporary BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_date_range CHECK (valid_until IS NULL OR valid_until > valid_from)
);

-- 6. Permission Conflicts and Overrides
CREATE TABLE permission_conflicts (
    conflict_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id UUID REFERENCES roles(role_id),
    permission1_id UUID REFERENCES permissions(permission_id),
    permission2_id UUID REFERENCES permissions(permission_id),
    conflict_type VARCHAR(50), -- contradiction, overlap, hierarchy
    resolution VARCHAR(50), -- deny_both, allow_higher, manual_review
    resolved_by VARCHAR(255),
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Access Control Lists (ACL)
CREATE TABLE access_control_lists (
    acl_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    resource_type VARCHAR(50) NOT NULL, -- report, dashboard, module, data
    resource_id VARCHAR(255) NOT NULL,
    role_id UUID REFERENCES roles(role_id),
    user_id UUID, -- Direct user assignment
    access_level VARCHAR(50), -- none, view, edit, full
    conditions JSONB, -- Time-based, location-based restrictions
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(resource_type, resource_id, role_id, user_id)
);

-- 8. Role Delegation
CREATE TABLE role_delegations (
    delegation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    delegator_user_id UUID NOT NULL,
    delegate_user_id UUID NOT NULL,
    role_id UUID REFERENCES roles(role_id),
    delegation_start DATE NOT NULL,
    delegation_end DATE NOT NULL,
    delegation_reason TEXT,
    permissions_subset JSONB, -- Specific permissions if not full role
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_delegation_period CHECK (delegation_end > delegation_start)
);

-- 9. Permission Audit Trail
CREATE TABLE permission_audit_log (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(50), -- grant, revoke, modify, delegate
    user_id UUID,
    role_id UUID,
    permission_id UUID,
    old_value JSONB,
    new_value JSONB,
    performed_by VARCHAR(255),
    reason TEXT,
    ip_address INET,
    event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. Role Templates
CREATE TABLE role_templates (
    template_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_name VARCHAR(100) NOT NULL UNIQUE,
    template_type VARCHAR(50), -- department, position, project
    permissions_set JSONB, -- Array of permission codes
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default system roles
INSERT INTO roles (role_name, role_name_ru, role_type, description, is_system, is_default)
VALUES 
    ('Administrator', 'Администратор', 'system', 'Full system access', true, false),
    ('Senior Operator', 'Старший оператор', 'system', 'Advanced operations access', true, false),
    ('Operator', 'Оператор', 'system', 'Basic operations access', true, true);

-- Insert permission categories
INSERT INTO permission_categories (category_name, category_name_ru, category_code, display_order)
VALUES 
    ('User Management', 'Управление пользователями', 'USER_MGMT', 1),
    ('System Configuration', 'Конфигурация системы', 'SYS_CONFIG', 2),
    ('Planning', 'Планирование', 'PLANNING', 3),
    ('Reporting', 'Отчетность', 'REPORTING', 4),
    ('Monitoring', 'Мониторинг', 'MONITORING', 5),
    ('Personnel Management', 'Управление персоналом', 'PERSONNEL', 6);

-- Insert core permissions
INSERT INTO permissions (permission_name, permission_code, category_id, resource_type, action)
SELECT 
    p.perm_name,
    p.perm_code,
    c.category_id,
    p.resource,
    p.action
FROM permission_categories c
CROSS JOIN (VALUES 
    ('View Users', 'USER_VIEW', 'USER_MGMT', 'user', 'view'),
    ('Create Users', 'USER_CREATE', 'USER_MGMT', 'user', 'create'),
    ('Edit Users', 'USER_EDIT', 'USER_MGMT', 'user', 'edit'),
    ('Delete Users', 'USER_DELETE', 'USER_MGMT', 'user', 'delete'),
    ('View Planning', 'PLANNING_VIEW', 'PLANNING', 'planning', 'view'),
    ('Edit Planning', 'PLANNING_EDIT', 'PLANNING', 'planning', 'edit'),
    ('Approve Planning', 'PLANNING_APPROVE', 'PLANNING', 'planning', 'approve'),
    ('View Reports', 'REPORT_VIEW', 'REPORTING', 'reporting', 'view'),
    ('Export Reports', 'REPORT_EXPORT', 'REPORTING', 'reporting', 'export'),
    ('Schedule Reports', 'REPORT_SCHEDULE', 'REPORTING', 'reporting', 'create')
) AS p(perm_name, perm_code, cat_code, resource, action)
WHERE c.category_code = p.cat_code;

-- Assign permissions to Administrator role (ALL permissions)
INSERT INTO role_permissions (role_id, permission_id, granted_by)
SELECT 
    r.role_id,
    p.permission_id,
    'SYSTEM'
FROM roles r
CROSS JOIN permissions p
WHERE r.role_name = 'Administrator';

-- Create indexes
CREATE INDEX idx_role_permissions_role ON role_permissions(role_id);
CREATE INDEX idx_user_roles_user ON user_roles(user_id);
CREATE INDEX idx_user_roles_dates ON user_roles(valid_from, valid_until);
CREATE INDEX idx_acl_resource ON access_control_lists(resource_type, resource_id);
CREATE INDEX idx_audit_log_user ON permission_audit_log(user_id, event_timestamp);

-- Verify RBAC tables
SELECT COUNT(*) as rbac_tables FROM information_schema.tables 
WHERE table_name LIKE '%role%' OR table_name LIKE '%permission%' OR table_name LIKE '%acl%';