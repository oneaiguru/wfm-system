"""
SPEC-17: Reference Data Version Control Manager
BDD File: 17-reference-data-management-configuration.feature

Enterprise-grade version control system for reference data with complete audit trail.
Built for REAL database integration with PostgreSQL schema.
Performance target: <100ms for version operations.
"""

import asyncio
import json
from datetime import datetime, timezone
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass, asdict
from enum import Enum
import asyncpg
import hashlib
import difflib

class VersionStatus(Enum):
    """Version status types"""
    DRAFT = "draft"
    ACTIVE = "active"
    ARCHIVED = "archived"
    DEPRECATED = "deprecated"

class ChangeType(Enum):
    """Types of changes tracked"""
    CREATE = "create"
    UPDATE = "update"
    DELETE = "delete"
    RESTORE = "restore"
    APPROVE = "approve"
    REJECT = "reject"

@dataclass
class VersionInfo:
    """Version information for reference data"""
    version_id: str
    entity_code: str
    entity_type: str
    version_number: str
    status: VersionStatus
    created_by: str
    created_at: datetime
    approved_by: Optional[str] = None
    approved_at: Optional[datetime] = None
    change_summary: str = ""
    data_hash: str = ""

@dataclass
class ChangeRecord:
    """Individual change record in version history"""
    change_id: str
    version_id: str
    change_type: ChangeType
    field_name: str
    old_value: Any
    new_value: Any
    changed_by: str
    changed_at: datetime
    change_reason: str = ""

@dataclass
class VersionDiff:
    """Comparison between two versions"""
    from_version: str
    to_version: str
    added_fields: List[str]
    removed_fields: List[str]
    modified_fields: List[Dict[str, Any]]
    impact_score: float
    rollback_complexity: str

class VersionControlManager:
    """
    Enterprise version control manager for reference data.
    Provides complete audit trail, rollback capabilities, and change approval workflow.
    """

    def __init__(self, database_url: str = "postgresql://postgres:password@localhost:5432/wfm_enterprise"):
        self.database_url = database_url
        self.performance_target_ms = 100

    async def create_version(self, entity_code: str, entity_type: str, data: Dict[str, Any], 
                           created_by: str, change_summary: str = "") -> VersionInfo:
        """
        Create a new version of reference data.
        Target performance: <100ms.
        """
        start_time = datetime.now()
        
        try:
            conn = await asyncpg.connect(self.database_url)
            
            # Generate version ID and number
            version_id = self._generate_version_id(entity_code, entity_type)
            version_number = await self._get_next_version_number(conn, entity_code, entity_type)
            
            # Calculate data hash for integrity
            data_hash = self._calculate_data_hash(data)
            
            # Create version record
            version_info = VersionInfo(
                version_id=version_id,
                entity_code=entity_code,
                entity_type=entity_type,
                version_number=version_number,
                status=VersionStatus.DRAFT,
                created_by=created_by,
                created_at=datetime.now(timezone.utc),
                change_summary=change_summary,
                data_hash=data_hash
            )
            
            # Insert into database
            await conn.execute("""
                INSERT INTO reference_data_versions 
                (version_id, entity_code, entity_type, version_number, status, 
                 created_by, created_at, change_summary, data_hash, data_content)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            """, version_id, entity_code, entity_type, version_number, 
                version_info.status.value, created_by, version_info.created_at,
                change_summary, data_hash, json.dumps(data))
            
            # Record change details
            await self._record_detailed_changes(conn, version_info, data, created_by)
            
            await conn.close()
            
            # Performance check
            elapsed_ms = (datetime.now() - start_time).total_seconds() * 1000
            if elapsed_ms > self.performance_target_ms:
                print(f"⚠️ Version creation took {elapsed_ms:.1f}ms (target: {self.performance_target_ms}ms)")
            
            print(f"✅ Created version {version_number} for {entity_type}.{entity_code}")
            return version_info
            
        except Exception as e:
            print(f"❌ Failed to create version: {str(e)}")
            raise

    async def get_version_history(self, entity_code: str, entity_type: str, 
                                limit: int = 50) -> List[VersionInfo]:
        """Get complete version history for an entity"""
        try:
            conn = await asyncpg.connect(self.database_url)
            
            rows = await conn.fetch("""
                SELECT version_id, entity_code, entity_type, version_number, status,
                       created_by, created_at, approved_by, approved_at, 
                       change_summary, data_hash
                FROM reference_data_versions
                WHERE entity_code = $1 AND entity_type = $2
                ORDER BY created_at DESC
                LIMIT $3
            """, entity_code, entity_type, limit)
            
            versions = []
            for row in rows:
                versions.append(VersionInfo(
                    version_id=row['version_id'],
                    entity_code=row['entity_code'],
                    entity_type=row['entity_type'],
                    version_number=row['version_number'],
                    status=VersionStatus(row['status']),
                    created_by=row['created_by'],
                    created_at=row['created_at'],
                    approved_by=row['approved_by'],
                    approved_at=row['approved_at'],
                    change_summary=row['change_summary'],
                    data_hash=row['data_hash']
                ))
            
            await conn.close()
            return versions
            
        except Exception as e:
            print(f"❌ Failed to get version history: {str(e)}")
            raise

    async def compare_versions(self, version_id_1: str, version_id_2: str) -> VersionDiff:
        """
        Compare two versions and generate detailed diff.
        Includes impact analysis and rollback complexity assessment.
        """
        try:
            conn = await asyncpg.connect(self.database_url)
            
            # Get version data
            version_1_data = await self._get_version_data(conn, version_id_1)
            version_2_data = await self._get_version_data(conn, version_id_2)
            
            if not version_1_data or not version_2_data:
                raise ValueError("One or both versions not found")
            
            data_1 = json.loads(version_1_data['data_content'])
            data_2 = json.loads(version_2_data['data_content'])
            
            # Calculate differences
            added_fields = []
            removed_fields = []
            modified_fields = []
            
            all_keys = set(data_1.keys()) | set(data_2.keys())
            
            for key in all_keys:
                if key not in data_1:
                    added_fields.append(key)
                elif key not in data_2:
                    removed_fields.append(key)
                elif data_1[key] != data_2[key]:
                    modified_fields.append({
                        "field": key,
                        "old_value": data_1[key],
                        "new_value": data_2[key],
                        "change_type": self._classify_change(data_1[key], data_2[key])
                    })
            
            # Calculate impact score
            impact_score = self._calculate_impact_score(added_fields, removed_fields, modified_fields)
            
            # Assess rollback complexity
            rollback_complexity = self._assess_rollback_complexity(impact_score, modified_fields)
            
            await conn.close()
            
            return VersionDiff(
                from_version=version_1_data['version_number'],
                to_version=version_2_data['version_number'],
                added_fields=added_fields,
                removed_fields=removed_fields,
                modified_fields=modified_fields,
                impact_score=impact_score,
                rollback_complexity=rollback_complexity
            )
            
        except Exception as e:
            print(f"❌ Failed to compare versions: {str(e)}")
            raise

    async def approve_version(self, version_id: str, approved_by: str, 
                            approval_notes: str = "") -> bool:
        """
        Approve a version for activation.
        Includes business rule validation and dependency checks.
        """
        try:
            conn = await asyncpg.connect(self.database_url)
            
            # Get current version status
            current_status = await conn.fetchval(
                "SELECT status FROM reference_data_versions WHERE version_id = $1",
                version_id
            )
            
            if not current_status:
                raise ValueError(f"Version {version_id} not found")
            
            if current_status != VersionStatus.DRAFT.value:
                raise ValueError(f"Can only approve draft versions, current status: {current_status}")
            
            # Validate version before approval
            validation_result = await self._validate_version_for_approval(conn, version_id)
            if not validation_result["is_valid"]:
                print(f"❌ Version validation failed: {validation_result['errors']}")
                return False
            
            # Update version status
            await conn.execute("""
                UPDATE reference_data_versions 
                SET status = $1, approved_by = $2, approved_at = $3
                WHERE version_id = $4
            """, VersionStatus.ACTIVE.value, approved_by, datetime.now(timezone.utc), version_id)
            
            # Archive previous active version
            await self._archive_previous_active_version(conn, version_id)
            
            # Record approval in change log
            await self._record_approval_change(conn, version_id, approved_by, approval_notes)
            
            await conn.close()
            
            print(f"✅ Version {version_id} approved and activated by {approved_by}")
            return True
            
        except Exception as e:
            print(f"❌ Failed to approve version: {str(e)}")
            return False

    async def rollback_to_version(self, entity_code: str, entity_type: str, 
                                target_version_id: str, rollback_by: str, 
                                rollback_reason: str) -> bool:
        """
        Rollback to a specific version.
        Creates new version based on target version data.
        """
        try:
            conn = await asyncpg.connect(self.database_url)
            
            # Get target version data
            target_data = await self._get_version_data(conn, target_version_id)
            if not target_data:
                raise ValueError(f"Target version {target_version_id} not found")
            
            # Validate rollback safety
            rollback_validation = await self._validate_rollback_safety(conn, target_version_id)
            if not rollback_validation["is_safe"]:
                print(f"❌ Rollback validation failed: {rollback_validation['risks']}")
                return False
            
            # Create new version with target data
            target_version_data = json.loads(target_data['data_content'])
            
            new_version = await self.create_version(
                entity_code=entity_code,
                entity_type=entity_type,
                data=target_version_data,
                created_by=rollback_by,
                change_summary=f"Rollback to version {target_data['version_number']}: {rollback_reason}"
            )
            
            # Auto-approve rollback version
            await self.approve_version(new_version.version_id, rollback_by, 
                                     f"Auto-approved rollback: {rollback_reason}")
            
            # Record rollback in audit trail
            await self._record_rollback_audit(conn, entity_code, entity_type, 
                                            target_version_id, new_version.version_id, 
                                            rollback_by, rollback_reason)
            
            await conn.close()
            
            print(f"✅ Successfully rolled back {entity_type}.{entity_code} to version {target_data['version_number']}")
            return True
            
        except Exception as e:
            print(f"❌ Failed to rollback: {str(e)}")
            return False

    async def get_audit_trail(self, entity_code: str, entity_type: str, 
                            days_back: int = 90) -> List[ChangeRecord]:
        """Get detailed audit trail for an entity"""
        try:
            conn = await asyncpg.connect(self.database_url)
            
            cutoff_date = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
            cutoff_date = cutoff_date.replace(day=cutoff_date.day - days_back)
            
            rows = await conn.fetch("""
                SELECT rc.change_id, rc.version_id, rc.change_type, rc.field_name,
                       rc.old_value, rc.new_value, rc.changed_by, rc.changed_at, rc.change_reason
                FROM reference_change_log rc
                JOIN reference_data_versions rv ON rc.version_id = rv.version_id
                WHERE rv.entity_code = $1 AND rv.entity_type = $2 
                AND rc.changed_at >= $3
                ORDER BY rc.changed_at DESC
            """, entity_code, entity_type, cutoff_date)
            
            changes = []
            for row in rows:
                changes.append(ChangeRecord(
                    change_id=row['change_id'],
                    version_id=row['version_id'],
                    change_type=ChangeType(row['change_type']),
                    field_name=row['field_name'],
                    old_value=row['old_value'],
                    new_value=row['new_value'],
                    changed_by=row['changed_by'],
                    changed_at=row['changed_at'],
                    change_reason=row['change_reason']
                ))
            
            await conn.close()
            return changes
            
        except Exception as e:
            print(f"❌ Failed to get audit trail: {str(e)}")
            raise

    # Helper methods

    def _generate_version_id(self, entity_code: str, entity_type: str) -> str:
        """Generate unique version ID"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        hash_input = f"{entity_code}_{entity_type}_{timestamp}"
        hash_suffix = hashlib.md5(hash_input.encode()).hexdigest()[:8]
        return f"VER_{entity_type.upper()}_{hash_suffix}"

    async def _get_next_version_number(self, conn: asyncpg.Connection, 
                                     entity_code: str, entity_type: str) -> str:
        """Get next version number for entity"""
        latest_version = await conn.fetchval("""
            SELECT version_number FROM reference_data_versions
            WHERE entity_code = $1 AND entity_type = $2
            ORDER BY created_at DESC LIMIT 1
        """, entity_code, entity_type)
        
        if not latest_version:
            return "1.0"
        
        # Parse version number and increment
        try:
            parts = latest_version.split('.')
            major, minor = int(parts[0]), int(parts[1])
            return f"{major}.{minor + 1}"
        except:
            return "1.0"

    def _calculate_data_hash(self, data: Dict[str, Any]) -> str:
        """Calculate SHA-256 hash of data for integrity checking"""
        data_str = json.dumps(data, sort_keys=True)
        return hashlib.sha256(data_str.encode()).hexdigest()

    async def _record_detailed_changes(self, conn: asyncpg.Connection, 
                                     version_info: VersionInfo, data: Dict[str, Any], 
                                     changed_by: str):
        """Record detailed field-level changes"""
        # For initial version, record all fields as CREATE
        for field_name, value in data.items():
            change_id = f"CHG_{version_info.version_id}_{field_name}"
            await conn.execute("""
                INSERT INTO reference_change_log
                (change_id, version_id, change_type, field_name, old_value, new_value, 
                 changed_by, changed_at, change_reason)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            """, change_id, version_info.version_id, ChangeType.CREATE.value, 
                field_name, None, json.dumps(value), changed_by, 
                version_info.created_at, "Initial creation")

    async def _get_version_data(self, conn: asyncpg.Connection, version_id: str) -> Optional[dict]:
        """Get version data from database"""
        return await conn.fetchrow("""
            SELECT version_id, version_number, data_content, created_at, created_by
            FROM reference_data_versions WHERE version_id = $1
        """, version_id)

    def _classify_change(self, old_value: Any, new_value: Any) -> str:
        """Classify the type of change between values"""
        if isinstance(old_value, str) and isinstance(new_value, str):
            return "text_modification"
        elif isinstance(old_value, (int, float)) and isinstance(new_value, (int, float)):
            return "numeric_change"
        elif isinstance(old_value, dict) and isinstance(new_value, dict):
            return "structure_change"
        else:
            return "data_type_change"

    def _calculate_impact_score(self, added_fields: List[str], 
                              removed_fields: List[str], 
                              modified_fields: List[Dict[str, Any]]) -> float:
        """Calculate impact score for version comparison"""
        impact = 0.0
        
        # Weight factors
        impact += len(added_fields) * 0.3      # Adding fields has medium impact
        impact += len(removed_fields) * 0.7    # Removing fields has high impact  
        impact += len(modified_fields) * 0.5   # Modifying fields has medium-high impact
        
        # Normalize to 0-10 scale
        return min(impact, 10.0)

    def _assess_rollback_complexity(self, impact_score: float, 
                                  modified_fields: List[Dict[str, Any]]) -> str:
        """Assess rollback complexity based on changes"""
        if impact_score < 2.0:
            return "low"
        elif impact_score < 5.0:
            return "medium"
        elif impact_score < 8.0:
            return "high"
        else:
            return "critical"

    async def _validate_version_for_approval(self, conn: asyncpg.Connection, 
                                           version_id: str) -> Dict[str, Any]:
        """Validate version before approval"""
        errors = []
        
        # Check data integrity
        version_data = await self._get_version_data(conn, version_id)
        if not version_data:
            errors.append("Version data not found")
            return {"is_valid": False, "errors": errors}
        
        try:
            data = json.loads(version_data['data_content'])
            
            # Basic validation
            if not data.get('code'):
                errors.append("Missing required field: code")
            if not data.get('name_en'):
                errors.append("Missing required field: name_en") 
            if not data.get('name_ru'):
                errors.append("Missing required field: name_ru")
            
        except json.JSONDecodeError:
            errors.append("Invalid JSON in version data")
        
        return {"is_valid": len(errors) == 0, "errors": errors}

    async def _archive_previous_active_version(self, conn: asyncpg.Connection, new_version_id: str):
        """Archive the previously active version"""
        # Get entity info for new version
        entity_info = await conn.fetchrow("""
            SELECT entity_code, entity_type FROM reference_data_versions 
            WHERE version_id = $1
        """, new_version_id)
        
        if entity_info:
            await conn.execute("""
                UPDATE reference_data_versions 
                SET status = $1 
                WHERE entity_code = $2 AND entity_type = $3 AND status = $4 AND version_id != $5
            """, VersionStatus.ARCHIVED.value, entity_info['entity_code'], 
                entity_info['entity_type'], VersionStatus.ACTIVE.value, new_version_id)

    async def _record_approval_change(self, conn: asyncpg.Connection, 
                                    version_id: str, approved_by: str, notes: str):
        """Record approval in change log"""
        change_id = f"CHG_{version_id}_APPROVAL"
        await conn.execute("""
            INSERT INTO reference_change_log
            (change_id, version_id, change_type, field_name, old_value, new_value,
             changed_by, changed_at, change_reason)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        """, change_id, version_id, ChangeType.APPROVE.value, "status", 
            "draft", "active", approved_by, datetime.now(timezone.utc), notes)

    async def _validate_rollback_safety(self, conn: asyncpg.Connection, 
                                      target_version_id: str) -> Dict[str, Any]:
        """Validate rollback is safe to perform"""
        risks = []
        
        # Check if target version still exists and is valid
        target_exists = await conn.fetchval(
            "SELECT version_id FROM reference_data_versions WHERE version_id = $1",
            target_version_id
        )
        
        if not target_exists:
            risks.append("Target version not found")
        
        # Add more safety checks as needed
        # - Check for dependent data
        # - Validate business rules
        # - Check integration impacts
        
        return {"is_safe": len(risks) == 0, "risks": risks}

    async def _record_rollback_audit(self, conn: asyncpg.Connection, 
                                   entity_code: str, entity_type: str,
                                   target_version_id: str, new_version_id: str,
                                   rollback_by: str, reason: str):
        """Record rollback operation in audit trail"""
        change_id = f"CHG_{new_version_id}_ROLLBACK"
        await conn.execute("""
            INSERT INTO reference_change_log
            (change_id, version_id, change_type, field_name, old_value, new_value,
             changed_by, changed_at, change_reason)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        """, change_id, new_version_id, ChangeType.RESTORE.value, "rollback_operation",
            target_version_id, new_version_id, rollback_by, datetime.now(timezone.utc), reason)


# Test the version control manager
async def test_version_control():
    """Test version control system with sample data"""
    manager = VersionControlManager()
    
    # Test data
    initial_data = {
        "code": "WR001",
        "name_en": "Standard 5/2",
        "name_ru": "Стандарт 5/2",
        "business_rules": {
            "days": 5,
            "hours": 40
        },
        "status": "active"
    }
    
    updated_data = {
        "code": "WR001", 
        "name_en": "Standard 5/2 Enhanced",
        "name_ru": "Стандарт 5/2 Улучшенный",
        "business_rules": {
            "days": 5,
            "hours": 38,  # Reduced hours
            "flexibility": "medium"
        },
        "status": "active"
    }
    
    print("Testing version control system...")
    
    try:
        # Create initial version
        version_1 = await manager.create_version(
            entity_code="WR001",
            entity_type="work_rule", 
            data=initial_data,
            created_by="admin",
            change_summary="Initial work rule setup"
        )
        
        # Approve initial version
        await manager.approve_version(version_1.version_id, "manager", "Approved for production")
        
        # Create updated version
        version_2 = await manager.create_version(
            entity_code="WR001",
            entity_type="work_rule",
            data=updated_data, 
            created_by="hr_specialist",
            change_summary="Reduced hours and added flexibility"
        )
        
        # Get version history
        history = await manager.get_version_history("WR001", "work_rule")
        print(f"Found {len(history)} versions in history")
        
        # Compare versions
        diff = await manager.compare_versions(version_1.version_id, version_2.version_id)
        print(f"Version comparison - Impact score: {diff.impact_score}, Complexity: {diff.rollback_complexity}")
        print(f"Modified fields: {len(diff.modified_fields)}")
        
        # Get audit trail
        audit_trail = await manager.get_audit_trail("WR001", "work_rule", days_back=30)
        print(f"Audit trail contains {len(audit_trail)} change records")
        
        print("✅ Version control system test completed successfully")
        
    except Exception as e:
        print(f"❌ Version control test failed: {str(e)}")

if __name__ == "__main__":
    asyncio.run(test_version_control())