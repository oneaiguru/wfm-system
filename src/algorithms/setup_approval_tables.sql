-- Approval Workflow Tables Setup
-- Required for approval_workflow_manager.py

-- Create approval tasks table
CREATE TABLE IF NOT EXISTS approval_tasks (
    task_id VARCHAR(255) PRIMARY KEY,
    object_name VARCHAR(255) NOT NULL,
    task_type VARCHAR(100) NOT NULL,
    process_name VARCHAR(100) NOT NULL,
    current_stage VARCHAR(50) NOT NULL,
    assigned_to INTEGER NOT NULL,
    priority VARCHAR(20) DEFAULT 'medium',
    created_date TIMESTAMPTZ DEFAULT NOW(),
    due_date TIMESTAMPTZ NOT NULL,
    updated_date TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'
);

-- Create approval actions log
CREATE TABLE IF NOT EXISTS approval_actions (
    id SERIAL PRIMARY KEY,
    task_id VARCHAR(255) REFERENCES approval_tasks(task_id),
    employee_id INTEGER NOT NULL,
    action VARCHAR(50) NOT NULL,
    comments TEXT,
    created_date TIMESTAMPTZ DEFAULT NOW()
);

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    created_date TIMESTAMPTZ DEFAULT NOW(),
    is_read BOOLEAN DEFAULT FALSE
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_approval_tasks_assigned_to ON approval_tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_approval_tasks_stage ON approval_tasks(current_stage);
CREATE INDEX IF NOT EXISTS idx_approval_actions_task_id ON approval_actions(task_id);
CREATE INDEX IF NOT EXISTS idx_notifications_employee ON notifications(employee_id);

-- Insert demo data if tables are empty
DO $$
BEGIN
    -- Only insert if approval_tasks is empty
    IF NOT EXISTS (SELECT 1 FROM approval_tasks LIMIT 1) THEN
        INSERT INTO approval_tasks (
            task_id, object_name, task_type, process_name,
            current_stage, assigned_to, priority, due_date, metadata
        ) VALUES (
            'demo_schedule_approval_001',
            'Schedule Q1 2025',
            'Schedule variant',
            'Schedule approval',
            'supervisor_review',
            111538,
            'medium',
            NOW() + INTERVAL '2 days',
            '{"schedule_id": "demo_001", "initiator_id": 111538}'
        );
    END IF;
END $$;