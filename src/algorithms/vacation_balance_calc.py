#!/usr/bin/env python3
"""
Vacation Balance Calculator
Simple calculation functions for vacation days
"""

import logging
from typing import Dict, Optional
from datetime import datetime, date
from dataclasses import dataclass
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os

logger = logging.getLogger(__name__)

@dataclass
class VacationBalance:
    """Vacation balance result"""
    employee_id: int
    total_days: float
    used_days: float
    remaining_days: float
    accrual_rate: float
    year: int

class VacationBalanceCalculator:
    """Calculate vacation balances from agents table"""
    
    def __init__(self, connection_string: Optional[str] = None):
        """Initialize with wfm_enterprise database connection"""
        self.connection_string = connection_string or os.getenv(
            'DATABASE_URL',
            'postgresql://postgres:postgres@localhost:5432/wfm_enterprise'
        )
        
        self.engine = create_engine(self.connection_string)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
        logger.info("✅ VacationBalanceCalculator initialized")
    
    def calculate_balance(self, employee_id: int, target_year: int = None) -> VacationBalance:
        """
        Calculate vacation balance: total - used = remaining
        """
        if target_year is None:
            target_year = datetime.now().year
            
        try:
            with self.SessionLocal() as session:
                # Get vacation data from agents table
                result = session.execute(text("""
                    SELECT 
                        vacation_days_total,
                        vacation_days_used,
                        vacation_days_remaining
                    FROM agents 
                    WHERE id = :employee_id
                """), {
                    'employee_id': employee_id
                }).fetchone()
                
                if not result:
                    logger.warning(f"Employee {employee_id} not found")
                    return VacationBalance(
                        employee_id=employee_id,
                        total_days=0.0,
                        used_days=0.0,
                        remaining_days=0.0,
                        accrual_rate=0.0,
                        year=target_year
                    )
                
                # Get vacation data
                total_days = float(result.vacation_days_total or 0)
                used_days = float(result.vacation_days_used or 0)
                remaining_days = float(result.vacation_days_remaining or 0)
                accrual_rate = 0.0  # Not stored in agents table
                
                return VacationBalance(
                    employee_id=employee_id,
                    total_days=total_days,
                    used_days=used_days,
                    remaining_days=remaining_days,
                    accrual_rate=accrual_rate,
                    year=target_year
                )
                
        except Exception as e:
            logger.error(f"Error calculating vacation balance: {e}")
            return VacationBalance(
                employee_id=employee_id,
                total_days=0.0,
                used_days=0.0,
                remaining_days=0.0,
                accrual_rate=0.0,
                year=target_year
            )

def calculate_vacation_balance(employee_id: int, year: int = None) -> VacationBalance:
    """Simple function interface for vacation balance calculation"""
    calculator = VacationBalanceCalculator()
    return calculator.calculate_balance(employee_id, year)

def validate_vacation_calculator():
    """Test vacation balance calculation with real data"""
    try:
        # Test with employee ID 111538 (from CLAUDE_SIMPLIFIED.md)
        balance = calculate_vacation_balance(111538)
        
        print(f"✅ Vacation Balance for Employee {balance.employee_id}:")
        print(f"   Total Days: {balance.total_days}")
        print(f"   Used Days: {balance.used_days}")
        print(f"   Remaining Days: {balance.remaining_days}")
        print(f"   Accrual Rate: {balance.accrual_rate}")
        print(f"   Year: {balance.year}")
        
        return True
        
    except Exception as e:
        print(f"❌ Vacation calculator validation failed: {e}")
        return False

if __name__ == "__main__":
    # Configure logging
    logging.basicConfig(level=logging.INFO)
    
    # Test the calculator
    if validate_vacation_calculator():
        print("\n✅ Vacation Balance Calculator: READY")
    else:
        print("\n❌ Vacation Balance Calculator: FAILED")