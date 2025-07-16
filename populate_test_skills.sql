-- Populate employee_skills for testing multi-skill allocation
-- This assigns skills to the first 20 employees with varying proficiency levels

-- First, let's create a temporary mapping of employees to skills
WITH active_employees AS (
    SELECT id, first_name, last_name, ROW_NUMBER() OVER (ORDER BY id) as emp_num
    FROM employees 
    WHERE is_active = true 
    LIMIT 20
),
skill_list AS (
    SELECT id, name FROM skills
),
employee_skill_mapping AS (
    SELECT 
        e.id as employee_id,
        e.first_name,
        e.last_name,
        e.emp_num,
        s.id as skill_id,
        s.name as skill_name,
        -- Determine which skills each employee should have
        CASE 
            WHEN s.name = 'Customer Service' THEN true -- Everyone has customer service
            WHEN s.name = 'Chat Support' THEN true -- Everyone has chat support
            WHEN s.name = 'Technical Support' AND e.emp_num % 3 = 0 THEN true
            WHEN s.name = 'Billing Support' AND e.emp_num % 4 = 0 THEN true
            WHEN s.name = 'Sales' AND e.emp_num % 5 = 0 THEN true
            ELSE false
        END as should_have_skill,
        -- Assign proficiency levels
        CASE 
            WHEN s.name = 'Customer Service' THEN 3 + (e.emp_num % 3)
            WHEN s.name = 'Technical Support' THEN 2 + (e.emp_num % 3)
            WHEN s.name = 'Billing Support' THEN 2 + (e.emp_num % 2)
            WHEN s.name = 'Sales' THEN 3 + (e.emp_num % 2)
            WHEN s.name = 'Chat Support' THEN 2 + (e.emp_num % 3)
            ELSE 3
        END as proficiency,
        -- Some employees are certified
        CASE 
            WHEN s.name = 'Customer Service' THEN true
            WHEN e.emp_num % 3 = 0 THEN true
            ELSE false
        END as is_certified
    FROM active_employees e
    CROSS JOIN skill_list s
)
-- Insert employee skills
INSERT INTO employee_skills (employee_id, skill_id, proficiency_level, certified)
SELECT 
    employee_id,
    skill_id,
    proficiency,
    is_certified
FROM employee_skill_mapping
WHERE should_have_skill = true
ON CONFLICT (employee_id, skill_id) DO NOTHING;

-- Show the results
SELECT 
    e.first_name || ' ' || e.last_name as employee_name,
    s.name as skill_name,
    es.proficiency_level,
    es.certified
FROM employee_skills es
JOIN employees e ON es.employee_id = e.id
JOIN skills s ON es.skill_id = s.id
ORDER BY e.last_name, e.first_name, s.name
LIMIT 30;