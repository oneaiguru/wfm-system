-- =============================================================================
-- 043_system_administration_configuration.sql
-- EXACT BDD Implementation: System Administration and Configuration Management
-- =============================================================================
-- Version: 1.0
-- Created: 2025-07-12
-- Based on: 18-system-administration-configuration.feature (943 lines)
-- Purpose: Complete technical implementation for system administration, configuration, and infrastructure management
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. DATABASE INFRASTRUCTURE CONFIGURATION
-- =============================================================================

-- PostgreSQL database components from BDD lines 20-29
CREATE TABLE database_components (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    component_name VARCHAR(100) NOT NULL UNIQUE,
    component_purpose TEXT NOT NULL,
    database_type VARCHAR(50) DEFAULT 'PostgreSQL 10.x',
    
    -- Performance requirements from BDD lines 24-29
    performance_target VARCHAR(100),
    query_response_target_ms INTEGER DEFAULT 2000,
    
    -- Configuration settings
    configuration JSONB NOT NULL DEFAULT '{}',
    connection_parameters JSONB,
    
    -- Status and monitoring
    is_active BOOLEAN DEFAULT true,
    last_health_check TIMESTAMP WITH TIME ZONE,
    health_status VARCHAR(20) CHECK (health_status IN ('healthy', 'degraded', 'unhealthy')),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- PostgreSQL configuration parameters from BDD lines 30-38
CREATE TABLE postgresql_configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    component_id UUID REFERENCES database_components(id) ON DELETE CASCADE,
    
    -- Exact parameters from admin guide
    max_connections INTEGER DEFAULT 1000,
    shared_buffers VARCHAR(20) DEFAULT '4GB',
    effective_cache_size VARCHAR(20) DEFAULT '10GB',
    maintenance_work_mem VARCHAR(20) DEFAULT '2GB',
    checkpoint_completion_target DECIMAL(3,2) DEFAULT 0.9,
    wal_buffers VARCHAR(20) DEFAULT '16MB',
    work_mem VARCHAR(20) DEFAULT '393kB',
    
    -- Additional performance settings
    random_page_cost DECIMAL(4,2) DEFAULT 1.1,
    effective_io_concurrency INTEGER DEFAULT 200,
    min_wal_size VARCHAR(20) DEFAULT '1GB',
    max_wal_size VARCHAR(20) DEFAULT '4GB',
    
    -- Replication configuration from BDD lines 39-43
    replication_enabled BOOLEAN DEFAULT true,
    replication_type VARCHAR(50) DEFAULT 'streaming',
    hot_standby_enabled BOOLEAN DEFAULT true,
    wal_archiving_enabled BOOLEAN DEFAULT true,
    max_replication_lag_seconds INTEGER DEFAULT 1,
    
    configuration_active BOOLEAN DEFAULT true,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 2. RESOURCE CALCULATION AND SIZING
-- =============================================================================

-- Resource calculation formulas from BDD lines 46-61
CREATE TABLE resource_calculations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    calculation_name VARCHAR(200) NOT NULL,
    calculation_type VARCHAR(50) CHECK (calculation_type IN ('database', 'application_server', 'service')),
    
    -- Calculation formulas from BDD lines 50-55
    load_source VARCHAR(100) NOT NULL,
    cpu_calculation_formula TEXT NOT NULL,
    ram_calculation_formula TEXT NOT NULL,
    admin_guide_reference VARCHAR(50),
    
    -- Calculation parameters
    base_cpu_cores INTEGER DEFAULT 1,
    base_ram_gb INTEGER DEFAULT 2,
    scaling_factor DECIMAL(5,2) DEFAULT 1.0,
    
    -- Final calculation rules from BDD lines 56-61
    reduction_factor DECIMAL(3,2) DEFAULT 0.75,
    minimum_ram_gb INTEGER DEFAULT 8,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 3. DIRECTORY ORGANIZATION AND PERMISSIONS
-- =============================================================================

-- Directory structure from BDD lines 64-74
CREATE TABLE directory_organization (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    directory_path VARCHAR(255) NOT NULL UNIQUE,
    directory_purpose TEXT NOT NULL,
    admin_guide_section VARCHAR(50),
    
    -- Permissions from BDD lines 69-74
    owner_user VARCHAR(50) DEFAULT 'argus',
    owner_group VARCHAR(50) DEFAULT 'argus',
    permissions VARCHAR(10) DEFAULT '755',
    
    -- Directory metadata
    parent_directory VARCHAR(255),
    is_required BOOLEAN DEFAULT true,
    auto_create BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 4. CONNECTION POOL MANAGEMENT
-- =============================================================================

-- Connection pool configuration from BDD lines 82-90
CREATE TABLE connection_pool_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pool_name VARCHAR(100) NOT NULL UNIQUE,
    database_component_id UUID REFERENCES database_components(id),
    
    -- Pool parameters from BDD lines 86-90
    max_connections INTEGER DEFAULT 1000,
    queue_size_limit INTEGER DEFAULT 500,
    queue_timeout_seconds INTEGER DEFAULT 30,
    connection_timeout_seconds INTEGER DEFAULT 60,
    
    -- Peak hour configuration
    peak_hours_enabled BOOLEAN DEFAULT true,
    peak_max_connections INTEGER DEFAULT 1200,
    peak_start_hour INTEGER DEFAULT 8,
    peak_end_hour INTEGER DEFAULT 18,
    
    -- Idle management
    idle_timeout_seconds INTEGER DEFAULT 300,
    min_idle_connections INTEGER DEFAULT 10,
    
    -- Health check configuration from BDD lines 91-96
    health_check_enabled BOOLEAN DEFAULT true,
    health_check_interval_minutes INTEGER DEFAULT 5,
    deadlock_detection_enabled BOOLEAN DEFAULT true,
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Connection pool monitoring from BDD lines 91-102
CREATE TABLE connection_pool_monitoring (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pool_config_id UUID REFERENCES connection_pool_config(id),
    
    -- Real-time metrics
    current_connections INTEGER NOT NULL,
    queued_connections INTEGER DEFAULT 0,
    failed_connections INTEGER DEFAULT 0,
    
    -- Performance metrics
    avg_connection_time_ms INTEGER,
    max_connection_time_ms INTEGER,
    connection_latency_p95_ms INTEGER,
    
    -- Utilization tracking
    utilization_percentage DECIMAL(5,2),
    peak_utilization_percentage DECIMAL(5,2),
    
    -- Alert status from BDD lines 97-102
    alert_type VARCHAR(50),
    alert_threshold_exceeded BOOLEAN DEFAULT false,
    alert_sent_at TIMESTAMP WITH TIME ZONE,
    
    monitored_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 5. MASTER-SLAVE REPLICATION AND FAILOVER
-- =============================================================================

-- Master-slave configuration from BDD lines 104-125
CREATE TABLE replication_configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cluster_name VARCHAR(100) NOT NULL UNIQUE,
    
    -- Replication settings
    master_host VARCHAR(255) NOT NULL,
    master_port INTEGER DEFAULT 5432,
    slave_hosts JSONB NOT NULL DEFAULT '[]', -- Array of slave configurations
    
    -- Failover configuration from BDD lines 108-113
    automatic_failover_enabled BOOLEAN DEFAULT true,
    failure_detection_seconds INTEGER DEFAULT 30,
    slave_promotion_seconds INTEGER DEFAULT 60,
    connection_redirect_seconds INTEGER DEFAULT 90,
    data_consistency_check_seconds INTEGER DEFAULT 120,
    
    -- Data protection settings from BDD lines 114-119
    wal_replay_enabled BOOLEAN DEFAULT true,
    session_transfer_enabled BOOLEAN DEFAULT true,
    lock_preservation_enabled BOOLEAN DEFAULT true,
    index_consistency_check BOOLEAN DEFAULT true,
    
    -- Current status
    current_master VARCHAR(255),
    last_failover_at TIMESTAMP WITH TIME ZONE,
    failover_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Failover validation tracking from BDD lines 120-125
CREATE TABLE failover_validation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    replication_config_id UUID REFERENCES replication_configuration(id),
    failover_event_id UUID NOT NULL,
    
    -- Validation results
    data_integrity_check BOOLEAN,
    performance_check BOOLEAN,
    replication_sync_check BOOLEAN,
    application_health_check BOOLEAN,
    
    -- Metrics
    query_response_time_ms INTEGER,
    data_consistency_percentage DECIMAL(5,2),
    
    validation_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    validation_passed BOOLEAN DEFAULT false
);

-- =============================================================================
-- 6. APPLICATION SERVER CONFIGURATION
-- =============================================================================

-- WildFly configuration from BDD lines 130-145
CREATE TABLE application_server_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    server_name VARCHAR(100) NOT NULL UNIQUE,
    server_type VARCHAR(50) DEFAULT 'WildFly 10.1.0',
    
    -- Technical requirements from BDD lines 135-141
    operating_system_timezone VARCHAR(50) DEFAULT 'UTC',
    java_version VARCHAR(100) DEFAULT 'Oracle JDK 8 update 77',
    java_home_path VARCHAR(255) DEFAULT '/argus/jdk/jdk1.8.0_77',
    system_user VARCHAR(50) DEFAULT 'argus',
    system_locale VARCHAR(20) DEFAULT 'ru_RU.UTF-8',
    
    -- Resource limits
    file_limit INTEGER DEFAULT 100000,
    process_limit INTEGER DEFAULT 4000,
    
    -- JVM configuration
    jvm_startup_memory_mb INTEGER DEFAULT 2048,
    jvm_max_memory_mb INTEGER,
    
    -- Environment variables from BDD lines 142-145
    environment_variables JSONB DEFAULT '{}',
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Resource calculation tracking from BDD lines 148-170
CREATE TABLE application_resource_calculations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    server_config_id UUID REFERENCES application_server_config(id),
    module_name VARCHAR(100) NOT NULL,
    
    -- Calculation formulas from BDD lines 152-157
    resource_formula TEXT NOT NULL,
    base_memory_mb INTEGER,
    
    -- Variables from BDD lines 158-166
    historical_data_years INTEGER DEFAULT 2,
    forecast_data_years INTEGER DEFAULT 1,
    forecast_open_sessions INTEGER DEFAULT 5,
    schedule_worker_count INTEGER DEFAULT 1000,
    planning_open_sessions INTEGER DEFAULT 10,
    monitoring_group_count INTEGER DEFAULT 20,
    monitoring_open_sessions INTEGER DEFAULT 5,
    
    -- Calculated values
    calculated_memory_mb INTEGER NOT NULL,
    
    calculation_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 7. SERVICE CONFIGURATION AND DOCKER MANAGEMENT
-- =============================================================================

-- Docker service configuration from BDD lines 193-200
CREATE TABLE docker_service_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_name VARCHAR(100) NOT NULL UNIQUE,
    container_name VARCHAR(100) NOT NULL,
    
    -- Docker configuration
    docker_compose_file VARCHAR(255),
    env_file VARCHAR(255),
    
    -- Service parameters
    service_port INTEGER,
    exposed_ports JSONB DEFAULT '[]',
    environment_variables JSONB DEFAULT '{}',
    volumes JSONB DEFAULT '[]',
    
    -- Health check
    health_check_command TEXT,
    health_check_interval_seconds INTEGER DEFAULT 30,
    health_check_retries INTEGER DEFAULT 3,
    
    -- Status
    is_running BOOLEAN DEFAULT false,
    last_started_at TIMESTAMP WITH TIME ZONE,
    last_stopped_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 8. SYSTEM MONITORING AND ALERTS
-- =============================================================================

-- System monitoring configuration
CREATE TABLE system_monitoring_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    monitoring_type VARCHAR(50) NOT NULL CHECK (monitoring_type IN (
        'database', 'application_server', 'service', 'infrastructure'
    )),
    
    -- Monitoring parameters
    metric_name VARCHAR(100) NOT NULL,
    check_interval_seconds INTEGER DEFAULT 60,
    
    -- Thresholds
    warning_threshold DECIMAL(10,2),
    critical_threshold DECIMAL(10,2),
    
    -- Alert configuration
    alert_enabled BOOLEAN DEFAULT true,
    alert_channels JSONB DEFAULT '["email", "system"]',
    alert_recipients JSONB DEFAULT '[]',
    
    -- Escalation
    escalation_enabled BOOLEAN DEFAULT true,
    escalation_timeout_minutes INTEGER DEFAULT 30,
    escalation_team VARCHAR(100),
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- System performance metrics
CREATE TABLE system_performance_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_type VARCHAR(50) NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    
    -- Metric values
    metric_value DECIMAL(20,4) NOT NULL,
    metric_unit VARCHAR(20),
    
    -- Context
    component_type VARCHAR(50),
    component_id UUID,
    
    -- Timestamp
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexing for time-series queries
    CONSTRAINT system_metrics_time_idx UNIQUE (metric_type, metric_name, recorded_at)
);

-- =============================================================================
-- 9. BACKUP AND RECOVERY CONFIGURATION
-- =============================================================================

-- Backup configuration
CREATE TABLE backup_configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    backup_name VARCHAR(100) NOT NULL UNIQUE,
    backup_type VARCHAR(50) CHECK (backup_type IN (
        'full', 'incremental', 'differential', 'wal_archive'
    )),
    
    -- Schedule
    schedule_cron TEXT,
    retention_days INTEGER DEFAULT 30,
    
    -- Backup location
    backup_path VARCHAR(500) NOT NULL,
    remote_backup_enabled BOOLEAN DEFAULT false,
    remote_backup_config JSONB,
    
    -- Compression and encryption
    compression_enabled BOOLEAN DEFAULT true,
    encryption_enabled BOOLEAN DEFAULT true,
    encryption_key_id VARCHAR(100),
    
    -- Status
    last_backup_at TIMESTAMP WITH TIME ZONE,
    last_backup_size_mb BIGINT,
    last_backup_duration_seconds INTEGER,
    last_backup_status VARCHAR(20),
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Recovery procedures
CREATE TABLE recovery_procedures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    procedure_name VARCHAR(100) NOT NULL UNIQUE,
    procedure_type VARCHAR(50) CHECK (procedure_type IN (
        'point_in_time', 'full_restore', 'partial_restore', 'disaster_recovery'
    )),
    
    -- Procedure steps
    procedure_steps JSONB NOT NULL,
    estimated_duration_minutes INTEGER,
    
    -- Requirements
    required_backup_types JSONB DEFAULT '[]',
    minimum_backup_age_hours INTEGER DEFAULT 0,
    
    -- Validation
    validation_steps JSONB,
    rollback_procedure JSONB,
    
    -- Documentation
    documentation_url TEXT,
    last_tested_at TIMESTAMP WITH TIME ZONE,
    test_result VARCHAR(20),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 10. STARTUP AND SHUTDOWN PROCEDURES
-- =============================================================================

-- Operational procedures from BDD lines 172-188
CREATE TABLE operational_procedures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    procedure_name VARCHAR(100) NOT NULL,
    procedure_type VARCHAR(50) CHECK (procedure_type IN (
        'startup', 'shutdown', 'restart', 'health_check', 'diagnostic'
    )),
    component_type VARCHAR(50) NOT NULL,
    
    -- Command details from BDD lines 177-183
    command TEXT NOT NULL,
    expected_output TEXT,
    success_indicator TEXT,
    admin_guide_section VARCHAR(50),
    
    -- Execution parameters
    timeout_seconds INTEGER DEFAULT 300,
    retry_attempts INTEGER DEFAULT 3,
    
    -- Monitoring files from BDD lines 184-187
    log_file_path VARCHAR(500),
    error_log_path VARCHAR(500),
    
    -- Procedure metadata
    requires_sudo BOOLEAN DEFAULT false,
    requires_confirmation BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Function to calculate resource requirements
CREATE OR REPLACE FUNCTION calculate_resource_requirements(
    p_component_type VARCHAR,
    p_user_count INTEGER,
    p_session_count INTEGER
) RETURNS TABLE (
    cpu_cores INTEGER,
    ram_gb INTEGER,
    storage_gb INTEGER
) AS $$
DECLARE
    v_base_cpu INTEGER;
    v_base_ram INTEGER;
    v_cpu_per_unit INTEGER;
    v_ram_per_unit INTEGER;
    v_reduction_factor DECIMAL := 0.75;
BEGIN
    -- Get calculation formulas
    SELECT 
        base_cpu_cores,
        base_ram_gb,
        CASE 
            WHEN load_source = 'WFM CC AS' THEN 10 -- 1 core per 10 sessions
            WHEN load_source = 'Personal Cabinet Service' THEN 100 -- 1 core per 100 sessions
            ELSE 1
        END,
        CASE 
            WHEN load_source = 'WFM CC AS' THEN 4 -- 4GB per 10 sessions
            WHEN load_source = 'Personal Cabinet Service' THEN 4 -- 4GB per 100 sessions
            ELSE 2
        END
    INTO v_base_cpu, v_base_ram, v_cpu_per_unit, v_ram_per_unit
    FROM resource_calculations
    WHERE calculation_type = p_component_type
    LIMIT 1;
    
    -- Calculate requirements with reduction factor
    RETURN QUERY
    SELECT 
        GREATEST(
            CEIL((p_session_count::DECIMAL / v_cpu_per_unit) * v_reduction_factor)::INTEGER + 1,
            v_base_cpu
        ) AS cpu_cores,
        GREATEST(
            CEIL(((p_session_count::DECIMAL / v_cpu_per_unit) * v_ram_per_unit * v_reduction_factor * 1.5)::INTEGER + 2),
            8 -- Minimum 8GB
        ) AS ram_gb,
        CEIL(p_user_count::DECIMAL / 100) * 10 AS storage_gb;
END;
$$ LANGUAGE plpgsql;

-- Function to check connection pool health
CREATE OR REPLACE FUNCTION check_connection_pool_health(
    p_pool_name VARCHAR
) RETURNS TABLE (
    health_status VARCHAR,
    utilization_pct DECIMAL,
    alert_needed BOOLEAN,
    alert_message TEXT
) AS $$
DECLARE
    v_config RECORD;
    v_monitoring RECORD;
    v_utilization DECIMAL;
    v_alert_needed BOOLEAN := false;
    v_alert_message TEXT;
BEGIN
    -- Get pool configuration
    SELECT * INTO v_config
    FROM connection_pool_config
    WHERE pool_name = p_pool_name;
    
    -- Get latest monitoring data
    SELECT * INTO v_monitoring
    FROM connection_pool_monitoring
    WHERE pool_config_id = v_config.id
    ORDER BY monitored_at DESC
    LIMIT 1;
    
    -- Calculate utilization
    v_utilization := (v_monitoring.current_connections::DECIMAL / v_config.max_connections) * 100;
    
    -- Check alert conditions
    IF v_utilization > 95 THEN
        v_alert_needed := true;
        v_alert_message := 'Pool exhaustion alert: ' || v_utilization || '% utilized';
    ELSIF v_monitoring.avg_connection_time_ms > 60000 THEN
        v_alert_needed := true;
        v_alert_message := 'Connection timeout alert: avg time ' || v_monitoring.avg_connection_time_ms || 'ms';
    END IF;
    
    RETURN QUERY
    SELECT 
        CASE 
            WHEN v_utilization < 80 THEN 'healthy'
            WHEN v_utilization < 95 THEN 'degraded'
            ELSE 'unhealthy'
        END AS health_status,
        v_utilization AS utilization_pct,
        v_alert_needed AS alert_needed,
        v_alert_message AS alert_message;
END;
$$ LANGUAGE plpgsql;

-- Function to validate failover readiness
CREATE OR REPLACE FUNCTION validate_failover_readiness(
    p_cluster_name VARCHAR
) RETURNS TABLE (
    failover_ready BOOLEAN,
    validation_results JSONB,
    issues JSONB
) AS $$
DECLARE
    v_config RECORD;
    v_issues JSONB := '[]'::jsonb;
    v_results JSONB := '{}'::jsonb;
    v_ready BOOLEAN := true;
BEGIN
    -- Get replication configuration
    SELECT * INTO v_config
    FROM replication_configuration
    WHERE cluster_name = p_cluster_name;
    
    -- Check slave availability
    IF jsonb_array_length(v_config.slave_hosts) = 0 THEN
        v_ready := false;
        v_issues := v_issues || '["No slave hosts configured"]'::jsonb;
    END IF;
    
    -- Build validation results
    v_results := jsonb_build_object(
        'slaves_available', jsonb_array_length(v_config.slave_hosts),
        'automatic_failover', v_config.automatic_failover_enabled,
        'wal_replay', v_config.wal_replay_enabled,
        'last_failover', v_config.last_failover_at
    );
    
    RETURN QUERY
    SELECT v_ready, v_results, v_issues;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Trigger to update timestamps
CREATE OR REPLACE FUNCTION update_admin_config_timestamps()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_database_components_timestamp
    BEFORE UPDATE ON database_components
    FOR EACH ROW
    EXECUTE FUNCTION update_admin_config_timestamps();

CREATE TRIGGER update_connection_pool_config_timestamp
    BEFORE UPDATE ON connection_pool_config
    FOR EACH ROW
    EXECUTE FUNCTION update_admin_config_timestamps();

CREATE TRIGGER update_replication_config_timestamp
    BEFORE UPDATE ON replication_configuration
    FOR EACH ROW
    EXECUTE FUNCTION update_admin_config_timestamps();

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Database component indexes
CREATE INDEX idx_database_components_active ON database_components(is_active);
CREATE INDEX idx_database_components_health ON database_components(health_status);

-- Connection pool indexes
CREATE INDEX idx_connection_pool_monitoring_time ON connection_pool_monitoring(monitored_at DESC);
CREATE INDEX idx_connection_pool_monitoring_pool ON connection_pool_monitoring(pool_config_id);
CREATE INDEX idx_connection_pool_monitoring_alerts ON connection_pool_monitoring(alert_threshold_exceeded) 
    WHERE alert_threshold_exceeded = true;

-- Replication indexes
CREATE INDEX idx_replication_config_cluster ON replication_configuration(cluster_name);
CREATE INDEX idx_failover_validation_time ON failover_validation(validation_timestamp DESC);

-- Performance metrics indexes
CREATE INDEX idx_system_metrics_type_time ON system_performance_metrics(metric_type, recorded_at DESC);
CREATE INDEX idx_system_metrics_component ON system_performance_metrics(component_type, component_id);

-- Backup indexes
CREATE INDEX idx_backup_config_active ON backup_configuration(is_active);
CREATE INDEX idx_backup_config_last ON backup_configuration(last_backup_at DESC);

-- =============================================================================
-- INITIAL DATA
-- =============================================================================

-- Insert default database components
INSERT INTO database_components (component_name, component_purpose, performance_target, query_response_target_ms) VALUES
('WFM CC Database', 'Primary workforce data', '<2 sec query response', 2000),
('Integration Database', 'External system data', 'Real-time sync capability', 500),
('Planning Database', 'Schedule algorithms', 'Complex calculation support', 5000),
('Notifications Database', 'Alert management', 'High throughput messaging', 100),
('Reports Database', 'Reporting data', 'Large dataset analytics', 10000);

-- Insert resource calculation formulas
INSERT INTO resource_calculations (calculation_name, calculation_type, load_source, cpu_calculation_formula, ram_calculation_formula, admin_guide_reference) VALUES
('WFM CC AS', 'database', 'WFM CC AS', '1 core per 10 concurrent sessions', '4GB per 10 concurrent sessions', '2.1.1.1'),
('Personal Cabinet Service', 'database', 'Personal Cabinet Service', '1 core per 100 concurrent sessions', '4GB per 100 concurrent sessions', '2.1.1.1'),
('Integration Service', 'database', 'Integration Service', '1 core per integration', '2GB per integration', '2.1.1.1'),
('Reports Service', 'database', 'Reports Service', '1 core', '2GB', '2.1.1.1'),
('Mobile API Service', 'database', 'Mobile API Service', '1 core per 500 operators', '2GB per 500 operators', '2.1.1.1');

-- Insert directory organization
INSERT INTO directory_organization (directory_path, directory_purpose, admin_guide_section) VALUES
('/argus', 'Root directory for all components', '3.1.1.1'),
('/argus/distr', 'Database distributables and packages', '3.1.1.1'),
('/argus/nmon', 'NMON performance reports', '3.1.1.1'),
('/argus/scripts', 'Auxiliary scripts', '3.1.1.1'),
('/argus/tmp', 'Temporary files', '3.1.1.1'),
('/argus/pgdata', 'PostgreSQL data directory', 'Database specific');

-- Insert operational procedures
INSERT INTO operational_procedures (procedure_name, procedure_type, component_type, command, expected_output, admin_guide_section) VALUES
('Check Status', 'health_check', 'application_server', './runjboss.sh status', 'wildfly started (pid XXXX) or wildfly not started', '3.2.2.5'),
('Start Server', 'startup', 'application_server', './runjboss.sh start', 'Starting wildfly in default mode...', '3.2.2.5'),
('Stop Server', 'shutdown', 'application_server', './runjboss.sh stop', 'Stopping wildfly:Done.', '3.2.2.6'),
('Force Stop', 'shutdown', 'application_server', './runjboss.sh stop kill', 'Immediate termination', '3.2.2.6'),
('Create Heap Dump', 'diagnostic', 'application_server', './runjboss.sh heap-dump', 'Dump file in bin directory', '4.2.1.1'),
('Create Thread Dump', 'diagnostic', 'application_server', './runjboss.sh thread-dump', 'Thread analysis file', '4.2.1.1');

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- Grant appropriate permissions
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO wfm_admin;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO wfm_operator;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO wfm_admin;