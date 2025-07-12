#!/usr/bin/env python3
"""
Demo Data Creation for WFM Enterprise Demo
Creates minimal test data for the 10 core endpoints
"""

import asyncio
import json
import sys
from datetime import datetime, date, time, timedelta
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
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

# Create async engine
engine = create_async_engine(DATABASE_URL)
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    """Hash password for demo users"""
    return pwd_context.hash(password)

async def create_demo_data():
    """Create minimal demo data"""
    async with AsyncSessionLocal() as session:
        try:
            print("👤 Creating demo users...")
            
            # Get organization and department IDs
            org_result = await session.execute(text("SELECT get_demo_organization()"))
            org_id = org_result.scalar()
            
            dept_result = await session.execute(text("SELECT get_demo_department()"))
            dept_id = dept_result.scalar()
            
            # Create admin user
            admin_password = hash_password("AdminPass123!")
            await session.execute(text("""
                INSERT INTO users (organization_id, department_id, username, email, hashed_password, 
                                 first_name, last_name, is_admin, is_superuser)
                VALUES (:org_id, :dept_id, 'admin', 'admin@demo.com', :password, 'Demo', 'Admin', true, true)
                ON CONFLICT (email) DO UPDATE SET 
                    hashed_password = EXCLUDED.hashed_password,
                    updated_at = CURRENT_TIMESTAMP
            """), {
                "org_id": org_id,
                "dept_id": dept_id,
                "password": admin_password
            })
            
            # Create manager user
            manager_password = hash_password("ManagerPass123!")
            await session.execute(text("""
                INSERT INTO users (organization_id, department_id, username, email, hashed_password, 
                                 first_name, last_name, is_admin)
                VALUES (:org_id, :dept_id, 'manager', 'manager@demo.com', :password, 'Demo', 'Manager', false)
                ON CONFLICT (email) DO UPDATE SET 
                    hashed_password = EXCLUDED.hashed_password,
                    updated_at = CURRENT_TIMESTAMP
            """), {
                "org_id": org_id,
                "dept_id": dept_id,
                "password": manager_password
            })
            
            print("🏢 Creating demo skills...")
            
            # Create demo skills
            skills_data = [
                ("English", "English language proficiency", "language"),
                ("Technical Support", "Technical troubleshooting skills", "technical"),
                ("Sales", "Sales and customer acquisition", "sales"),
                ("Customer Service", "Customer service excellence", "service"),
                ("Spanish", "Spanish language proficiency", "language")
            ]
            
            for skill_name, description, category in skills_data:
                await session.execute(text("""
                    INSERT INTO skills (organization_id, name, description, category)
                    VALUES (:org_id, :name, :description, :category)
                    ON CONFLICT (organization_id, name) DO NOTHING
                """), {
                    "org_id": org_id,
                    "name": skill_name,
                    "description": description,
                    "category": category
                })
            
            print("👥 Creating demo employees...")
            
            # Create 50 demo employees
            employees_data = []
            for i in range(1, 51):
                employee = {
                    "organization_id": org_id,
                    "department_id": dept_id,
                    "employee_number": f"EMP{i:03d}",
                    "first_name": f"Employee{i}",
                    "last_name": f"Demo{i}",
                    "email": f"employee{i}@demo.com",
                    "employment_type": "full-time" if i % 10 != 0 else "part-time",
                    "hire_date": date.today() - timedelta(days=i*10)
                }
                employees_data.append(employee)
                
                await session.execute(text("""
                    INSERT INTO employees (organization_id, department_id, employee_number, 
                                         first_name, last_name, email, employment_type, hire_date)
                    VALUES (:organization_id, :department_id, :employee_number, 
                           :first_name, :last_name, :email, :employment_type, :hire_date)
                    ON CONFLICT (organization_id, employee_number) DO NOTHING
                """), employee)
            
            print("🎯 Assigning skills to employees...")
            
            # Get skill IDs
            skills_result = await session.execute(text("""
                SELECT id, name FROM skills WHERE organization_id = :org_id
            """), {"org_id": org_id})
            skills = {name: skill_id for skill_id, name in skills_result}
            
            # Get employee IDs
            employees_result = await session.execute(text("""
                SELECT id, employee_number FROM employees WHERE organization_id = :org_id
            """), {"org_id": org_id})
            employees = {emp_num: emp_id for emp_id, emp_num in employees_result}
            
            # Assign skills to employees (each employee gets 2-3 skills)
            skill_assignments = []
            for i, (emp_num, emp_id) in enumerate(employees.items(), 1):
                # All employees get English
                skill_assignments.append({
                    "employee_id": emp_id,
                    "skill_id": skills["English"],
                    "proficiency_level": 4 + (i % 2),  # 4 or 5
                    "certified": True
                })
                
                # Assign based on employee number
                if i % 3 == 1:  # Technical Support
                    skill_assignments.append({
                        "employee_id": emp_id,
                        "skill_id": skills["Technical Support"],
                        "proficiency_level": 3 + (i % 3),
                        "certified": i % 5 == 0
                    })
                elif i % 3 == 2:  # Sales
                    skill_assignments.append({
                        "employee_id": emp_id,
                        "skill_id": skills["Sales"],
                        "proficiency_level": 3 + (i % 3),
                        "certified": i % 4 == 0
                    })
                else:  # Customer Service
                    skill_assignments.append({
                        "employee_id": emp_id,
                        "skill_id": skills["Customer Service"],
                        "proficiency_level": 4,
                        "certified": True
                    })
                
                # Some employees get Spanish
                if i % 7 == 0:
                    skill_assignments.append({
                        "employee_id": emp_id,
                        "skill_id": skills["Spanish"],
                        "proficiency_level": 3,
                        "certified": i % 14 == 0
                    })
            
            # Insert skill assignments
            for assignment in skill_assignments:
                await session.execute(text("""
                    INSERT INTO employee_skills (employee_id, skill_id, proficiency_level, certified)
                    VALUES (:employee_id, :skill_id, :proficiency_level, :certified)
                    ON CONFLICT (employee_id, skill_id) DO NOTHING
                """), assignment)
            
            print("📈 Creating demo forecast...")
            
            # Create a demo forecast
            forecast_data = {
                "organization_id": org_id,
                "department_id": dept_id,
                "name": "Q1 2024 Call Volume Forecast",
                "forecast_type": "call_volume",
                "method": "ml_ensemble",
                "granularity": "30min",
                "start_date": datetime.now().replace(hour=0, minute=0, second=0, microsecond=0),
                "end_date": datetime.now().replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(days=7),
                "status": "completed",
                "accuracy_score": 0.956,
                "parameters": json.dumps({
                    "model_type": "ensemble",
                    "historical_months": 12,
                    "seasonal_adjustment": True,
                    "trend_analysis": True
                }),
                "results": json.dumps({
                    "total_calls": 8750,
                    "peak_hours": ["09:00-11:00", "14:00-16:00"],
                    "average_handle_time": 285,
                    "service_level_target": 0.80,
                    "confidence_interval": 0.95
                })
            }
            
            await session.execute(text("""
                INSERT INTO forecasts (organization_id, department_id, name, forecast_type, method, 
                                     granularity, start_date, end_date, status, accuracy_score, 
                                     parameters, results)
                VALUES (:organization_id, :department_id, :name, :forecast_type, :method, 
                       :granularity, :start_date, :end_date, :status, :accuracy_score, 
                       :parameters, :results)
                ON CONFLICT DO NOTHING
            """), forecast_data)
            
            print("📅 Creating demo schedule...")
            
            # Get the forecast ID
            forecast_result = await session.execute(text("""
                SELECT id FROM forecasts WHERE organization_id = :org_id ORDER BY created_at DESC LIMIT 1
            """), {"org_id": org_id})
            forecast_id = forecast_result.scalar()
            
            # Create a demo schedule
            schedule_data = {
                "organization_id": org_id,
                "department_id": dept_id,
                "forecast_id": forecast_id,
                "name": "Week 1 Optimized Schedule",
                "description": "AI-optimized schedule for customer support team",
                "schedule_type": "weekly",
                "start_date": date.today(),
                "end_date": date.today() + timedelta(days=6),
                "status": "published",
                "optimization_score": 0.923,
                "parameters": json.dumps({
                    "optimization_goals": ["minimize_cost", "maximize_coverage"],
                    "max_consecutive_days": 5,
                    "min_rest_hours": 11,
                    "skill_requirements": ["English", "Technical Support"]
                }),
                "metadata": json.dumps({
                    "generated_by": "ml_optimizer",
                    "generation_time": 2.3,
                    "conflicts_resolved": 0,
                    "coverage_percentage": 98.5
                })
            }
            
            await session.execute(text("""
                INSERT INTO schedules (organization_id, department_id, forecast_id, name, description, 
                                     schedule_type, start_date, end_date, status, optimization_score, 
                                     parameters, metadata)
                VALUES (:organization_id, :department_id, :forecast_id, :name, :description, 
                       :schedule_type, :start_date, :end_date, :status, :optimization_score, 
                       :parameters, :metadata)
                ON CONFLICT DO NOTHING
            """), schedule_data)
            
            print("⏰ Creating demo shifts...")
            
            # Get the schedule ID
            schedule_result = await session.execute(text("""
                SELECT id FROM schedules WHERE organization_id = :org_id ORDER BY created_at DESC LIMIT 1
            """), {"org_id": org_id})
            schedule_id = schedule_result.scalar()
            
            # Create shifts for the first 20 employees over 7 days
            shift_times = [
                (time(9, 0), time(17, 0)),    # 9 AM - 5 PM
                (time(13, 0), time(21, 0)),   # 1 PM - 9 PM
                (time(8, 0), time(16, 0)),    # 8 AM - 4 PM
                (time(10, 0), time(18, 0)),   # 10 AM - 6 PM
            ]
            
            employee_list = list(employees.values())[:20]  # First 20 employees
            
            for day_offset in range(7):  # 7 days
                shift_date = date.today() + timedelta(days=day_offset)
                
                # Skip weekends for demo simplicity
                if shift_date.weekday() >= 5:
                    continue
                    
                for i, emp_id in enumerate(employee_list):
                    # Each employee works 5 days, with different shift patterns
                    if (i + day_offset) % 7 < 5:  # Work 5 out of 7 days
                        start_time, end_time = shift_times[i % len(shift_times)]
                        
                        await session.execute(text("""
                            INSERT INTO schedule_shifts (schedule_id, employee_id, shift_date, 
                                                        start_time, end_time, break_duration, 
                                                        shift_type, status)
                            VALUES (:schedule_id, :employee_id, :shift_date, 
                                   :start_time, :end_time, 60, 'regular', 'scheduled')
                            ON CONFLICT (employee_id, shift_date, start_time) DO NOTHING
                        """), {
                            "schedule_id": schedule_id,
                            "employee_id": emp_id,
                            "shift_date": shift_date,
                            "start_time": start_time,
                            "end_time": end_time
                        })
            
            await session.commit()
            print("✅ Demo data created successfully!")
            
            # Print summary
            print("\n📊 Demo Data Summary:")
            
            # Count records
            counts = {}
            for table in ['users', 'employees', 'skills', 'employee_skills', 'forecasts', 'schedules', 'schedule_shifts']:
                result = await session.execute(text(f"SELECT COUNT(*) FROM {table}"))
                counts[table] = result.scalar()
            
            print(f"👤 Users: {counts['users']}")
            print(f"👥 Employees: {counts['employees']}")
            print(f"🎯 Skills: {counts['skills']}")
            print(f"🔗 Skill Assignments: {counts['employee_skills']}")
            print(f"📈 Forecasts: {counts['forecasts']}")
            print(f"📅 Schedules: {counts['schedules']}")
            print(f"⏰ Shifts: {counts['schedule_shifts']}")
            
            print("\n🔑 Demo Credentials:")
            print("Admin: admin@demo.com / AdminPass123!")
            print("Manager: manager@demo.com / ManagerPass123!")
            
        except Exception as e:
            await session.rollback()
            print(f"❌ Demo data creation failed: {e}")
            sys.exit(1)

async def main():
    """Main function"""
    print("🚀 WFM Enterprise Demo - Data Creation")
    print("=" * 40)
    
    await create_demo_data()
    
    print("\n✨ Demo data setup complete!")
    print("\n🎯 Next step: uvicorn src.api.main:app --reload")

if __name__ == "__main__":
    asyncio.run(main())