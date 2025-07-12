-- Basic schema setup for performance testing
-- Create minimal required tables

-- Queues table
CREATE TABLE IF NOT EXISTS queues (
    queue_id VARCHAR(255) PRIMARY KEY,
    queue_name VARCHAR(255) NOT NULL,
    queue_type VARCHAR(50) DEFAULT 'inbound',
    is_active BOOLEAN DEFAULT TRUE,
    max_concurrent_calls INTEGER DEFAULT 10,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Agents table
CREATE TABLE IF NOT EXISTS agents (
    agent_id VARCHAR(255) PRIMARY KEY,
    agent_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    employment_type VARCHAR(50) DEFAULT 'full_time',
    hire_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    max_concurrent_calls INTEGER DEFAULT 1,
    skill_level INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Contact statistics table (partitioned for performance)
CREATE TABLE IF NOT EXISTS contact_statistics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    interval_start TIMESTAMP WITH TIME ZONE NOT NULL,
    interval_end TIMESTAMP WITH TIME ZONE NOT NULL,
    queue_id VARCHAR(255) NOT NULL,
    offered_calls INTEGER DEFAULT 0,
    answered_calls INTEGER DEFAULT 0,
    abandoned_calls INTEGER DEFAULT 0,
    avg_handle_time INTEGER DEFAULT 0,
    avg_wait_time INTEGER DEFAULT 0,
    service_level_20s INTEGER DEFAULT 0,
    max_wait_time INTEGER DEFAULT 0,
    total_talk_time INTEGER DEFAULT 0,
    total_hold_time INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (queue_id) REFERENCES queues(queue_id)
);

-- Real-time queues table
CREATE TABLE IF NOT EXISTS realtime_queues (
    queue_id VARCHAR(255) PRIMARY KEY,
    queue_name VARCHAR(255) NOT NULL,
    queue_status VARCHAR(50) DEFAULT 'active',
    calls_waiting INTEGER DEFAULT 0,
    calls_in_progress INTEGER DEFAULT 0,
    agents_available INTEGER DEFAULT 0,
    agents_busy INTEGER DEFAULT 0,
    agents_unavailable INTEGER DEFAULT 0,
    longest_wait_time INTEGER DEFAULT 0,
    avg_wait_time INTEGER DEFAULT 0,
    service_level_current INTEGER DEFAULT 0,
    calls_today INTEGER DEFAULT 0,
    abandoned_today INTEGER DEFAULT 0,
    avg_handle_time_today INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (queue_id) REFERENCES queues(queue_id)
);

-- Real-time agents table
CREATE TABLE IF NOT EXISTS realtime_agents (
    agent_id VARCHAR(255) PRIMARY KEY,
    agent_name VARCHAR(255) NOT NULL,
    current_state VARCHAR(50) DEFAULT 'unavailable',
    current_queue_id VARCHAR(255),
    state_duration INTEGER DEFAULT 0,
    calls_today INTEGER DEFAULT 0,
    avg_handle_time_today INTEGER DEFAULT 0,
    last_call_end TIMESTAMP,
    next_break_time TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (agent_id) REFERENCES agents(agent_id),
    FOREIGN KEY (current_queue_id) REFERENCES queues(queue_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_contact_stats_queue_date ON contact_statistics(queue_id, interval_start);
CREATE INDEX IF NOT EXISTS idx_contact_stats_interval ON contact_statistics(interval_start);
CREATE INDEX IF NOT EXISTS idx_realtime_queues_status ON realtime_queues(queue_status);
CREATE INDEX IF NOT EXISTS idx_realtime_agents_state ON realtime_agents(current_state);
CREATE INDEX IF NOT EXISTS idx_realtime_agents_queue ON realtime_agents(current_queue_id);

-- Success message
SELECT 'Basic schema setup completed successfully' AS status;