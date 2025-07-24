"""
SPEC-17: Reference Data Configuration Validation Engine
BDD File: 17-reference-data-management-configuration.feature

Enterprise-grade validation for reference data configurations with multi-language support.
Built for REAL database integration with PostgreSQL schema validation.
Performance target: <50ms per validation operation.
"""

import asyncio
import json
import re
from datetime import datetime
from typing import Dict, List, Any, Optional, Union, Tuple
from dataclasses import dataclass, asdict
from enum import Enum
import asyncpg

class ValidationSeverity(Enum):
    """Validation result severity levels"""
    INFO = "info"
    WARNING = "warning" 
    ERROR = "error"
    CRITICAL = "critical"

class ReferenceDataType(Enum):
    """Supported reference data types"""
    WORK_RULE = "work_rule"
    ABSENCE_CODE = "absence_code"
    DEPARTMENT = "department"
    SERVICE_LEVEL = "service_level"
    BUSINESS_RULE = "business_rule"
    INTEGRATION_MAPPING = "integration_mapping"

@dataclass
class ValidationResult:
    """Validation result for reference data configuration"""
    is_valid: bool
    severity: ValidationSeverity
    rule_id: str
    message: str
    field: Optional[str] = None
    suggested_fix: Optional[str] = None
    russian_message: Optional[str] = None

@dataclass
class ConfigurationItem:
    """Reference data configuration item"""
    code: str
    name_en: str
    name_ru: str
    data_type: ReferenceDataType
    business_rules: Dict[str, Any]
    status: str = "active"
    parent_code: Optional[str] = None
    sort_order: int = 0
    integration_codes: Optional[Dict[str, str]] = None

class ConfigValidationEngine:
    """
    Enterprise configuration validation engine for reference data management.
    Validates all reference data types with comprehensive business rule enforcement.
    """

    def __init__(self, database_url: str = "postgresql://postgres:password@localhost:5432/wfm_enterprise"):
        self.database_url = database_url
        self.validation_rules = self._initialize_validation_rules()
        self.performance_target_ms = 50

    def _initialize_validation_rules(self) -> Dict[str, Dict[str, Any]]:
        """Initialize validation rules for each reference data type"""
        return {
            "work_rule": {
                "required_fields": ["code", "name_en", "name_ru", "business_rules"],
                "code_pattern": r"^WR\d{3}$",
                "business_rule_schema": {
                    "required": ["days", "hours"],
                    "optional": ["pattern", "min", "max", "restrictions"]
                },
                "max_hours_per_week": 60,
                "russian_patterns": {
                    "standard": r"Стандарт \d/\d",
                    "shift": r"Сменный \d/\d", 
                    "flexible": r"Гибкий"
                }
            },
            "absence_code": {
                "required_fields": ["code", "name_en", "name_ru", "category", "paid", "documentation"],
                "code_pattern": r"^ABS_[A-Z_]+$",
                "categories": ["Medical Leave", "Personal Leave", "Company Leave", "Training"],
                "1c_mapping_required": True,
                "russian_medical_terms": [
                    "Больничный", "Отпуск", "Командировка", "Обучение"
                ]
            },
            "department": {
                "required_fields": ["code", "name", "parent", "sort_order"],
                "code_pattern": r"^[A-Z_]+$",
                "max_hierarchy_depth": 10,
                "sort_order_unique_per_parent": True
            },
            "service_level": {
                "required_fields": ["code", "name", "target", "time_window", "calculation"],
                "code_pattern": r"^SL_\d+_\d+$",
                "target_range": {"min": 50, "max": 99},
                "time_window_range": {"min": 10, "max": 300}
            },
            "business_rule": {
                "required_fields": ["rule_component", "configuration"],
                "valid_components": ["threshold", "multiplier", "restrictions", "approval_required"],
                "formula_validation": True
            },
            "integration_mapping": {
                "required_fields": ["internal_code", "external_systems"],
                "supported_systems": ["1C_ZUP", "SAP", "Oracle", "Contact_Center"],
                "bidirectional_required": True
            }
        }

    async def validate_configuration(self, config: ConfigurationItem) -> List[ValidationResult]:
        """
        Validate a single configuration item against all applicable rules.
        Target performance: <50ms per validation.
        """
        start_time = datetime.now()
        results = []

        try:
            # Get validation rules for this data type
            rules = self.validation_rules.get(config.data_type.value, {})
            
            # Basic field validation
            results.extend(await self._validate_required_fields(config, rules))
            
            # Code pattern validation
            results.extend(await self._validate_code_pattern(config, rules))
            
            # Multi-language validation
            results.extend(await self._validate_multilingual_fields(config))
            
            # Business rules validation
            results.extend(await self._validate_business_rules(config, rules))
            
            # Database constraint validation
            results.extend(await self._validate_database_constraints(config))
            
            # Integration mapping validation
            if config.integration_codes:
                results.extend(await self._validate_integration_mappings(config, rules))

            # Performance validation
            elapsed_ms = (datetime.now() - start_time).total_seconds() * 1000
            if elapsed_ms > self.performance_target_ms:
                results.append(ValidationResult(
                    is_valid=False,
                    severity=ValidationSeverity.WARNING,
                    rule_id="PERF_001",
                    message=f"Validation took {elapsed_ms:.1f}ms, target is {self.performance_target_ms}ms",
                    suggested_fix="Consider optimizing validation rules or database queries"
                ))

            return results

        except Exception as e:
            return [ValidationResult(
                is_valid=False,
                severity=ValidationSeverity.CRITICAL,
                rule_id="SYS_001",
                message=f"Validation system error: {str(e)}",
                suggested_fix="Check system configuration and database connectivity"
            )]

    async def _validate_required_fields(self, config: ConfigurationItem, rules: Dict[str, Any]) -> List[ValidationResult]:
        """Validate all required fields are present and non-empty"""
        results = []
        required_fields = rules.get("required_fields", [])
        
        config_dict = asdict(config)
        
        for field in required_fields:
            if field not in config_dict or not config_dict[field]:
                results.append(ValidationResult(
                    is_valid=False,
                    severity=ValidationSeverity.ERROR,
                    rule_id="REQ_001",
                    field=field,
                    message=f"Required field '{field}' is missing or empty",
                    russian_message=f"Обязательное поле '{field}' отсутствует или пустое",
                    suggested_fix=f"Provide a valid value for {field}"
                ))
        
        return results

    async def _validate_code_pattern(self, config: ConfigurationItem, rules: Dict[str, Any]) -> List[ValidationResult]:
        """Validate code follows required pattern"""
        results = []
        pattern = rules.get("code_pattern")
        
        if pattern and not re.match(pattern, config.code):
            results.append(ValidationResult(
                is_valid=False,
                severity=ValidationSeverity.ERROR,
                rule_id="CODE_001",
                field="code",
                message=f"Code '{config.code}' doesn't match pattern {pattern}",
                russian_message=f"Код '{config.code}' не соответствует шаблону {pattern}",
                suggested_fix=f"Use format matching pattern {pattern}"
            ))
        
        return results

    async def _validate_multilingual_fields(self, config: ConfigurationItem) -> List[ValidationResult]:
        """Validate multi-language field consistency"""
        results = []
        
        # Check English and Russian names are both present
        if not config.name_en or not config.name_ru:
            results.append(ValidationResult(
                is_valid=False,
                severity=ValidationSeverity.ERROR,
                rule_id="LANG_001",
                message="Both English and Russian names are required",
                russian_message="Требуются названия на английском и русском языках",
                suggested_fix="Provide names in both languages"
            ))
        
        # Validate Russian text encoding
        if config.name_ru:
            try:
                config.name_ru.encode('utf-8')
            except UnicodeEncodeError:
                results.append(ValidationResult(
                    is_valid=False,
                    severity=ValidationSeverity.ERROR,
                    rule_id="LANG_002",
                    field="name_ru",
                    message="Russian name contains invalid UTF-8 characters",
                    russian_message="Русское название содержит недопустимые символы UTF-8",
                    suggested_fix="Use proper UTF-8 encoding for Russian text"
                ))
        
        # Check for reasonable name lengths
        if len(config.name_en) > 100 or len(config.name_ru) > 100:
            results.append(ValidationResult(
                is_valid=False,
                severity=ValidationSeverity.WARNING,
                rule_id="LANG_003",
                message="Name exceeds recommended length of 100 characters",
                russian_message="Название превышает рекомендуемую длину в 100 символов",
                suggested_fix="Consider shorter, more concise names"
            ))
        
        return results

    async def _validate_business_rules(self, config: ConfigurationItem, rules: Dict[str, Any]) -> List[ValidationResult]:
        """Validate business rules configuration"""
        results = []
        
        if not config.business_rules:
            return results
        
        # Validate JSON structure
        try:
            if isinstance(config.business_rules, str):
                json.loads(config.business_rules)
        except json.JSONDecodeError as e:
            results.append(ValidationResult(
                is_valid=False,
                severity=ValidationSeverity.ERROR,
                rule_id="RULE_001",
                field="business_rules",
                message=f"Invalid JSON in business rules: {str(e)}",
                russian_message=f"Недопустимый JSON в бизнес-правилах: {str(e)}",
                suggested_fix="Fix JSON syntax errors"
            ))
            return results
        
        # Type-specific business rule validation
        if config.data_type == ReferenceDataType.WORK_RULE:
            results.extend(await self._validate_work_rule_business_rules(config, rules))
        elif config.data_type == ReferenceDataType.SERVICE_LEVEL:
            results.extend(await self._validate_service_level_rules(config, rules))
        
        return results

    async def _validate_work_rule_business_rules(self, config: ConfigurationItem, rules: Dict[str, Any]) -> List[ValidationResult]:
        """Validate work rule specific business rules"""
        results = []
        br = config.business_rules
        
        # Check required fields for work rules
        schema = rules.get("business_rule_schema", {})
        required = schema.get("required", [])
        
        for field in required:
            if field not in br:
                results.append(ValidationResult(
                    is_valid=False,
                    severity=ValidationSeverity.ERROR,
                    rule_id="WORK_001",
                    message=f"Work rule missing required field: {field}",
                    russian_message=f"В рабочем правиле отсутствует обязательное поле: {field}",
                    suggested_fix=f"Add {field} to business rules"
                ))
        
        # Validate hours per week don't exceed legal limits
        if "hours" in br and br["hours"] > rules.get("max_hours_per_week", 60):
            results.append(ValidationResult(
                is_valid=False,
                severity=ValidationSeverity.ERROR,
                rule_id="WORK_002",
                message=f"Hours per week ({br['hours']}) exceeds legal limit",
                russian_message=f"Часы в неделю ({br['hours']}) превышают законный лимит",
                suggested_fix="Reduce hours to comply with labor regulations"
            ))
        
        return results

    async def _validate_service_level_rules(self, config: ConfigurationItem, rules: Dict[str, Any]) -> List[ValidationResult]:
        """Validate service level specific rules"""
        results = []
        br = config.business_rules
        
        # Validate target percentage is in valid range
        if "target" in br:
            target_range = rules.get("target_range", {"min": 50, "max": 99})
            target = br["target"]
            if target < target_range["min"] or target > target_range["max"]:
                results.append(ValidationResult(
                    is_valid=False,
                    severity=ValidationSeverity.ERROR,
                    rule_id="SL_001",
                    message=f"Service level target {target}% outside valid range {target_range['min']}-{target_range['max']}%",
                    suggested_fix=f"Set target between {target_range['min']}% and {target_range['max']}%"
                ))
        
        return results

    async def _validate_database_constraints(self, config: ConfigurationItem) -> List[ValidationResult]:
        """Validate against existing database constraints"""
        results = []
        
        try:
            conn = await asyncpg.connect(self.database_url)
            
            # Check for code uniqueness
            existing = await conn.fetchval(
                "SELECT code FROM reference_data_multilang WHERE code = $1 AND category = $2",
                config.code, config.data_type.value
            )
            
            if existing:
                results.append(ValidationResult(
                    is_valid=False,
                    severity=ValidationSeverity.ERROR,
                    rule_id="DB_001",
                    field="code",
                    message=f"Code '{config.code}' already exists in {config.data_type.value}",
                    russian_message=f"Код '{config.code}' уже существует в {config.data_type.value}",
                    suggested_fix="Use a unique code or update existing entry"
                ))
            
            # Validate hierarchical relationships for departments
            if config.data_type == ReferenceDataType.DEPARTMENT and config.parent_code:
                parent_exists = await conn.fetchval(
                    "SELECT code FROM reference_data_multilang WHERE code = $1 AND category = 'department'",
                    config.parent_code
                )
                
                if not parent_exists:
                    results.append(ValidationResult(
                        is_valid=False,
                        severity=ValidationSeverity.ERROR,
                        rule_id="DB_002",
                        field="parent_code",
                        message=f"Parent department '{config.parent_code}' does not exist",
                        russian_message=f"Родительский отдел '{config.parent_code}' не существует",
                        suggested_fix="Create parent department first or remove parent reference"
                    ))
            
            await conn.close()
            
        except Exception as e:
            results.append(ValidationResult(
                is_valid=False,
                severity=ValidationSeverity.WARNING,
                rule_id="DB_003",
                message=f"Could not validate database constraints: {str(e)}",
                suggested_fix="Check database connectivity"
            ))
        
        return results

    async def _validate_integration_mappings(self, config: ConfigurationItem, rules: Dict[str, Any]) -> List[ValidationResult]:
        """Validate integration system mappings"""
        results = []
        
        if not config.integration_codes:
            return results
        
        supported_systems = rules.get("supported_systems", [])
        
        for system, code in config.integration_codes.items():
            if system not in supported_systems:
                results.append(ValidationResult(
                    is_valid=False,
                    severity=ValidationSeverity.WARNING,
                    rule_id="INT_001",
                    message=f"Unsupported integration system: {system}",
                    suggested_fix=f"Use one of: {', '.join(supported_systems)}"
                ))
            
            if not code or len(code.strip()) == 0:
                results.append(ValidationResult(
                    is_valid=False,
                    severity=ValidationSeverity.ERROR,
                    rule_id="INT_002",
                    message=f"Empty integration code for system {system}",
                    suggested_fix=f"Provide valid code for {system}"
                ))
        
        return results

    async def validate_bulk_configuration(self, configs: List[ConfigurationItem]) -> Dict[str, List[ValidationResult]]:
        """
        Validate multiple configurations efficiently.
        Returns validation results keyed by configuration code.
        """
        start_time = datetime.now()
        results = {}
        
        # Validate each configuration
        tasks = []
        for config in configs:
            task = asyncio.create_task(self.validate_configuration(config))
            tasks.append((config.code, task))
        
        # Wait for all validations to complete
        for code, task in tasks:
            results[code] = await task
        
        # Add bulk validation specific checks
        results.update(await self._validate_bulk_consistency(configs))
        
        elapsed_ms = (datetime.now() - start_time).total_seconds() * 1000
        print(f"Bulk validation of {len(configs)} items completed in {elapsed_ms:.1f}ms")
        
        return results

    async def _validate_bulk_consistency(self, configs: List[ConfigurationItem]) -> Dict[str, List[ValidationResult]]:
        """Validate consistency across multiple configurations"""
        results = {}
        
        # Check for duplicate codes
        codes_seen = set()
        for config in configs:
            if config.code in codes_seen:
                key = f"BULK_{config.code}"
                results[key] = [ValidationResult(
                    is_valid=False,
                    severity=ValidationSeverity.ERROR,
                    rule_id="BULK_001",
                    message=f"Duplicate code '{config.code}' found in bulk data",
                    suggested_fix="Ensure all codes are unique"
                )]
            codes_seen.add(config.code)
        
        # Validate hierarchical consistency for departments
        dept_configs = [c for c in configs if c.data_type == ReferenceDataType.DEPARTMENT]
        dept_codes = {c.code for c in dept_configs}
        
        for config in dept_configs:
            if config.parent_code and config.parent_code not in dept_codes:
                key = f"BULK_{config.code}_PARENT"
                results[key] = [ValidationResult(
                    is_valid=False,
                    severity=ValidationSeverity.ERROR,
                    rule_id="BULK_002",
                    message=f"Department '{config.code}' references missing parent '{config.parent_code}'",
                    suggested_fix="Include parent department in bulk data or remove parent reference"
                )]
        
        return results

    def get_validation_summary(self, results: List[ValidationResult]) -> Dict[str, Any]:
        """Generate summary statistics for validation results"""
        total = len(results)
        if total == 0:
            return {"status": "valid", "total": 0, "errors": 0, "warnings": 0}
        
        errors = len([r for r in results if r.severity in [ValidationSeverity.ERROR, ValidationSeverity.CRITICAL]])
        warnings = len([r for r in results if r.severity == ValidationSeverity.WARNING])
        
        return {
            "status": "invalid" if errors > 0 else "valid_with_warnings" if warnings > 0 else "valid",
            "total": total,
            "errors": errors,
            "warnings": warnings,
            "error_rate": round(errors / total * 100, 1) if total > 0 else 0,
            "most_common_issues": self._get_most_common_issues(results)
        }

    def _get_most_common_issues(self, results: List[ValidationResult]) -> List[Dict[str, Any]]:
        """Get most common validation issues"""
        issue_counts = {}
        for result in results:
            rule_id = result.rule_id
            if rule_id in issue_counts:
                issue_counts[rule_id]["count"] += 1
            else:
                issue_counts[rule_id] = {
                    "rule_id": rule_id,
                    "message": result.message,
                    "count": 1,
                    "severity": result.severity.value
                }
        
        # Return top 5 most common issues
        return sorted(issue_counts.values(), key=lambda x: x["count"], reverse=True)[:5]


# Test the configuration validation engine
async def test_config_validation():
    """Test configuration validation with sample data"""
    engine = ConfigValidationEngine()
    
    # Test work rule configuration
    work_rule = ConfigurationItem(
        code="WR001",
        name_en="Standard 5/2",
        name_ru="Стандарт 5/2",
        data_type=ReferenceDataType.WORK_RULE,
        business_rules={
            "days": 5,
            "hours": 40,
            "pattern": "weekdays"
        },
        status="active"
    )
    
    # Test absence code configuration
    absence_code = ConfigurationItem(
        code="ABS_SICK_CHILD",
        name_en="Child Sick Leave",
        name_ru="Больничный по уходу за ребенком",
        data_type=ReferenceDataType.ABSENCE_CODE,
        business_rules={
            "category": "Medical Leave",
            "paid": True,
            "documentation": "required"
        },
        integration_codes={
            "1C_ZUP": "Б",
            "SAP": "SICK",
            "Oracle": "5020"
        }
    )
    
    print("Testing configuration validation...")
    
    # Validate individual configurations
    work_rule_results = await engine.validate_configuration(work_rule)
    absence_results = await engine.validate_configuration(absence_code)
    
    print(f"Work rule validation: {len(work_rule_results)} issues found")
    for result in work_rule_results:
        print(f"  - {result.severity.value}: {result.message}")
    
    print(f"Absence code validation: {len(absence_results)} issues found")
    for result in absence_results:
        print(f"  - {result.severity.value}: {result.message}")
    
    # Test bulk validation
    bulk_results = await engine.validate_bulk_configuration([work_rule, absence_code])
    print(f"Bulk validation completed for {len(bulk_results)} items")
    
    # Generate summary
    all_results = work_rule_results + absence_results
    summary = engine.get_validation_summary(all_results)
    print(f"Validation summary: {summary}")

if __name__ == "__main__":
    asyncio.run(test_config_validation())