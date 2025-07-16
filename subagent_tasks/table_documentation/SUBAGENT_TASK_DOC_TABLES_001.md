# 📋 SUBAGENT TASK: Table Documentation Batch 001

## 🎯 Task Information
- **Task ID**: DOC_TABLES_001
- **Priority**: High
- **Estimated Time**: 20 minutes
- **Dependencies**: None

## 📊 Assigned Tables

You are responsible for documenting these 4 tables with API contracts:

1. **access_control_lists**
2. **access_logs**  
3. **access_permissions**
4. **account_settings**

## 📝 Execution Steps

### Step 1: Check Current State
```bash
psql -U postgres -d wfm_enterprise -c "
SELECT 
    relname as table_name,
    obj_description(oid, 'pg_class') as current_comment
FROM pg_class 
WHERE relname IN ('access_control_lists', 'access_logs', 'access_permissions', 'account_settings')
ORDER BY relname;"
```

### Step 2: Apply API Contracts

Execute these commands in order:

#### Table 1: access_control_lists
```sql
COMMENT ON TABLE access_control_lists IS 
'API Contract: GET /api/v1/access-control-lists
params: {user_id?: UUID, resource_type?: string}
returns: [{id: UUID, resource_id: UUID, resource_type: string, permissions: array}]

Helper Queries:
-- Get ACL for user
SELECT 
    acl.id::text as id,
    acl.resource_id::text as resource_id,
    acl.resource_type,
    array_agg(p.permission_name) as permissions
FROM access_control_lists acl
JOIN access_permissions p ON p.acl_id = acl.id
WHERE acl.user_id = $1
GROUP BY acl.id;

-- Create new ACL entry
INSERT INTO access_control_lists (user_id, resource_id, resource_type)
VALUES ($1, $2, $3)
RETURNING id, created_at;';
```

#### Table 2: access_logs
```sql
COMMENT ON TABLE access_logs IS
'API Contract: GET /api/v1/access-logs
params: {user_id?: UUID, date_from?: YYYY-MM-DD, date_to?: YYYY-MM-DD, limit?: int}
returns: [{id: UUID, user_id: UUID, action: string, resource: string, timestamp: ISO8601, ip_address: string}]

Helper Queries:
-- Get recent access logs
SELECT 
    id::text as id,
    user_id::text as user_id,
    action,
    resource,
    timestamp::text as timestamp,
    ip_address::inet::text as ip_address
FROM access_logs
WHERE ($1::uuid IS NULL OR user_id = $1)
    AND ($2::date IS NULL OR timestamp >= $2)
    AND ($3::date IS NULL OR timestamp <= $3)
ORDER BY timestamp DESC
LIMIT COALESCE($4, 100);';
```

#### Table 3: access_permissions
```sql
COMMENT ON TABLE access_permissions IS
'API Contract: GET /api/v1/access-permissions
returns: [{id: UUID, permission_name: string, permission_code: string, description: string}]

Helper Queries:
-- Get all permissions
SELECT 
    id::text as id,
    permission_name,
    permission_code,
    description
FROM access_permissions
WHERE is_active = true
ORDER BY permission_name;

-- Check user permission
SELECT EXISTS(
    SELECT 1 
    FROM access_permissions ap
    JOIN access_control_lists acl ON ap.acl_id = acl.id
    WHERE acl.user_id = $1 
    AND ap.permission_code = $2
) as has_permission;';
```

#### Table 4: account_settings
```sql
COMMENT ON TABLE account_settings IS
'API Contract: GET /api/v1/users/{user_id}/settings
returns: {user_id: UUID, settings: json, updated_at: timestamp}

PUT /api/v1/users/{user_id}/settings
expects: {settings: json}
returns: {user_id: UUID, settings: json, updated_at: timestamp}

Helper Queries:
-- Get user settings
SELECT 
    user_id::text as user_id,
    settings,
    updated_at
FROM account_settings
WHERE user_id = $1;

-- Update settings
INSERT INTO account_settings (user_id, settings, updated_at)
VALUES ($1, $2, NOW())
ON CONFLICT (user_id) 
DO UPDATE SET settings = $2, updated_at = NOW()
RETURNING user_id, settings, updated_at;';
```

### Step 3: Create Test Data
```sql
-- Insert test data for access_control_lists
INSERT INTO access_control_lists (user_id, resource_id, resource_type)
SELECT 
    e.id as user_id,
    gen_random_uuid() as resource_id,
    'report' as resource_type
FROM employees e
WHERE e.first_name = 'Иван'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Insert test permission
INSERT INTO access_permissions (acl_id, permission_name, permission_code)
SELECT 
    acl.id,
    'View Report',
    'report.view'
FROM access_control_lists acl
LIMIT 1
ON CONFLICT DO NOTHING;
```

### Step 4: Verify Success
```bash
psql -U postgres -d wfm_enterprise -c "
SELECT 
    relname as table_name,
    CASE 
        WHEN obj_description(oid, 'pg_class') LIKE 'API Contract:%' 
        THEN '✅ Documented'
        ELSE '❌ Missing'
    END as status
FROM pg_class 
WHERE relname IN ('access_control_lists', 'access_logs', 'access_permissions', 'account_settings')
ORDER BY relname;"
```

## ✅ Success Criteria

All of the following must be true:
- [ ] All 4 tables have API contract comments
- [ ] Helper queries are included in comments
- [ ] Test data exists for at least one table
- [ ] Verification query shows ✅ for all tables

## 📊 Progress Update

When complete, update the master progress file:
```bash
echo "DOC_TABLES_001: Complete - 4 tables documented" >> /project/subagent_tasks/progress_tracking/completed.log
```

## 🚨 Troubleshooting

If a table doesn't exist:
- Mark as "N/A - Table not found"
- Continue with remaining tables

If permission denied:
- Use `sudo -u postgres psql`
- Or request elevated access

## 🎯 Next Task
After completion, proceed to: SUBAGENT_TASK_DOC_TABLES_002.md