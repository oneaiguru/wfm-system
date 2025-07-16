-- Schema 076: Multi-Site Location Management (BDD 21)
-- Complete location hierarchy and distributed operations support
-- Russian market ready with timezone and regional compliance

-- 1. Site Location Definitions
CREATE TABLE locations (
    location_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_code VARCHAR(50) UNIQUE NOT NULL,
    location_name VARCHAR(255) NOT NULL,
    location_name_ru VARCHAR(255), -- Russian name
    parent_location_id UUID REFERENCES locations(location_id),
    location_type VARCHAR(50), -- headquarters, region, branch, remote
    address_line1 VARCHAR(500),
    address_line2 VARCHAR(500),
    city VARCHAR(255),
    region VARCHAR(255), -- Oblast/Krai
    postal_code VARCHAR(20),
    country_code VARCHAR(2) DEFAULT 'RU',
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    timezone VARCHAR(50) NOT NULL, -- Europe/Moscow, Asia/Yekaterinburg
    status VARCHAR(50) DEFAULT 'active',
    operating_hours JSONB, -- {"monday": {"open": "09:00", "close": "18:00"}}
    capacity_employees INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Location Hierarchy with Materialized Path
CREATE TABLE location_hierarchy (
    hierarchy_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_location_id UUID REFERENCES locations(location_id),
    child_location_id UUID REFERENCES locations(location_id),
    hierarchy_level INTEGER NOT NULL,
    hierarchy_path TEXT, -- /root/region/branch
    is_direct_child BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(parent_location_id, child_location_id)
);

-- 3. Location-Specific Configurations
CREATE TABLE location_configurations (
    config_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_id UUID REFERENCES locations(location_id),
    parameter_category VARCHAR(100), -- scheduling, reporting, integration
    parameter_name VARCHAR(255) NOT NULL,
    parameter_value JSONB NOT NULL,
    parameter_type VARCHAR(50), -- string, number, boolean, json
    is_inherited BOOLEAN DEFAULT false,
    inherited_from UUID REFERENCES locations(location_id),
    effective_date DATE NOT NULL,
    expiration_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(location_id, parameter_name, effective_date)
);

-- 4. Location Resources and Capacity
CREATE TABLE location_resources (
    resource_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_id UUID REFERENCES locations(location_id),
    resource_type VARCHAR(100), -- workstation, equipment, room, parking
    resource_name VARCHAR(255),
    resource_code VARCHAR(50),
    capacity INTEGER,
    current_utilization INTEGER DEFAULT 0,
    status VARCHAR(50) DEFAULT 'available',
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Employee Location Assignments
CREATE TABLE location_employees (
    assignment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL, -- References employees table
    location_id UUID REFERENCES locations(location_id),
    assignment_type VARCHAR(50), -- primary, secondary, temporary, remote
    role VARCHAR(100), -- manager, supervisor, agent, support
    start_date DATE NOT NULL,
    end_date DATE,
    work_schedule_type VARCHAR(50), -- onsite, hybrid, remote
    desk_assignment VARCHAR(100),
    access_level VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255),
    CONSTRAINT valid_date_range CHECK (end_date IS NULL OR end_date > start_date)
);

-- 6. Cross-Site Scheduling Coordination
CREATE TABLE cross_site_scheduling (
    coordination_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    primary_location_id UUID REFERENCES locations(location_id),
    supporting_location_id UUID REFERENCES locations(location_id),
    coordination_type VARCHAR(50), -- coverage, overflow, backup
    schedule_date DATE NOT NULL,
    time_period VARCHAR(50), -- morning, afternoon, evening, night
    required_agents INTEGER,
    assigned_agents INTEGER DEFAULT 0,
    coordination_status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Location-Specific Holidays and Events
CREATE TABLE location_holidays (
    holiday_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_id UUID REFERENCES locations(location_id),
    holiday_date DATE NOT NULL,
    holiday_name VARCHAR(255),
    holiday_name_ru VARCHAR(255),
    holiday_type VARCHAR(50), -- national, regional, local
    is_working_day BOOLEAN DEFAULT false,
    reduced_hours JSONB, -- {"open": "10:00", "close": "16:00"}
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(location_id, holiday_date)
);

-- 8. Inter-Site Travel Configuration
CREATE TABLE inter_site_travel (
    travel_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    from_location_id UUID REFERENCES locations(location_id),
    to_location_id UUID REFERENCES locations(location_id),
    travel_time_minutes INTEGER NOT NULL,
    travel_distance_km DECIMAL(10,2),
    travel_cost_estimate DECIMAL(10,2),
    transportation_mode VARCHAR(50), -- car, public, company_shuttle
    is_bidirectional BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(from_location_id, to_location_id)
);

-- 9. Location Performance Metrics
CREATE TABLE location_performance_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_id UUID REFERENCES locations(location_id),
    metric_date DATE NOT NULL,
    metric_type VARCHAR(100), -- productivity, service_level, cost_efficiency
    metric_value DECIMAL(10,4),
    target_value DECIMAL(10,4),
    achievement_percent DECIMAL(5,2),
    aggregation_level VARCHAR(50), -- daily, weekly, monthly
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. Location Data Synchronization
CREATE TABLE location_sync_status (
    sync_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_id UUID REFERENCES locations(location_id),
    sync_type VARCHAR(50), -- config, employee, schedule, reporting
    last_sync_timestamp TIMESTAMP,
    next_sync_timestamp TIMESTAMP,
    sync_status VARCHAR(50),
    records_synced INTEGER,
    sync_errors INTEGER DEFAULT 0,
    error_details JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample Russian locations
INSERT INTO locations (location_code, location_name, location_name_ru, timezone, city, region, capacity_employees)
VALUES 
    ('MSK-HQ', 'Moscow Headquarters', 'Московский головной офис', 'Europe/Moscow', 'Москва', 'Москва', 500),
    ('SPB-01', 'St. Petersburg Branch', 'Санкт-Петербургский филиал', 'Europe/Moscow', 'Санкт-Петербург', 'Санкт-Петербург', 200),
    ('EKB-01', 'Yekaterinburg Office', 'Екатеринбургский офис', 'Asia/Yekaterinburg', 'Екатеринбург', 'Свердловская область', 150);

-- Create location hierarchy
INSERT INTO location_hierarchy (parent_location_id, child_location_id, hierarchy_level, hierarchy_path)
SELECT 
    p.location_id,
    c.location_id,
    1,
    '/' || p.location_code || '/' || c.location_code
FROM locations p
CROSS JOIN locations c
WHERE p.location_code = 'MSK-HQ' 
    AND c.location_code IN ('SPB-01', 'EKB-01');

-- Add location configurations
INSERT INTO location_configurations (location_id, parameter_category, parameter_name, parameter_value, effective_date)
SELECT 
    location_id,
    'scheduling',
    'standard_shift_hours',
    '{"start": "09:00", "end": "18:00", "break_minutes": 60}'::jsonb,
    CURRENT_DATE
FROM locations;

-- Create indexes for performance
CREATE INDEX idx_locations_parent ON locations(parent_location_id);
CREATE INDEX idx_location_employees_location ON location_employees(location_id);
CREATE INDEX idx_location_employees_employee ON location_employees(employee_id);
CREATE INDEX idx_location_configs_location ON location_configurations(location_id);
CREATE INDEX idx_location_sync_status ON location_sync_status(location_id, sync_type);

-- Verify multi-site tables
SELECT COUNT(*) as multi_site_tables FROM information_schema.tables 
WHERE table_name LIKE 'location%' OR table_name LIKE 'cross_site%' OR table_name LIKE 'inter_site%';