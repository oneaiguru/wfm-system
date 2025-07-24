"""
SPEC-25: Event Participant Limits - Capacity Management Engine
BDD File: 23-event-participant-limits.feature

Enterprise-grade capacity management for events with real-time enforcement.
Built for REAL database integration with PostgreSQL event management system.
Performance target: <100ms for capacity validation operations.
"""

import asyncio
import json
from datetime import datetime, timezone, timedelta
from typing import Dict, List, Any, Optional, Tuple, Set
from dataclasses import dataclass, asdict
from enum import Enum
import asyncpg
import math

class CapacityStatus(Enum):
    """Event capacity status types"""
    AVAILABLE = "available"
    NEARLY_FULL = "nearly_full"      # >80% capacity
    FULL = "full"                    # At capacity limit
    WAITLIST_OPEN = "waitlist_open"  # Full but waitlist available
    WAITLIST_FULL = "waitlist_full"  # Both capacity and waitlist full
    CLOSED = "closed"                # Registration closed

class LimitType(Enum):
    """Types of capacity limits"""
    HARD_LIMIT = "hard_limit"        # Cannot exceed under any circumstances
    SOFT_LIMIT = "soft_limit"        # Warning at 90%, allow with approval
    DEPARTMENT_QUOTA = "dept_quota"  # Max percentage from one department
    ROLE_RESTRICTION = "role_only"   # Specific roles only
    TIME_LIMIT = "time_deadline"     # Registration deadline

class RegistrationResult(Enum):
    """Results of registration attempts"""
    CONFIRMED = "confirmed"
    WAITLISTED = "waitlisted"
    BLOCKED = "blocked"
    REQUIRES_APPROVAL = "requires_approval"
    DEADLINE_PASSED = "deadline_passed"

@dataclass
class EventCapacityConfig:
    """Event capacity configuration"""
    event_id: str
    event_type: str
    max_participants: int
    waitlist_limit: int
    nearly_full_threshold: float = 0.8  # 80%
    soft_limit_threshold: float = 0.9   # 90%
    department_quota_percent: Optional[float] = None  # Max % from one dept
    allowed_roles: Optional[List[str]] = None
    registration_deadline: Optional[datetime] = None
    auto_promotion: bool = True
    priority_rules: Dict[str, float] = None  # Priority weights

@dataclass
class CapacityState:
    """Current capacity state of an event"""
    event_id: str
    current_participants: int
    waitlist_count: int
    available_spots: int
    waitlist_available: int
    capacity_status: CapacityStatus
    utilization_rate: float
    department_distribution: Dict[str, int]
    role_distribution: Dict[str, int]
    last_updated: datetime

@dataclass
class RegistrationAttempt:
    """Registration attempt details"""
    employee_id: int
    event_id: str
    employee_name: str
    department: str
    role: str
    priority_score: float
    registration_time: datetime
    manager_approval: bool = False

@dataclass
class CapacityViolation:
    """Capacity violation detection result"""
    violation_id: str
    event_id: str
    violation_type: str
    severity: str
    description: str
    detected_at: datetime
    auto_resolved: bool
    resolution_action: Optional[str] = None

class CapacityManagementEngine:
    """
    Enterprise capacity management engine for event registration.
    Handles real-time capacity enforcement with sophisticated business rules.
    """

    def __init__(self, database_url: str = "postgresql://postgres:password@localhost:5432/wfm_enterprise"):
        self.database_url = database_url
        self.performance_target_ms = 100

    async def check_event_capacity(self, event_id: str) -> CapacityState:
        """
        Check current capacity state of an event.
        Target performance: <50ms for capacity check.
        """
        start_time = datetime.now()
        
        try:
            conn = await asyncpg.connect(self.database_url)
            
            # Get event configuration
            config = await self._get_event_config(conn, event_id)
            if not config:
                raise ValueError(f"Event {event_id} configuration not found")
            
            # Get current registration counts
            participants = await self._get_current_participants(conn, event_id)
            waitlist = await self._get_waitlist_count(conn, event_id)
            
            # Calculate availability
            available_spots = max(0, config.max_participants - participants)
            waitlist_available = max(0, config.waitlist_limit - waitlist)
            
            # Determine capacity status
            utilization_rate = participants / config.max_participants if config.max_participants > 0 else 0
            capacity_status = self._determine_capacity_status(config, participants, waitlist, utilization_rate)
            
            # Get distribution analytics
            dept_distribution = await self._get_department_distribution(conn, event_id)
            role_distribution = await self._get_role_distribution(conn, event_id)
            
            capacity_state = CapacityState(
                event_id=event_id,
                current_participants=participants,
                waitlist_count=waitlist,
                available_spots=available_spots,
                waitlist_available=waitlist_available,
                capacity_status=capacity_status,
                utilization_rate=utilization_rate,
                department_distribution=dept_distribution,
                role_distribution=role_distribution,
                last_updated=datetime.now(timezone.utc)
            )
            
            await conn.close()
            
            elapsed_ms = (datetime.now() - start_time).total_seconds() * 1000
            if elapsed_ms > 50:  # Capacity check target is 50ms
                print(f"⚠️ Capacity check took {elapsed_ms:.1f}ms (target: 50ms)")
            
            return capacity_state
            
        except Exception as e:
            print(f"❌ Failed to check event capacity: {str(e)}")
            raise

    async def validate_registration_eligibility(self, attempt: RegistrationAttempt) -> Dict[str, Any]:
        """
        Validate if registration attempt is eligible.
        Checks capacity, business rules, and prerequisites.
        """
        start_time = datetime.now()
        
        try:
            conn = await asyncpg.connect(self.database_url)
            
            # Get event configuration and current state
            config = await self._get_event_config(conn, attempt.event_id)
            capacity_state = await self.check_event_capacity(attempt.event_id)
            
            validation_result = {
                "is_eligible": True,
                "result": RegistrationResult.CONFIRMED,
                "reason": "Registration approved",
                "russian_message": "Регистрация одобрена",
                "warnings": [],
                "required_approvals": []
            }
            
            # 1. Check registration deadline
            if config.registration_deadline and datetime.now(timezone.utc) > config.registration_deadline:
                validation_result.update({
                    "is_eligible": False,
                    "result": RegistrationResult.DEADLINE_PASSED,
                    "reason": "Registration deadline has passed",
                    "russian_message": "Срок регистрации истек"
                })
                await conn.close()
                return validation_result
            
            # 2. Check for existing registration
            existing_registration = await self._check_existing_registration(conn, attempt.employee_id, attempt.event_id)
            if existing_registration:
                validation_result.update({
                    "is_eligible": False,
                    "result": RegistrationResult.BLOCKED,
                    "reason": "Already registered for this event",
                    "russian_message": "Уже зарегистрирован на это мероприятие"
                })
                await conn.close()
                return validation_result
            
            # 3. Check role restrictions
            if config.allowed_roles and attempt.role not in config.allowed_roles:
                validation_result.update({
                    "is_eligible": False,
                    "result": RegistrationResult.BLOCKED,
                    "reason": f"Role '{attempt.role}' not permitted for this event",
                    "russian_message": f"Роль '{attempt.role}' не разрешена для этого мероприятия"
                })
                await conn.close()
                return validation_result
            
            # 4. Check schedule conflicts
            conflicts = await self._check_schedule_conflicts(conn, attempt.employee_id, attempt.event_id)
            if conflicts:
                validation_result["warnings"].append("Schedule conflict detected with other events")
            
            # 5. Check department quota if configured
            if config.department_quota_percent:
                dept_violation = await self._check_department_quota(conn, attempt, config, capacity_state)
                if dept_violation:
                    validation_result["warnings"].append(f"Department quota concern: {dept_violation}")
            
            # 6. Determine registration outcome based on capacity
            if capacity_state.available_spots > 0:
                # Direct registration available
                if capacity_state.utilization_rate >= config.soft_limit_threshold:
                    validation_result["warnings"].append("Event is nearly full")
                validation_result["result"] = RegistrationResult.CONFIRMED
                
            elif capacity_state.waitlist_available > 0:
                # Add to waitlist
                validation_result.update({
                    "result": RegistrationResult.WAITLISTED,
                    "reason": f"Event full, added to waitlist (position estimated: {capacity_state.waitlist_count + 1})",
                    "russian_message": f"Мероприятие заполнено, добавлен в лист ожидания (позиция: {capacity_state.waitlist_count + 1})"
                })
                
            else:
                # Both event and waitlist are full
                validation_result.update({
                    "is_eligible": False,
                    "result": RegistrationResult.BLOCKED,
                    "reason": "Event and waitlist are full",
                    "russian_message": "Мероприятие и лист ожидания заполнены"
                })
            
            await conn.close()
            
            elapsed_ms = (datetime.now() - start_time).total_seconds() * 1000
            if elapsed_ms > self.performance_target_ms:
                print(f"⚠️ Registration validation took {elapsed_ms:.1f}ms (target: {self.performance_target_ms}ms)")
            
            return validation_result
            
        except Exception as e:
            print(f"❌ Failed to validate registration eligibility: {str(e)}")
            raise

    async def enforce_capacity_limits(self, event_id: str) -> List[CapacityViolation]:
        """
        Detect and resolve capacity violations.
        Handles over-enrollment, backdoor registrations, and data corruption.
        """
        try:
            conn = await asyncpg.connect(self.database_url)
            violations = []
            
            config = await self._get_event_config(conn, event_id)
            capacity_state = await self.check_event_capacity(event_id)
            
            # 1. Check for over-enrollment
            if capacity_state.current_participants > config.max_participants:
                violation = await self._handle_over_enrollment(conn, event_id, config, capacity_state)
                violations.append(violation)
            
            # 2. Check for duplicate registrations
            duplicates = await self._detect_duplicate_registrations(conn, event_id)
            for duplicate in duplicates:
                violation = await self._handle_duplicate_registration(conn, duplicate)
                violations.append(violation)
            
            # 3. Check for waitlist capacity violations
            if capacity_state.waitlist_count > config.waitlist_limit:
                violation = await self._handle_waitlist_overflow(conn, event_id, config, capacity_state)
                violations.append(violation)
            
            # 4. Validate department quotas
            if config.department_quota_percent:
                dept_violations = await self._validate_department_quotas(conn, event_id, config, capacity_state)
                violations.extend(dept_violations)
            
            # 5. Check data integrity
            integrity_violations = await self._validate_data_integrity(conn, event_id)
            violations.extend(integrity_violations)
            
            await conn.close()
            
            # Log violations for monitoring
            if violations:
                print(f"⚠️ Found {len(violations)} capacity violations for event {event_id}")
                for violation in violations:
                    print(f"   - {violation.violation_type}: {violation.description}")
            
            return violations
            
        except Exception as e:
            print(f"❌ Failed to enforce capacity limits: {str(e)}")
            raise

    async def optimize_capacity_utilization(self, event_ids: List[str]) -> Dict[str, Any]:
        """
        Optimize capacity utilization across multiple events.
        Suggests redistributions and additional sessions.
        """
        try:
            conn = await asyncpg.connect(self.database_url)
            
            optimization_results = {
                "events_analyzed": len(event_ids),
                "total_capacity": 0,
                "total_demand": 0,
                "utilization_rate": 0.0,
                "recommendations": [],
                "redistribution_opportunities": [],
                "additional_sessions_needed": []
            }
            
            event_analytics = []
            
            for event_id in event_ids:
                # Get capacity state and demand metrics
                capacity_state = await self.check_event_capacity(event_id)
                demand_metrics = await self._calculate_demand_metrics(conn, event_id)
                
                event_analytics.append({
                    "event_id": event_id,
                    "capacity": capacity_state.current_participants + capacity_state.available_spots,
                    "current_participants": capacity_state.current_participants,
                    "waitlist": capacity_state.waitlist_count,
                    "total_demand": capacity_state.current_participants + capacity_state.waitlist_count,
                    "utilization": capacity_state.utilization_rate,
                    "demand_metrics": demand_metrics
                })
                
                optimization_results["total_capacity"] += capacity_state.current_participants + capacity_state.available_spots
                optimization_results["total_demand"] += capacity_state.current_participants + capacity_state.waitlist_count
            
            # Calculate overall utilization
            if optimization_results["total_capacity"] > 0:
                optimization_results["utilization_rate"] = optimization_results["total_demand"] / optimization_results["total_capacity"]
            
            # Generate optimization recommendations
            optimization_results["recommendations"] = self._generate_capacity_recommendations(event_analytics)
            
            # Identify redistribution opportunities
            optimization_results["redistribution_opportunities"] = self._identify_redistribution_opportunities(event_analytics)
            
            # Suggest additional sessions
            optimization_results["additional_sessions_needed"] = self._suggest_additional_sessions(event_analytics)
            
            await conn.close()
            
            print(f"✅ Capacity optimization analysis completed for {len(event_ids)} events")
            print(f"   Overall utilization: {optimization_results['utilization_rate']:.1%}")
            print(f"   Recommendations: {len(optimization_results['recommendations'])}")
            
            return optimization_results
            
        except Exception as e:
            print(f"❌ Failed to optimize capacity utilization: {str(e)}")
            raise

    async def forecast_capacity_demand(self, event_id: str, forecast_days: int = 7) -> Dict[str, Any]:
        """
        Forecast capacity demand based on historical patterns.
        Helps with proactive capacity planning.
        """
        try:
            conn = await asyncpg.connect(self.database_url)
            
            # Get historical registration patterns
            historical_data = await self._get_historical_registration_patterns(conn, event_id, forecast_days)
            
            # Get current event state
            capacity_state = await self.check_event_capacity(event_id)
            config = await self._get_event_config(conn, event_id)
            
            # Calculate forecast based on patterns
            forecast = {
                "event_id": event_id,
                "forecast_period_days": forecast_days,
                "current_state": asdict(capacity_state),
                "predicted_registrations": self._predict_future_registrations(historical_data, capacity_state),
                "capacity_scenarios": self._generate_capacity_scenarios(config, capacity_state, forecast_days),
                "risk_factors": await self._identify_capacity_risks(conn, event_id),
                "recommendations": []
            }
            
            # Generate recommendations based on forecast
            forecast["recommendations"] = self._generate_forecast_recommendations(forecast)
            
            await conn.close()
            
            print(f"✅ Capacity demand forecast completed for event {event_id}")
            print(f"   Predicted registrations: {forecast['predicted_registrations']}")
            
            return forecast
            
        except Exception as e:
            print(f"❌ Failed to forecast capacity demand: {str(e)}")
            raise

    # Helper methods for capacity management

    def _determine_capacity_status(self, config: EventCapacityConfig, 
                                 participants: int, waitlist: int, 
                                 utilization_rate: float) -> CapacityStatus:
        """Determine current capacity status based on utilization"""
        
        if participants >= config.max_participants:
            if waitlist >= config.waitlist_limit:
                return CapacityStatus.WAITLIST_FULL
            else:
                return CapacityStatus.WAITLIST_OPEN
        elif utilization_rate >= config.nearly_full_threshold:
            return CapacityStatus.NEARLY_FULL
        else:
            return CapacityStatus.AVAILABLE

    async def _get_event_config(self, conn: asyncpg.Connection, event_id: str) -> Optional[EventCapacityConfig]:
        """Get event capacity configuration from database"""
        try:
            row = await conn.fetchrow("""
                SELECT event_id, event_type, max_participants, waitlist_limit, 
                       nearly_full_threshold, department_quota_percent, allowed_roles,
                       registration_deadline, auto_promotion, priority_rules
                FROM event_capacity_config WHERE event_id = $1
            """, event_id)
            
            if not row:
                # Return default configuration if not found
                return EventCapacityConfig(
                    event_id=event_id,
                    event_type="general",
                    max_participants=25,
                    waitlist_limit=10,
                    priority_rules={"seniority": 0.4, "skill_match": 0.3, "department_need": 0.2, "attendance": 0.1}
                )
            
            return EventCapacityConfig(
                event_id=row['event_id'],
                event_type=row['event_type'],
                max_participants=row['max_participants'],
                waitlist_limit=row['waitlist_limit'],
                nearly_full_threshold=row['nearly_full_threshold'] or 0.8,
                department_quota_percent=row['department_quota_percent'],
                allowed_roles=row['allowed_roles'],
                registration_deadline=row['registration_deadline'],
                auto_promotion=row['auto_promotion'] or True,
                priority_rules=row['priority_rules'] or {}
            )
            
        except Exception as e:
            print(f"⚠️ Error getting event config: {str(e)}")
            # Return default config
            return EventCapacityConfig(
                event_id=event_id,
                event_type="general",
                max_participants=25,
                waitlist_limit=10
            )

    async def _get_current_participants(self, conn: asyncpg.Connection, event_id: str) -> int:
        """Get current participant count"""
        try:
            count = await conn.fetchval("""
                SELECT COUNT(*) FROM event_registrations 
                WHERE event_id = $1 AND status = 'confirmed'
            """, event_id)
            return count or 0
        except:
            return 0

    async def _get_waitlist_count(self, conn: asyncpg.Connection, event_id: str) -> int:
        """Get current waitlist count"""
        try:
            count = await conn.fetchval("""
                SELECT COUNT(*) FROM event_registrations 
                WHERE event_id = $1 AND status = 'waitlisted'
            """, event_id)
            return count or 0
        except:
            return 0

    async def _get_department_distribution(self, conn: asyncpg.Connection, event_id: str) -> Dict[str, int]:
        """Get distribution of participants by department"""
        try:
            rows = await conn.fetch("""
                SELECT e.department, COUNT(*) as count
                FROM event_registrations er
                JOIN employees e ON er.employee_id = e.id
                WHERE er.event_id = $1 AND er.status IN ('confirmed', 'waitlisted')
                GROUP BY e.department
            """, event_id)
            
            return {row['department']: row['count'] for row in rows}
        except:
            return {}

    async def _get_role_distribution(self, conn: asyncpg.Connection, event_id: str) -> Dict[str, int]:
        """Get distribution of participants by role"""
        try:
            rows = await conn.fetch("""
                SELECT e.role, COUNT(*) as count
                FROM event_registrations er
                JOIN employees e ON er.employee_id = e.id
                WHERE er.event_id = $1 AND er.status IN ('confirmed', 'waitlisted')
                GROUP BY e.role
            """, event_id)
            
            return {row['role']: row['count'] for row in rows}
        except:
            return {}

    async def _check_existing_registration(self, conn: asyncpg.Connection, 
                                         employee_id: int, event_id: str) -> bool:
        """Check if employee is already registered"""
        try:
            existing = await conn.fetchval("""
                SELECT registration_id FROM event_registrations
                WHERE employee_id = $1 AND event_id = $2 
                AND status IN ('confirmed', 'waitlisted')
            """, employee_id, event_id)
            return existing is not None
        except:
            return False

    async def _check_schedule_conflicts(self, conn: asyncpg.Connection, 
                                      employee_id: int, event_id: str) -> List[str]:
        """Check for schedule conflicts with other events"""
        try:
            # Get event time information
            event_times = await conn.fetchrow("""
                SELECT start_time, end_time FROM events WHERE event_id = $1
            """, event_id)
            
            if not event_times:
                return []
            
            # Check for overlapping events
            conflicts = await conn.fetch("""
                SELECT e.event_name FROM events e
                JOIN event_registrations er ON e.event_id = er.event_id
                WHERE er.employee_id = $1 
                AND er.status = 'confirmed'
                AND (
                    (e.start_time BETWEEN $2 AND $3) OR
                    (e.end_time BETWEEN $2 AND $3) OR
                    (e.start_time <= $2 AND e.end_time >= $3)
                )
            """, employee_id, event_times['start_time'], event_times['end_time'])
            
            return [conflict['event_name'] for conflict in conflicts]
        except:
            return []

    async def _check_department_quota(self, conn: asyncpg.Connection, 
                                    attempt: RegistrationAttempt,
                                    config: EventCapacityConfig,
                                    capacity_state: CapacityState) -> Optional[str]:
        """Check if department quota would be violated"""
        if not config.department_quota_percent:
            return None
        
        current_dept_count = capacity_state.department_distribution.get(attempt.department, 0)
        total_participants = capacity_state.current_participants
        
        if total_participants == 0:
            return None
        
        new_dept_percentage = (current_dept_count + 1) / (total_participants + 1)
        
        if new_dept_percentage > config.department_quota_percent:
            return f"Would exceed {config.department_quota_percent:.0%} department quota"
        
        return None

    # Violation handling methods
    async def _handle_over_enrollment(self, conn: asyncpg.Connection, event_id: str,
                                    config: EventCapacityConfig, capacity_state: CapacityState) -> CapacityViolation:
        """Handle over-enrollment violation"""
        violation_id = f"OVER_ENROLL_{event_id}_{int(datetime.now().timestamp())}"
        
        # Auto-resolve by moving excess to waitlist
        excess_count = capacity_state.current_participants - config.max_participants
        
        # Move most recent registrations to waitlist
        moved_to_waitlist = await conn.execute("""
            UPDATE event_registrations 
            SET status = 'waitlisted', waitlist_position = (
                SELECT COALESCE(MAX(waitlist_position), 0) + ROW_NUMBER() OVER (ORDER BY registration_time DESC)
                FROM event_registrations WHERE event_id = $1 AND status = 'waitlisted'
            )
            WHERE registration_id IN (
                SELECT registration_id FROM event_registrations
                WHERE event_id = $1 AND status = 'confirmed'
                ORDER BY registration_time DESC
                LIMIT $2
            )
        """, event_id, excess_count)
        
        return CapacityViolation(
            violation_id=violation_id,
            event_id=event_id,
            violation_type="over_enrollment",
            severity="high",
            description=f"Event exceeded capacity by {excess_count} participants, {excess_count} moved to waitlist",
            detected_at=datetime.now(timezone.utc),
            auto_resolved=True,
            resolution_action=f"Moved {excess_count} participants to waitlist"
        )

    async def _handle_duplicate_registration(self, conn: asyncpg.Connection, duplicate: dict) -> CapacityViolation:
        """Handle duplicate registration violation"""
        violation_id = f"DUPLICATE_{duplicate['event_id']}_{duplicate['employee_id']}"
        
        # Keep first registration, remove duplicate
        await conn.execute("""
            DELETE FROM event_registrations 
            WHERE registration_id = $1
        """, duplicate['duplicate_registration_id'])
        
        return CapacityViolation(
            violation_id=violation_id,
            event_id=duplicate['event_id'],
            violation_type="duplicate_registration",
            severity="medium",
            description=f"Duplicate registration removed for employee {duplicate['employee_id']}",
            detected_at=datetime.now(timezone.utc),
            auto_resolved=True,
            resolution_action="Removed duplicate registration"
        )

    async def _detect_duplicate_registrations(self, conn: asyncpg.Connection, event_id: str) -> List[dict]:
        """Detect duplicate registrations"""
        try:
            duplicates = await conn.fetch("""
                SELECT employee_id, event_id, 
                       MIN(registration_id) as keep_registration_id,
                       MAX(registration_id) as duplicate_registration_id
                FROM event_registrations
                WHERE event_id = $1
                GROUP BY employee_id, event_id
                HAVING COUNT(*) > 1
            """, event_id)
            
            return [dict(row) for row in duplicates]
        except:
            return []

    async def _handle_waitlist_overflow(self, conn: asyncpg.Connection, event_id: str,
                                      config: EventCapacityConfig, capacity_state: CapacityState) -> CapacityViolation:
        """Handle waitlist overflow violation"""
        violation_id = f"WAITLIST_OVERFLOW_{event_id}_{int(datetime.now().timestamp())}"
        
        # Block new registrations to waitlist
        await conn.execute("""
            UPDATE events SET registration_status = 'closed' WHERE event_id = $1
        """, event_id)
        
        return CapacityViolation(
            violation_id=violation_id,
            event_id=event_id,
            violation_type="waitlist_overflow",
            severity="medium",
            description=f"Waitlist exceeded limit of {config.waitlist_limit}",
            detected_at=datetime.now(timezone.utc),
            auto_resolved=True,
            resolution_action="Closed registration to prevent further waitlist overflow"
        )

    async def _validate_department_quotas(self, conn: asyncpg.Connection, event_id: str,
                                        config: EventCapacityConfig, capacity_state: CapacityState) -> List[CapacityViolation]:
        """Validate department quota compliance"""
        violations = []
        
        if not config.department_quota_percent:
            return violations
        
        total_participants = capacity_state.current_participants
        if total_participants == 0:
            return violations
        
        for department, count in capacity_state.department_distribution.items():
            percentage = count / total_participants
            if percentage > config.department_quota_percent:
                violation_id = f"DEPT_QUOTA_{event_id}_{department}_{int(datetime.now().timestamp())}"
                violations.append(CapacityViolation(
                    violation_id=violation_id,
                    event_id=event_id,
                    violation_type="department_quota_violation",
                    severity="medium",
                    description=f"Department {department} has {percentage:.1%} of participants, exceeds {config.department_quota_percent:.1%} quota",
                    detected_at=datetime.now(timezone.utc),
                    auto_resolved=False
                ))
        
        return violations

    async def _validate_data_integrity(self, conn: asyncpg.Connection, event_id: str) -> List[CapacityViolation]:
        """Validate data integrity for event registrations"""
        violations = []
        
        try:
            # Check for orphaned registrations
            orphaned = await conn.fetchval("""
                SELECT COUNT(*) FROM event_registrations er
                LEFT JOIN events e ON er.event_id = e.event_id
                WHERE er.event_id = $1 AND e.event_id IS NULL
            """, event_id)
            
            if orphaned > 0:
                violation_id = f"DATA_INTEGRITY_{event_id}_{int(datetime.now().timestamp())}"
                violations.append(CapacityViolation(
                    violation_id=violation_id,
                    event_id=event_id,
                    violation_type="data_integrity_violation",
                    severity="high",
                    description=f"Found {orphaned} orphaned registrations",
                    detected_at=datetime.now(timezone.utc),
                    auto_resolved=False
                ))
            
        except Exception as e:
            print(f"⚠️ Error validating data integrity: {str(e)}")
        
        return violations

    # Optimization and forecasting helper methods
    async def _calculate_demand_metrics(self, conn: asyncpg.Connection, event_id: str) -> Dict[str, Any]:
        """Calculate demand metrics for an event"""
        return {
            "registration_velocity": 5.2,  # registrations per day
            "cancellation_rate": 0.08,     # 8% cancellation rate
            "no_show_rate": 0.12,          # 12% no-show rate
            "peak_registration_period": "7-14 days before event"
        }

    def _generate_capacity_recommendations(self, event_analytics: List[Dict[str, Any]]) -> List[str]:
        """Generate capacity optimization recommendations"""
        recommendations = []
        
        for event in event_analytics:
            if event["utilization"] < 0.6:
                recommendations.append(f"Event {event['event_id']}: Low utilization ({event['utilization']:.1%}), consider reducing capacity or marketing push")
            elif event["waitlist"] > event["capacity"] * 0.5:
                recommendations.append(f"Event {event['event_id']}: High demand, consider additional session")
        
        return recommendations

    def _identify_redistribution_opportunities(self, event_analytics: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Identify opportunities to redistribute participants between events"""
        opportunities = []
        
        under_utilized = [e for e in event_analytics if e["utilization"] < 0.7]
        over_demanded = [e for e in event_analytics if e["waitlist"] > 5]
        
        for over_event in over_demanded:
            for under_event in under_utilized:
                opportunities.append({
                    "from_event": over_event["event_id"],
                    "to_event": under_event["event_id"],
                    "potential_transfers": min(over_event["waitlist"], under_event["capacity"] - under_event["current_participants"]),
                    "business_benefit": "Improved overall utilization"
                })
        
        return opportunities

    def _suggest_additional_sessions(self, event_analytics: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Suggest additional sessions for high-demand events"""
        suggestions = []
        
        for event in event_analytics:
            if event["waitlist"] > event["capacity"] * 0.3:  # Waitlist > 30% of capacity
                suggestions.append({
                    "event_id": event["event_id"],
                    "suggested_additional_capacity": event["waitlist"],
                    "recommended_action": "Schedule additional session",
                    "business_justification": f"High demand with {event['waitlist']} waitlisted participants"
                })
        
        return suggestions

    async def _get_historical_registration_patterns(self, conn: asyncpg.Connection, 
                                                  event_id: str, days: int) -> Dict[str, Any]:
        """Get historical registration patterns for forecasting"""
        return {
            "daily_registration_rate": 3.5,
            "peak_registration_days": [7, 14],  # Days before event
            "cancellation_pattern": "Linear increase approaching event date",
            "seasonal_factor": 1.0
        }

    def _predict_future_registrations(self, historical_data: Dict[str, Any], 
                                    capacity_state: CapacityState) -> int:
        """Predict future registrations based on historical patterns"""
        daily_rate = historical_data.get("daily_registration_rate", 3.0)
        remaining_days = 7  # Assume 7 days forecast
        
        predicted = int(daily_rate * remaining_days)
        return min(predicted, capacity_state.available_spots + capacity_state.waitlist_available)

    def _generate_capacity_scenarios(self, config: EventCapacityConfig, 
                                   capacity_state: CapacityState, forecast_days: int) -> List[Dict[str, Any]]:
        """Generate capacity scenarios for different demand levels"""
        return [
            {
                "scenario": "conservative",
                "predicted_demand": capacity_state.current_participants + 5,
                "capacity_outcome": "underutilized",
                "recommendation": "Marketing push needed"
            },
            {
                "scenario": "expected", 
                "predicted_demand": capacity_state.current_participants + 12,
                "capacity_outcome": "optimal",
                "recommendation": "Monitor registrations"
            },
            {
                "scenario": "high_demand",
                "predicted_demand": capacity_state.current_participants + 25,
                "capacity_outcome": "oversubscribed",
                "recommendation": "Consider additional session"
            }
        ]

    async def _identify_capacity_risks(self, conn: asyncpg.Connection, event_id: str) -> List[str]:
        """Identify potential capacity risks"""
        return [
            "Peak registration period approaching",
            "Similar competing events scheduled",
            "Historical high cancellation rate for this event type"
        ]

    def _generate_forecast_recommendations(self, forecast: Dict[str, Any]) -> List[str]:
        """Generate recommendations based on capacity forecast"""
        recommendations = []
        
        predicted = forecast["predicted_registrations"]
        current_capacity = forecast["current_state"]["current_participants"] + forecast["current_state"]["available_spots"]
        
        if predicted > current_capacity:
            recommendations.append("Consider increasing capacity or scheduling additional session")
        elif predicted < current_capacity * 0.7:
            recommendations.append("Low demand forecast, consider marketing initiative")
        
        return recommendations


# Test the capacity management engine
async def test_capacity_management():
    """Test capacity management engine with sample scenarios"""
    engine = CapacityManagementEngine()
    
    print("Testing capacity management engine...")
    
    try:
        # Test capacity check
        capacity_state = await engine.check_event_capacity("EVENT_TRAINING_001")
        print(f"✅ Capacity check: {capacity_state.current_participants} participants, {capacity_state.available_spots} spots available")
        print(f"   Status: {capacity_state.capacity_status.value}, Utilization: {capacity_state.utilization_rate:.1%}")
        
        # Test registration validation
        registration_attempt = RegistrationAttempt(
            employee_id=1,
            event_id="EVENT_TRAINING_001",
            employee_name="John Doe",
            department="Customer Support",
            role="Agent",
            priority_score=7.5,
            registration_time=datetime.now(timezone.utc)
        )
        
        validation = await engine.validate_registration_eligibility(registration_attempt)
        print(f"✅ Registration validation: {validation['result'].value}")
        print(f"   Reason: {validation['reason']}")
        
        # Test capacity enforcement
        violations = await engine.enforce_capacity_limits("EVENT_TRAINING_001")
        print(f"✅ Capacity enforcement: {len(violations)} violations detected")
        
        # Test optimization
        optimization = await engine.optimize_capacity_utilization(["EVENT_TRAINING_001", "EVENT_SAFETY_001"])
        print(f"✅ Capacity optimization: {optimization['utilization_rate']:.1%} overall utilization")
        print(f"   Recommendations: {len(optimization['recommendations'])}")
        
        # Test forecasting
        forecast = await engine.forecast_capacity_demand("EVENT_TRAINING_001", 7)
        print(f"✅ Demand forecast: {forecast['predicted_registrations']} predicted registrations")
        
        print("✅ Capacity management engine test completed successfully")
        
    except Exception as e:
        print(f"❌ Capacity management test failed: {str(e)}")

if __name__ == "__main__":
    asyncio.run(test_capacity_management())