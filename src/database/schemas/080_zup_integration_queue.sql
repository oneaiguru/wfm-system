-- =============================================================================
-- 080_zup_integration_queue.sql
-- 1C ZUP Integration Queue System
-- =============================================================================
-- Purpose: Handles all asynchronous integration operations with 1C ZUP system
-- Features: Queue processing, retry logic, status tracking, error handling
-- Created: 2025-07-15
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1C ZUP INTEGRATION QUEUE
-- =============================================================================

-- Main integration queue table for managing 1C ZUP operations
CREATE TABLE zup_integration_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Queue identification
    operation_type VARCHAR(50) NOT NULL CHECK (operation_type IN (
        'personnel_sync', 'schedule_upload', 'timesheet_request', 
        'vacation_export', 'time_norm_calculation', 'document_creation',
        'employee_data_sync', 'payroll_export', 'absence_sync'
    )),
    
    -- Operation data
    operation_data JSONB NOT NULL DEFAULT '{}',
    employee_id VARCHAR(100), -- Optional: specific employee for operation
    period_start DATE, -- Optional: period-based operations
    period_end DATE, -- Optional: period-based operations
    
    -- Queue processing status
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending', 'processing', 'completed', 'failed', 'retry_scheduled'
    )),
    
    -- Priority handling (1=highest, 10=lowest)
    priority INTEGER DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
    
    -- Retry mechanism
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    retry_delay_seconds INTEGER DEFAULT 60, -- Exponential backoff base
    next_retry_at TIMESTAMP WITH TIME ZONE,
    
    -- Error handling
    error_message TEXT,
    error_details JSONB,
    last_error_at TIMESTAMP WITH TIME ZONE,
    
    -- Processing tracking
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP WITH TIME ZONE,
    processed_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Processing metadata
    processing_node VARCHAR(100), -- Which server/process is handling
    session_id UUID, -- Link to operation session
    parent_operation_id UUID, -- For dependent operations
    
    -- 1C ZUP specific fields
    zup_document_id VARCHAR(100), -- 1C document reference
    zup_response JSONB, -- Full 1C response
    api_endpoint VARCHAR(200), -- Specific 1C API endpoint used
    
    -- Performance tracking
    processing_duration_ms INTEGER,
    api_response_time_ms INTEGER,
    
    -- Audit trail
    created_by VARCHAR(100) DEFAULT 'system',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- QUEUE PROCESSING HISTORY
-- =============================================================================

-- Archive completed queue operations for audit and analysis
CREATE TABLE zup_integration_queue_history (
    id UUID PRIMARY KEY,
    operation_type VARCHAR(50) NOT NULL,
    operation_data JSONB,
    employee_id VARCHAR(100),
    period_start DATE,
    period_end DATE,
    
    -- Final status
    final_status VARCHAR(20) NOT NULL,
    retry_count INTEGER,
    
    -- Error information
    error_message TEXT,
    error_details JSONB,
    
    -- Timing data
    created_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    total_duration_ms INTEGER,
    
    -- 1C integration details
    zup_document_id VARCHAR(100),
    zup_response JSONB,
    api_endpoint VARCHAR(200),
    
    -- Archive metadata
    archived_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    archive_reason VARCHAR(50) DEFAULT 'completed'
);

-- =============================================================================
-- QUEUE STATISTICS
-- =============================================================================

-- Real-time queue performance metrics
CREATE TABLE zup_queue_statistics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Time period
    stats_date DATE NOT NULL DEFAULT CURRENT_DATE,
    stats_hour INTEGER, -- NULL for daily stats, 0-23 for hourly
    
    -- Operation counts by type
    operation_type VARCHAR(50),
    
    -- Status distribution
    pending_count INTEGER DEFAULT 0,
    processing_count INTEGER DEFAULT 0,
    completed_count INTEGER DEFAULT 0,
    failed_count INTEGER DEFAULT 0,
    retry_count INTEGER DEFAULT 0,
    
    -- Performance metrics
    avg_processing_time_ms INTEGER,
    min_processing_time_ms INTEGER,
    max_processing_time_ms INTEGER,
    avg_api_response_time_ms INTEGER,
    
    -- Error rate
    success_rate_percent DECIMAL(5,2),
    error_rate_percent DECIMAL(5,2),
    
    -- Queue health
    max_queue_depth INTEGER,
    avg_queue_depth INTEGER,
    
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_stats_period UNIQUE(stats_date, stats_hour, operation_type)
);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Function to add operation to queue with validation
CREATE OR REPLACE FUNCTION enqueue_zup_operation(
    p_operation_type VARCHAR,
    p_operation_data JSONB,
    p_employee_id VARCHAR DEFAULT NULL,
    p_period_start DATE DEFAULT NULL,
    p_period_end DATE DEFAULT NULL,
    p_priority INTEGER DEFAULT 5
) RETURNS UUID AS $$
DECLARE
    v_queue_id UUID;
    v_delay_seconds INTEGER;
BEGIN
    -- Validate operation type
    IF p_operation_type NOT IN (
        'personnel_sync', 'schedule_upload', 'timesheet_request', 
        'vacation_export', 'time_norm_calculation', 'document_creation',
        'employee_data_sync', 'payroll_export', 'absence_sync'
    ) THEN
        RAISE EXCEPTION 'Invalid operation type: %', p_operation_type;
    END IF;
    
    -- Insert into queue
    INSERT INTO zup_integration_queue (
        operation_type, operation_data, employee_id,
        period_start, period_end, priority
    ) VALUES (
        p_operation_type, p_operation_data, p_employee_id,
        p_period_start, p_period_end, p_priority
    ) RETURNING id INTO v_queue_id;
    
    RETURN v_queue_id;
END;
$$ LANGUAGE plpgsql;

-- Function to get next operation for processing
CREATE OR REPLACE FUNCTION dequeue_zup_operation(
    p_processing_node VARCHAR DEFAULT 'default'
) RETURNS TABLE (
    queue_id UUID,
    operation_type VARCHAR,
    operation_data JSONB,
    employee_id VARCHAR,
    period_start DATE,
    period_end DATE,
    retry_count INTEGER
) AS $$
DECLARE
    v_queue_record RECORD;
BEGIN
    -- Get highest priority pending operation
    SELECT * INTO v_queue_record
    FROM zup_integration_queue 
    WHERE status IN ('pending', 'retry_scheduled')
      AND (next_retry_at IS NULL OR next_retry_at <= CURRENT_TIMESTAMP)
    ORDER BY priority ASC, created_at ASC
    LIMIT 1
    FOR UPDATE SKIP LOCKED;
    
    -- If found, mark as processing
    IF v_queue_record.id IS NOT NULL THEN
        UPDATE zup_integration_queue 
        SET status = 'processing',
            started_at = CURRENT_TIMESTAMP,
            processing_node = p_processing_node,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_queue_record.id;
        
        -- Return the operation details
        RETURN QUERY
        SELECT 
            v_queue_record.id,
            v_queue_record.operation_type,
            v_queue_record.operation_data,
            v_queue_record.employee_id,
            v_queue_record.period_start,
            v_queue_record.period_end,
            v_queue_record.retry_count;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to mark operation as completed
CREATE OR REPLACE FUNCTION complete_zup_operation(
    p_queue_id UUID,
    p_zup_response JSONB DEFAULT NULL,
    p_zup_document_id VARCHAR DEFAULT NULL,
    p_api_response_time_ms INTEGER DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_started_at TIMESTAMP WITH TIME ZONE;
    v_duration_ms INTEGER;
BEGIN
    -- Get start time for duration calculation
    SELECT started_at INTO v_started_at
    FROM zup_integration_queue
    WHERE id = p_queue_id;
    
    -- Calculate duration
    IF v_started_at IS NOT NULL THEN
        v_duration_ms := EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_started_at)) * 1000;
    END IF;
    
    -- Update queue record
    UPDATE zup_integration_queue 
    SET status = 'completed',
        processed_at = CURRENT_TIMESTAMP,
        completed_at = CURRENT_TIMESTAMP,
        zup_response = p_zup_response,
        zup_document_id = p_zup_document_id,
        api_response_time_ms = p_api_response_time_ms,
        processing_duration_ms = v_duration_ms,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_queue_id
      AND status = 'processing';
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Function to mark operation as failed with retry logic
CREATE OR REPLACE FUNCTION fail_zup_operation(
    p_queue_id UUID,
    p_error_message TEXT,
    p_error_details JSONB DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_operation RECORD;
    v_next_retry TIMESTAMP WITH TIME ZONE;
    v_delay_seconds INTEGER;
BEGIN
    -- Get current operation details
    SELECT retry_count, max_retries, retry_delay_seconds
    INTO v_operation
    FROM zup_integration_queue
    WHERE id = p_queue_id;
    
    -- Check if retry is possible
    IF v_operation.retry_count < v_operation.max_retries THEN
        -- Calculate exponential backoff delay
        v_delay_seconds := v_operation.retry_delay_seconds * POWER(2, v_operation.retry_count);
        v_next_retry := CURRENT_TIMESTAMP + (v_delay_seconds || ' seconds')::INTERVAL;
        
        -- Schedule retry
        UPDATE zup_integration_queue 
        SET status = 'retry_scheduled',
            retry_count = retry_count + 1,
            error_message = p_error_message,
            error_details = p_error_details,
            last_error_at = CURRENT_TIMESTAMP,
            next_retry_at = v_next_retry,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = p_queue_id;
    ELSE
        -- Mark as permanently failed
        UPDATE zup_integration_queue 
        SET status = 'failed',
            error_message = p_error_message,
            error_details = p_error_details,
            last_error_at = CURRENT_TIMESTAMP,
            processed_at = CURRENT_TIMESTAMP,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = p_queue_id;
    END IF;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Function to archive completed operations
CREATE OR REPLACE FUNCTION archive_completed_queue_operations(
    p_retention_days INTEGER DEFAULT 7
) RETURNS INTEGER AS $$
DECLARE
    v_archived_count INTEGER;
    v_cutoff_date TIMESTAMP WITH TIME ZONE;
BEGIN
    v_cutoff_date := CURRENT_TIMESTAMP - (p_retention_days || ' days')::INTERVAL;
    
    -- Move completed operations to history
    WITH archived_ops AS (
        DELETE FROM zup_integration_queue
        WHERE status IN ('completed', 'failed')
          AND completed_at < v_cutoff_date
        RETURNING *
    )
    INSERT INTO zup_integration_queue_history (
        id, operation_type, operation_data, employee_id,
        period_start, period_end, final_status, retry_count,
        error_message, error_details, created_at, completed_at,
        total_duration_ms, zup_document_id, zup_response, api_endpoint
    )
    SELECT 
        id, operation_type, operation_data, employee_id,
        period_start, period_end, status, retry_count,
        error_message, error_details, created_at, completed_at,
        processing_duration_ms, zup_document_id, zup_response, api_endpoint
    FROM archived_ops;
    
    GET DIAGNOSTICS v_archived_count = ROW_COUNT;
    RETURN v_archived_count;
END;
$$ LANGUAGE plpgsql;

-- Function to update queue statistics
CREATE OR REPLACE FUNCTION update_queue_statistics() RETURNS VOID AS $$
BEGIN
    -- Daily statistics by operation type
    INSERT INTO zup_queue_statistics (
        stats_date, operation_type,
        pending_count, processing_count, completed_count, failed_count, retry_count,
        avg_processing_time_ms, min_processing_time_ms, max_processing_time_ms,
        success_rate_percent, error_rate_percent
    )
    SELECT 
        CURRENT_DATE,
        operation_type,
        COUNT(*) FILTER (WHERE status = 'pending'),
        COUNT(*) FILTER (WHERE status = 'processing'),
        COUNT(*) FILTER (WHERE status = 'completed'),
        COUNT(*) FILTER (WHERE status = 'failed'),
        COUNT(*) FILTER (WHERE status = 'retry_scheduled'),
        AVG(processing_duration_ms) FILTER (WHERE processing_duration_ms IS NOT NULL),
        MIN(processing_duration_ms) FILTER (WHERE processing_duration_ms IS NOT NULL),
        MAX(processing_duration_ms) FILTER (WHERE processing_duration_ms IS NOT NULL),
        ROUND(
            COUNT(*) FILTER (WHERE status = 'completed') * 100.0 / 
            NULLIF(COUNT(*) FILTER (WHERE status IN ('completed', 'failed')), 0), 
            2
        ),
        ROUND(
            COUNT(*) FILTER (WHERE status = 'failed') * 100.0 / 
            NULLIF(COUNT(*) FILTER (WHERE status IN ('completed', 'failed')), 0), 
            2
        )
    FROM zup_integration_queue
    WHERE DATE(created_at) = CURRENT_DATE
    GROUP BY operation_type
    ON CONFLICT (stats_date, stats_hour, operation_type) 
    DO UPDATE SET
        pending_count = EXCLUDED.pending_count,
        processing_count = EXCLUDED.processing_count,
        completed_count = EXCLUDED.completed_count,
        failed_count = EXCLUDED.failed_count,
        retry_count = EXCLUDED.retry_count,
        avg_processing_time_ms = EXCLUDED.avg_processing_time_ms,
        min_processing_time_ms = EXCLUDED.min_processing_time_ms,
        max_processing_time_ms = EXCLUDED.max_processing_time_ms,
        success_rate_percent = EXCLUDED.success_rate_percent,
        error_rate_percent = EXCLUDED.error_rate_percent,
        last_updated = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Trigger to update timestamps
CREATE OR REPLACE FUNCTION update_queue_timestamps()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_zup_queue_timestamp
    BEFORE UPDATE ON zup_integration_queue
    FOR EACH ROW
    EXECUTE FUNCTION update_queue_timestamps();

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Queue processing indexes
CREATE INDEX idx_zup_queue_status_priority ON zup_integration_queue(status, priority, created_at);
CREATE INDEX idx_zup_queue_retry_schedule ON zup_integration_queue(status, next_retry_at) 
    WHERE status = 'retry_scheduled';
CREATE INDEX idx_zup_queue_processing ON zup_integration_queue(status, started_at) 
    WHERE status = 'processing';

-- Operation lookup indexes
CREATE INDEX idx_zup_queue_operation_type ON zup_integration_queue(operation_type);
CREATE INDEX idx_zup_queue_employee ON zup_integration_queue(employee_id);
CREATE INDEX idx_zup_queue_period ON zup_integration_queue(period_start, period_end);
CREATE INDEX idx_zup_queue_session ON zup_integration_queue(session_id);

-- Performance analysis indexes
CREATE INDEX idx_zup_queue_completion ON zup_integration_queue(completed_at DESC) 
    WHERE status = 'completed';
CREATE INDEX idx_zup_queue_errors ON zup_integration_queue(last_error_at DESC) 
    WHERE status = 'failed';

-- History table indexes
CREATE INDEX idx_zup_queue_history_date ON zup_integration_queue_history(completed_at DESC);
CREATE INDEX idx_zup_queue_history_type ON zup_integration_queue_history(operation_type);

-- Statistics indexes
CREATE INDEX idx_zup_queue_stats_date ON zup_queue_statistics(stats_date DESC);

-- =============================================================================
-- INITIAL DATA AND CONFIGURATION
-- =============================================================================

-- Insert sample queue operations for testing
INSERT INTO zup_integration_queue (operation_type, operation_data, priority) VALUES
('personnel_sync', '{"sync_type": "full", "department": "call_center"}', 2),
('schedule_upload', '{"period": "2025-07", "employees": ["EMP001", "EMP002"]}', 3),
('timesheet_request', '{"employee": "EMP001", "month": "2025-07"}', 4);

-- Create queue monitoring view
CREATE OR REPLACE VIEW v_zup_queue_monitor AS
SELECT 
    q.id,
    q.operation_type,
    q.status,
    q.priority,
    q.retry_count,
    q.error_message,
    q.created_at,
    q.started_at,
    q.next_retry_at,
    CASE 
        WHEN q.status = 'processing' THEN 
            EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - q.started_at))
        ELSE NULL 
    END as processing_duration_seconds,
    q.employee_id,
    q.processing_node
FROM zup_integration_queue q
ORDER BY q.priority ASC, q.created_at ASC;

-- Create queue health summary view
CREATE OR REPLACE VIEW v_zup_queue_health AS
SELECT 
    COUNT(*) as total_operations,
    COUNT(*) FILTER (WHERE status = 'pending') as pending,
    COUNT(*) FILTER (WHERE status = 'processing') as processing,
    COUNT(*) FILTER (WHERE status = 'completed') as completed,
    COUNT(*) FILTER (WHERE status = 'failed') as failed,
    COUNT(*) FILTER (WHERE status = 'retry_scheduled') as retry_scheduled,
    AVG(processing_duration_ms) FILTER (WHERE processing_duration_ms IS NOT NULL) as avg_processing_ms,
    MAX(retry_count) as max_retries,
    COUNT(*) FILTER (WHERE last_error_at > CURRENT_TIMESTAMP - INTERVAL '1 hour') as errors_last_hour
FROM zup_integration_queue;

-- =============================================================================
-- COMMENTS FOR API CONTRACTS
-- =============================================================================

COMMENT ON TABLE zup_integration_queue IS 
'Main queue for managing asynchronous 1C ZUP integration operations with retry logic and error handling';

COMMENT ON COLUMN zup_integration_queue.operation_type IS 
'Type of 1C ZUP operation: personnel_sync, schedule_upload, timesheet_request, etc.';

COMMENT ON COLUMN zup_integration_queue.status IS 
'Current processing status with transitions: pending → processing → completed/failed';

COMMENT ON COLUMN zup_integration_queue.retry_count IS 
'Number of retry attempts (max 3 by default with exponential backoff)';

COMMENT ON COLUMN zup_integration_queue.priority IS 
'Operation priority (1=highest, 10=lowest) for queue processing order';

COMMENT ON FUNCTION enqueue_zup_operation IS 
'Adds new operation to integration queue with validation and priority';

COMMENT ON FUNCTION dequeue_zup_operation IS 
'Gets next operation for processing with locking to prevent conflicts';

COMMENT ON FUNCTION complete_zup_operation IS 
'Marks operation as completed and records 1C ZUP response data';

COMMENT ON FUNCTION fail_zup_operation IS 
'Handles operation failures with automatic retry scheduling or permanent failure';