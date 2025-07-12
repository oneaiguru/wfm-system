-- =============================================================================
-- 046_multi_site_location_management.sql
-- EXACT BDD Implementation: Multi-Site Location Management with Database Schema
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: 21-multi-site-location-management.feature (200+ lines)
-- Purpose: Comprehensive location hierarchy management for distributed operations
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- =============================================================================
-- 1. LOCATION HIERARCHY MANAGEMENT
-- =============================================================================

-- Site definitions from BDD lines 16-22
CREATE TABLE locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_id VARCHAR(50) NOT NULL UNIQUE,
    location_name VARCHAR(200) NOT NULL,
    location_code VARCHAR(20) NOT NULL UNIQUE,
    description TEXT,
    
    -- Geographic data from BDD lines 43-48
    address TEXT,
    coordinates POINT,
    timezone VARCHAR(50) NOT NULL DEFAULT 'UTC',
    
    -- Hierarchy from BDD line 18
    parent_location_id UUID REFERENCES locations(id),
    location_level INTEGER DEFAULT 1 CHECK (location_level > 0),
    hierarchy_path TEXT, -- Computed path like /corp/region/site
    
    -- Operational data from BDD lines 46-48
    operating_hours JSONB DEFAULT '{"monday": "09:00-17:00", "tuesday": "09:00-17:00", "wednesday": "09:00-17:00", "thursday": "09:00-17:00", "friday": "09:00-17:00"}',
    capacity INTEGER DEFAULT 100,
    services TEXT[],
    
    -- Contact information from BDD line 47
    phone VARCHAR(50),
    email VARCHAR(100),
    contact_person VARCHAR(200),
    
    -- Status management from BDD line 48
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'maintenance')),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Organizational structure from BDD line 19
CREATE TABLE location_hierarchy (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hierarchy_id VARCHAR(50) NOT NULL UNIQUE,
    parent_location_id UUID REFERENCES locations(id),
    child_location_id UUID REFERENCES locations(id),
    hierarchy_level INTEGER NOT NULL,
    hierarchy_path TEXT NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_parent_child UNIQUE(parent_location_id, child_location_id)
);

-- Site-specific settings from BDD line 20
CREATE TABLE location_configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_id VARCHAR(50) NOT NULL,
    location_id UUID NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
    
    -- Configuration parameters from BDD lines 49-55
    parameter_category VARCHAR(50) NOT NULL CHECK (parameter_category IN (
        'scheduling_rules', 'service_levels', 'resource_limits', 'integration_settings', 'reporting_preferences'
    )),
    parameter_name VARCHAR(100) NOT NULL,
    parameter_value JSONB NOT NULL,
    
    -- Inheritance from BDD lines 56-61
    inheritance_level VARCHAR(20) CHECK (inheritance_level IN (
        'corporate', 'regional', 'site', 'department'
    )),
    can_override BOOLEAN DEFAULT true,
    inherited_from UUID REFERENCES locations(id),
    
    effective_date DATE DEFAULT CURRENT_DATE,
    expiry_date DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_location_parameter UNIQUE(location_id, parameter_name, effective_date)
);

-- =============================================================================
-- 2. RESOURCE ALLOCATION MANAGEMENT
-- =============================================================================

-- Resource allocation from BDD line 21
CREATE TABLE location_resources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    resource_id VARCHAR(50) NOT NULL,
    location_id UUID NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
    
    resource_type VARCHAR(50) NOT NULL CHECK (resource_type IN (
        'employees', 'equipment', 'workstations', 'meeting_rooms', 'parking_spaces'
    )),
    resource_name VARCHAR(200) NOT NULL,
    
    -- Capacity management from BDD lines 26, 53
    total_capacity INTEGER NOT NULL DEFAULT 0,
    current_utilization INTEGER DEFAULT 0,
    utilization_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE WHEN total_capacity > 0 THEN (current_utilization::DECIMAL / total_capacity) * 100 ELSE 0 END
    ) STORED,
    
    status VARCHAR(20) DEFAULT 'available' CHECK (status IN (
        'available', 'in_use', 'maintenance', 'reserved', 'unavailable'
    )),
    
    -- Resource details
    specifications JSONB,
    maintenance_schedule JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_location_resource UNIQUE(location_id, resource_id)
);

-- =============================================================================
-- 3. EMPLOYEE LOCATION ASSIGNMENTS
-- =============================================================================

-- Employee assignments from BDD line 22
CREATE TABLE location_employee_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assignment_id VARCHAR(50) NOT NULL UNIQUE,
    employee_id UUID NOT NULL,
    location_id UUID NOT NULL REFERENCES locations(id),
    
    -- Assignment types from BDD lines 67-72
    assignment_type VARCHAR(20) NOT NULL CHECK (assignment_type IN (
        'primary', 'secondary', 'temporary', 'remote'
    )),
    
    start_date DATE NOT NULL,
    end_date DATE,
    role VARCHAR(100),
    
    -- Assignment validation from BDD lines 73-85
    is_active BOOLEAN DEFAULT true,
    capacity_impact INTEGER DEFAULT 1,
    required_skills TEXT[],
    security_clearance_level VARCHAR(20),
    
    -- Business rules enforcement
    transfer_request_id UUID,
    approval_status VARCHAR(20) DEFAULT 'approved' CHECK (approval_status IN (
        'pending', 'approved', 'rejected', 'cancelled'
    )),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_date_range CHECK (end_date IS NULL OR end_date >= start_date)
);

-- =============================================================================
-- 4. CROSS-SITE SCHEDULING COORDINATION
-- =============================================================================

-- Cross-site scheduling from BDD lines 87-100
CREATE TABLE cross_site_scheduling (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_coordination_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Coordination types from BDD lines 92-96
    coordination_type VARCHAR(30) NOT NULL CHECK (coordination_type IN (
        'timezone_management', 'resource_sharing', 'shift_coordination', 'holiday_management'
    )),
    
    primary_location_id UUID NOT NULL REFERENCES locations(id),
    secondary_location_ids UUID[], -- Array of related locations
    
    -- Timezone management from BDD line 93
    source_timezone VARCHAR(50),
    target_timezones VARCHAR(50)[],
    auto_conversion_enabled BOOLEAN DEFAULT true,
    
    -- Coordination rules
    coordination_rules JSONB NOT NULL DEFAULT '{}',
    synchronization_frequency VARCHAR(20) DEFAULT 'real_time',
    
    -- Travel time calculation from BDD line 100
    inter_site_travel_minutes JSONB, -- {"location1-location2": 45}
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 5. LOCATION-SPECIFIC CALENDARS AND HOLIDAYS
-- =============================================================================

-- Holiday management from BDD line 96
CREATE TABLE location_holidays (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_id UUID NOT NULL REFERENCES locations(id),
    
    holiday_name VARCHAR(200) NOT NULL,
    holiday_date DATE NOT NULL,
    holiday_type VARCHAR(30) CHECK (holiday_type IN (
        'national', 'regional', 'local', 'company'
    )),
    
    is_working_day BOOLEAN DEFAULT false,
    is_paid_holiday BOOLEAN DEFAULT true,
    
    -- Recurrence for annual holidays
    is_recurring BOOLEAN DEFAULT true,
    recurrence_rule VARCHAR(100), -- Annual, specific day of week, etc.
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_location_holiday UNIQUE(location_id, holiday_date)
);

-- =============================================================================
-- 6. DATA SYNCHRONIZATION MANAGEMENT
-- =============================================================================

-- Location data sync from BDD lines 30-36
CREATE TABLE location_data_synchronization (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sync_session_id UUID NOT NULL DEFAULT uuid_generate_v4(),
    
    -- Sync configuration from BDD lines 31-36
    sync_type VARCHAR(30) NOT NULL CHECK (sync_type IN (
        'real_time_events', 'batch_reporting', 'configuration_changes', 
        'employee_assignments', 'schedule_coordination'
    )),
    
    sync_schedule VARCHAR(50), -- immediate, hourly, daily, on-demand, every_15_minutes
    data_flow_direction VARCHAR(20) CHECK (data_flow_direction IN (
        'bi_directional', 'upward_aggregation', 'centralized_push', 
        'location_specific', 'cross_site_sync'
    )),
    
    source_location_id UUID REFERENCES locations(id),
    target_location_ids UUID[],
    
    -- Conflict resolution from BDD line 32
    conflict_resolution_strategy VARCHAR(30) CHECK (conflict_resolution_strategy IN (
        'timestamp_priority', 'master_site_priority', 'version_control', 
        'business_rules_validation', 'timezone_conversion'
    )),
    
    -- Sync status
    last_sync_timestamp TIMESTAMP WITH TIME ZONE,
    next_sync_timestamp TIMESTAMP WITH TIME ZONE,
    sync_status VARCHAR(20) DEFAULT 'pending',
    
    sync_log JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 7. LOCATION PERFORMANCE MONITORING
-- =============================================================================

-- Location performance tracking
CREATE TABLE location_performance_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_id UUID NOT NULL REFERENCES locations(id),
    
    metric_date DATE NOT NULL,
    
    -- Capacity utilization
    employee_capacity_utilization DECIMAL(5,2),
    resource_utilization DECIMAL(5,2),
    
    -- Operational metrics
    schedule_compliance_rate DECIMAL(5,2),
    cross_site_coordination_success_rate DECIMAL(5,2),
    
    -- Service levels
    response_time_ms INTEGER,
    quality_score DECIMAL(4,2),
    
    -- Cost metrics
    operational_cost DECIMAL(12,2),
    cost_per_employee DECIMAL(10,2),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_location_metric_date UNIQUE(location_id, metric_date)
);

-- =============================================================================
-- 8. LOCATION ACCESS CONTROL
-- =============================================================================

-- Security isolation from BDD line 28
CREATE TABLE location_access_control (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_id UUID NOT NULL REFERENCES locations(id),
    
    access_rule_name VARCHAR(200) NOT NULL,
    access_type VARCHAR(30) CHECK (access_type IN (
        'physical_access', 'data_access', 'system_access', 'administrative_access'
    )),
    
    -- Role-based permissions from BDD line 28
    required_roles TEXT[],
    required_clearance_level VARCHAR(20),
    
    -- Access restrictions
    allowed_time_ranges JSONB, -- {"monday": "08:00-18:00"}
    ip_restrictions INET[],
    
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Function to calculate hierarchy path
CREATE OR REPLACE FUNCTION calculate_location_hierarchy_path(p_location_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_path TEXT := '';
    v_current_id UUID := p_location_id;
    v_location RECORD;
BEGIN
    WHILE v_current_id IS NOT NULL LOOP
        SELECT location_code, parent_location_id INTO v_location
        FROM locations WHERE id = v_current_id;
        
        IF v_path = '' THEN
            v_path := v_location.location_code;
        ELSE
            v_path := v_location.location_code || '/' || v_path;
        END IF;
        
        v_current_id := v_location.parent_location_id;
    END LOOP;
    
    RETURN '/' || v_path;
END;
$$ LANGUAGE plpgsql;

-- Function to convert time between locations
CREATE OR REPLACE FUNCTION convert_time_between_locations(
    p_source_location_id UUID,
    p_target_location_id UUID,
    p_source_time TIMESTAMP WITH TIME ZONE
) RETURNS TIMESTAMP WITH TIME ZONE AS $$
DECLARE
    v_source_tz VARCHAR(50);
    v_target_tz VARCHAR(50);
    v_converted_time TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Get source timezone
    SELECT timezone INTO v_source_tz FROM locations WHERE id = p_source_location_id;
    
    -- Get target timezone  
    SELECT timezone INTO v_target_tz FROM locations WHERE id = p_target_location_id;
    
    -- Convert time
    v_converted_time := p_source_time AT TIME ZONE v_source_tz AT TIME ZONE v_target_tz;
    
    RETURN v_converted_time;
END;
$$ LANGUAGE plpgsql;

-- Function to validate employee assignment capacity
CREATE OR REPLACE FUNCTION validate_assignment_capacity(
    p_location_id UUID,
    p_assignment_date DATE,
    p_capacity_impact INTEGER DEFAULT 1
) RETURNS BOOLEAN AS $$
DECLARE
    v_total_capacity INTEGER;
    v_current_assignments INTEGER;
    v_available_capacity INTEGER;
BEGIN
    -- Get location capacity
    SELECT capacity INTO v_total_capacity FROM locations WHERE id = p_location_id;
    
    -- Count current assignments for the date
    SELECT COALESCE(SUM(capacity_impact), 0) INTO v_current_assignments
    FROM location_employee_assignments
    WHERE location_id = p_location_id
    AND start_date <= p_assignment_date
    AND (end_date IS NULL OR end_date >= p_assignment_date)
    AND is_active = true;
    
    v_available_capacity := v_total_capacity - v_current_assignments;
    
    RETURN v_available_capacity >= p_capacity_impact;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Trigger to maintain hierarchy path
CREATE OR REPLACE FUNCTION update_location_hierarchy_path()
RETURNS TRIGGER AS $$
BEGIN
    NEW.hierarchy_path = calculate_location_hierarchy_path(NEW.id);
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_location_hierarchy_trigger
    BEFORE INSERT OR UPDATE ON locations
    FOR EACH ROW
    EXECUTE FUNCTION update_location_hierarchy_path();

-- Trigger to validate assignment capacity
CREATE OR REPLACE FUNCTION validate_employee_assignment()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT validate_assignment_capacity(NEW.location_id, NEW.start_date, NEW.capacity_impact) THEN
        RAISE EXCEPTION 'Location capacity exceeded for assignment';
    END IF;
    
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_assignment_capacity_trigger
    BEFORE INSERT OR UPDATE ON location_employee_assignments
    FOR EACH ROW
    EXECUTE FUNCTION validate_employee_assignment();

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Location indexes
CREATE INDEX idx_locations_parent ON locations(parent_location_id);
CREATE INDEX idx_locations_status ON locations(status);
CREATE INDEX idx_locations_timezone ON locations(timezone);
CREATE INDEX idx_locations_hierarchy_path ON locations USING BTREE(hierarchy_path);

-- Configuration indexes
CREATE INDEX idx_location_config_location ON location_configurations(location_id);
CREATE INDEX idx_location_config_category ON location_configurations(parameter_category);
CREATE INDEX idx_location_config_inheritance ON location_configurations(inheritance_level);

-- Assignment indexes
CREATE INDEX idx_employee_assignments_location ON location_employee_assignments(location_id);
CREATE INDEX idx_employee_assignments_employee ON location_employee_assignments(employee_id);
CREATE INDEX idx_employee_assignments_type ON location_employee_assignments(assignment_type);
CREATE INDEX idx_employee_assignments_active ON location_employee_assignments(is_active);
CREATE INDEX idx_employee_assignments_dates ON location_employee_assignments(start_date, end_date);

-- Resource indexes
CREATE INDEX idx_location_resources_location ON location_resources(location_id);
CREATE INDEX idx_location_resources_type ON location_resources(resource_type);
CREATE INDEX idx_location_resources_status ON location_resources(status);

-- Performance indexes
CREATE INDEX idx_location_performance_location ON location_performance_metrics(location_id);
CREATE INDEX idx_location_performance_date ON location_performance_metrics(metric_date);

-- =============================================================================
-- INITIAL DATA
-- =============================================================================

-- Insert sample location hierarchy
INSERT INTO locations (location_id, location_name, location_code, timezone, capacity, status) VALUES
('corp-hq', 'Corporate Headquarters', 'HQ', 'Europe/Moscow', 500, 'active'),
('region-west', 'Western Region', 'WEST', 'Europe/Moscow', 200, 'active'),
('region-east', 'Eastern Region', 'EAST', 'Asia/Yekaterinburg', 150, 'active'),
('site-msk-01', 'Moscow Contact Center 1', 'MSK01', 'Europe/Moscow', 100, 'active'),
('site-spb-01', 'St. Petersburg Office', 'SPB01', 'Europe/Moscow', 75, 'active');

-- Update parent relationships
UPDATE locations SET parent_location_id = (SELECT id FROM locations WHERE location_code = 'HQ') 
WHERE location_code IN ('WEST', 'EAST');

UPDATE locations SET parent_location_id = (SELECT id FROM locations WHERE location_code = 'WEST') 
WHERE location_code IN ('MSK01', 'SPB01');

-- Insert default configurations
INSERT INTO location_configurations (config_id, location_id, parameter_category, parameter_name, parameter_value, inheritance_level) VALUES
('sched-001', (SELECT id FROM locations WHERE location_code = 'HQ'), 'scheduling_rules', 'default_break_duration', '{"minutes": 15}', 'corporate'),
('sched-002', (SELECT id FROM locations WHERE location_code = 'HQ'), 'scheduling_rules', 'max_shift_hours', '{"hours": 12}', 'corporate'),
('perf-001', (SELECT id FROM locations WHERE location_code = 'HQ'), 'service_levels', 'response_time_target', '{"seconds": 30}', 'corporate');

-- Insert holiday calendar
INSERT INTO location_holidays (location_id, holiday_name, holiday_date, holiday_type) VALUES
((SELECT id FROM locations WHERE location_code = 'HQ'), 'New Year', '2025-01-01', 'national'),
((SELECT id FROM locations WHERE location_code = 'HQ'), 'Orthodox Christmas', '2025-01-07', 'national'),
((SELECT id FROM locations WHERE location_code = 'HQ'), 'International Women''s Day', '2025-03-08', 'national');

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO wfm_site_manager;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO wfm_operator;