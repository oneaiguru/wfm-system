#!/usr/bin/env python3
"""
Simple demo data creation for WFM Enterprise
Creates 50 employees with skills, forecasts, and schedules
"""

import asyncio
import random
from datetime import datetime, timedelta, date
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
import os
from dotenv import load_dotenv
from passlib.context import CryptContext

# Load environment variables
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://postgres:@localhost/wfm_enterprise")

# Convert to async URL if needed
if not DATABASE_URL.startswith("postgresql+asyncpg://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://")

print(f"🗄️  Connecting to database: {DATABASE_URL}")

# Create async engine
engine = create_async_engine(DATABASE_URL, echo=False)

# Password context
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Demo data
FIRST_NAMES = ["John", "Jane", "Michael", "Sarah", "David", "Lisa", "Robert", "Mary", 
               "James", "Patricia", "William", "Jennifer", "Richard", "Linda", "Thomas"]
LAST_NAMES = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", 
              "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Wilson", "Anderson"]

SKILLS = [
    ("Customer Service", "general"),
    ("Technical Support", "technical"),
    ("Sales", "sales"),
    ("Billing Support", "financial"),
    ("Product Knowledge", "general"),
    ("English", "language"),
    ("Spanish", "language"),
    ("Problem Solving", "general"),
    ("Email Support", "technical"),
    ("Chat Support", "technical")
]

async def create_demo_data():
    """Create demo data for WFM Enterprise"""
    try:
        async with engine.begin() as conn:
            print("🏢 Creating organization and department...")
            
            # Create organization
            result = await conn.execute(text("""
                INSERT INTO organizations (name, code) 
                VALUES ('Demo Organization', 'DEMO_ORG') 
                RETURNING id
            """))
            org_id = result.scalar()
            
            # Create departments
            dept_results = []
            departments = [
                ('Customer Support', 'SUPPORT'),
                ('Sales', 'SALES'),
                ('Technical Support', 'TECH')
            ]
            
            for dept_name, dept_code in departments:
                result = await conn.execute(text("""
                    INSERT INTO departments (organization_id, name, code)
                    VALUES (:org_id, :name, :code)
                    RETURNING id
                """), {"org_id": org_id, "name": dept_name, "code": dept_code})
                dept_results.append((dept_code, result.scalar()))
            
            # Get primary department for most employees
            support_dept_id = dept_results[0][1]
            
            print("👤 Creating demo users...")
            
            # Create admin user
            admin_hash = pwd_context.hash("AdminPass123!")
            result = await conn.execute(text("""
                INSERT INTO users (organization_id, department_id, username, email, 
                                 hashed_password, first_name, last_name, is_admin, is_superuser)
                VALUES (:org_id, :dept_id, 'admin', 'admin@demo.com', :password, 
                       'Admin', 'User', true, true)
                RETURNING id
            """), {"org_id": org_id, "dept_id": support_dept_id, "password": admin_hash})
            admin_user_id = result.scalar()
            
            # Create manager user
            manager_hash = pwd_context.hash("ManagerPass123!")
            result = await conn.execute(text("""
                INSERT INTO users (organization_id, department_id, username, email,
                                 hashed_password, first_name, last_name, is_admin)
                VALUES (:org_id, :dept_id, 'manager', 'manager@demo.com', :password,
                       'Manager', 'User', true)
                RETURNING id
            """), {"org_id": org_id, "dept_id": support_dept_id, "password": manager_hash})
            manager_user_id = result.scalar()
            
            # Assign roles
            result = await conn.execute(text("SELECT id FROM roles WHERE name = 'admin'"))
            admin_role_id = result.scalar()
            result = await conn.execute(text("SELECT id FROM roles WHERE name = 'manager'"))
            manager_role_id = result.scalar()
            
            await conn.execute(text("""
                INSERT INTO user_roles (user_id, role_id) VALUES
                (:admin_id, :admin_role),
                (:manager_id, :manager_role)
            """), {"admin_id": admin_user_id, "admin_role": admin_role_id,
                   "manager_id": manager_user_id, "manager_role": manager_role_id})
            
            print("💼 Creating skills...")
            
            # Create skills
            skill_ids = []
            for skill_name, category in SKILLS:
                result = await conn.execute(text("""
                    INSERT INTO skills (organization_id, name, category)
                    VALUES (:org_id, :name, :category)
                    RETURNING id
                """), {"org_id": org_id, "name": skill_name, "category": category})
                skill_ids.append(result.scalar())
            
            print("👥 Creating 50 demo employees...")
            
            # Create employees
            employee_ids = []
            for i in range(50):
                first_name = random.choice(FIRST_NAMES)
                last_name = random.choice(LAST_NAMES)
                employee_number = f"EMP{str(i+1).zfill(4)}"
                email = f"{first_name.lower()}.{last_name.lower()}{i}@demo.com"
                
                # Distribute employees across departments
                if i < 30:
                    dept_id = support_dept_id  # 30 in support
                elif i < 40:
                    dept_id = dept_results[1][1]  # 10 in sales
                else:
                    dept_id = dept_results[2][1]  # 10 in tech
                
                hire_date = date.today() - timedelta(days=random.randint(30, 1095))
                
                result = await conn.execute(text("""
                    INSERT INTO employees (organization_id, department_id, employee_number,
                                         first_name, last_name, email, hire_date)
                    VALUES (:org_id, :dept_id, :emp_num, :first, :last, :email, :hire_date)
                    RETURNING id
                """), {
                    "org_id": org_id,
                    "dept_id": dept_id,
                    "emp_num": employee_number,
                    "first": first_name,
                    "last": last_name,
                    "email": email,
                    "hire_date": hire_date
                })
                employee_ids.append(result.scalar())
                
                # Assign 2-5 random skills to each employee
                num_skills = random.randint(2, 5)
                for skill_id in random.sample(skill_ids, num_skills):
                    proficiency = random.randint(1, 5)
                    await conn.execute(text("""
                        INSERT INTO employee_skills (employee_id, skill_id, proficiency_level)
                        VALUES (:emp_id, :skill_id, :prof)
                    """), {"emp_id": employee_ids[-1], "skill_id": skill_id, "prof": proficiency})
            
            print("📊 Creating forecasts with 95.6% accuracy...")
            
            # Create forecasts
            forecast_ids = []
            forecast_names = [
                "Q1 2024 Call Volume",
                "Q1 2024 Email Volume", 
                "Q1 2024 Chat Volume",
                "February 2024 Staffing",
                "March 2024 Optimization"
            ]
            
            for i, forecast_name in enumerate(forecast_names):
                start_date = datetime.now() + timedelta(days=i*7)
                end_date = start_date + timedelta(days=30)
                accuracy = 0.956 if i == 0 else round(random.uniform(0.92, 0.98), 3)
                
                result = await conn.execute(text("""
                    INSERT INTO forecasts (organization_id, department_id, name, 
                                         start_date, end_date, status, accuracy_score)
                    VALUES (:org_id, :dept_id, :name, :start, :end, :status, :accuracy)
                    RETURNING id
                """), {
                    "org_id": org_id,
                    "dept_id": support_dept_id,
                    "name": forecast_name,
                    "start": start_date,
                    "end": end_date,
                    "status": "completed" if i < 3 else "in_progress",
                    "accuracy": accuracy
                })
                forecast_ids.append(result.scalar())
            
            print("📅 Creating schedules with 92.3% optimization...")
            
            # Create schedules
            schedule_names = [
                "Week 1 Optimized Schedule",
                "Week 2 Optimized Schedule",
                "Week 3 Draft Schedule",
                "February Special Events",
                "March Coverage Plan"
            ]
            
            for i, schedule_name in enumerate(schedule_names):
                start_date = date.today() + timedelta(days=i*7)
                end_date = start_date + timedelta(days=6)
                optimization = 0.923 if i == 0 else round(random.uniform(0.88, 0.95), 3)
                
                result = await conn.execute(text("""
                    INSERT INTO schedules (organization_id, department_id, forecast_id,
                                         name, start_date, end_date, status, optimization_score)
                    VALUES (:org_id, :dept_id, :forecast_id, :name, :start, :end, :status, :opt)
                    RETURNING id
                """), {
                    "org_id": org_id,
                    "dept_id": support_dept_id,
                    "forecast_id": forecast_ids[min(i, len(forecast_ids)-1)],
                    "name": schedule_name,
                    "start": start_date,
                    "end": end_date,
                    "status": "published" if i < 2 else "draft",
                    "opt": optimization
                })
                schedule_id = result.scalar()
                
                # Create shifts for first 20 employees
                if i < 2:  # Only for published schedules
                    for emp_idx in range(20):
                        for day in range(5):  # Monday to Friday
                            shift_date = start_date + timedelta(days=day)
                            # Morning or evening shift
                            if emp_idx % 2 == 0:
                                start_time = "08:00:00"
                                end_time = "16:00:00"
                            else:
                                start_time = "14:00:00"
                                end_time = "22:00:00"
                            
                            await conn.execute(text("""
                                INSERT INTO schedule_shifts (schedule_id, employee_id, shift_date,
                                                           start_time, end_time, break_duration)
                                VALUES (:sched_id, :emp_id, :date, CAST(:start AS time), CAST(:end AS time), 30)
                            """), {
                                "sched_id": schedule_id,
                                "emp_id": employee_ids[emp_idx],
                                "date": shift_date,
                                "start": start_time,
                                "end": end_time
                            })
            
            print("✅ Demo data created successfully!")
            
        # Verify data
        async with engine.begin() as conn:
            counts = {}
            tables = ['organizations', 'departments', 'users', 'employees', 
                     'skills', 'forecasts', 'schedules', 'schedule_shifts']
            
            for table in tables:
                result = await conn.execute(text(f"SELECT COUNT(*) FROM {table}"))
                counts[table] = result.scalar()
            
            print("\n📊 Data Summary:")
            print(f"   Organizations: {counts['organizations']}")
            print(f"   Departments: {counts['departments']}")
            print(f"   Users: {counts['users']}")
            print(f"   Employees: {counts['employees']}")
            print(f"   Skills: {counts['skills']}")
            print(f"   Forecasts: {counts['forecasts']} (95.6% accuracy)")
            print(f"   Schedules: {counts['schedules']} (92.3% optimization)")
            print(f"   Shifts: {counts['schedule_shifts']}")
            
    except Exception as e:
        print(f"❌ Demo data creation failed: {e}")
        import traceback
        traceback.print_exc()

async def main():
    """Main function"""
    print("🚀 WFM Enterprise Demo - Data Creation")
    print("=" * 40)
    
    await create_demo_data()
    
    # Close engine
    await engine.dispose()
    print("\n✨ Database ready for API testing!")

if __name__ == "__main__":
    asyncio.run(main())