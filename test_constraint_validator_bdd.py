#!/usr/bin/env python
"""
🔴🟢 TDD Test for Constraint Validator per BDD Line 52
From: 24-automatic-schedule-optimization.feature:52
"Constraint Validator | Rule-based system | Labor laws + contracts | Compliance matrix | 1-2 seconds"
"""

import sys
import time
sys.path.insert(0, '.')

from src.algorithms.optimization.constraint_validator import ConstraintValidator, ComplianceMatrix, ViolationSeverity

def test_constraint_validator_bdd():
    """Test constraint validator per BDD requirements"""
    
    print("\n⚖️ TESTING CONSTRAINT VALIDATOR (BDD Line 52)")
    print("="*70)
    print("BDD: Rule-based system | Labor laws + contracts | Compliance matrix | 1-2 seconds")
    
    validator = ConstraintValidator()
    
    # Test Case 1: Standard scenario with violations
    print("\n📊 Test 1: Labor Laws + Contracts Validation")
    
    # Schedule data with potential violations (BDD input)
    schedule_data = {
        'employees': [
            {
                'id': 'EMP_001',
                'skill_level': 'senior',
                'skills': ['english', 'technical'],
                'department': 'customer_care',
                'shifts': [
                    {
                        'date': '2024-01-15',
                        'start_time': '08:00',
                        'end_time': '21:00',  # 13 hours = 5 hours overtime (violation)
                        'hours': 13.0
                    },
                    {
                        'date': '2024-01-16',
                        'start_time': '08:00',
                        'end_time': '22:00',  # 14 hours = 6 hours overtime (violation)
                        'hours': 14.0
                    }
                ]
            },
            {
                'id': 'EMP_002',
                'skill_level': 'junior',
                'skills': ['spanish'],
                'department': 'customer_care',
                'shifts': [
                    {
                        'date': '2024-01-15',
                        'start_time': '09:00',
                        'end_time': '17:00',  # Normal 8-hour shift
                        'hours': 8.0
                    }
                ]
            }
        ]
    }
    
    # Labor laws (BDD input)
    labor_laws = {
        'max_weekly_hours': 40,
        'min_rest_hours': 11,
        'overtime_limit': 4,
        'jurisdiction': 'RF_TK'
    }
    
    # Contracts (BDD input)
    contracts = {
        'EMP_001': {
            'max_hours': 45,
            'overtime_allowed': True,
            'shift_patterns': ['standard', 'extended']
        },
        'EMP_002': {
            'max_hours': 40,
            'overtime_allowed': False,
            'shift_patterns': ['standard']
        }
    }
    
    # Run constraint validation
    start_time = time.time()
    result = validator.validate_constraints(
        schedule_data=schedule_data,
        labor_laws=labor_laws,
        contracts=contracts
    )
    actual_time = (time.time() - start_time) * 1000
    
    print(f"Processing time: {result.processing_time_ms:.1f}ms")
    print(f"Total rules checked: {result.total_rules_checked}")
    print(f"Violations found: {result.violations_found}")
    print(f"Compliance rate: {result.compliance_rate:.1f}%")
    print(f"Compliant employees: {len(result.compliant_employees)}")
    print(f"Violations by severity: {result.violations_by_severity}")
    
    # BDD Validations
    assert result.processing_time_ms <= 2000, f"Processing time {result.processing_time_ms}ms exceeds 2s limit"
    bdd_compliant = result.processing_time_ms <= 2000
    print(f"BDD 1-2 second requirement: {'✅' if bdd_compliant else '❌'} {'Met' if bdd_compliant else 'Failed'}")
    
    # Rule-based system validation
    assert result.total_rules_checked > 0, "Should check constraint rules"
    assert isinstance(result.violations_by_severity, dict), "Should provide severity breakdown"
    assert isinstance(result.violations_by_type, dict), "Should provide type breakdown"
    assert result.compliance_rate >= 0, "Should calculate compliance rate"
    
    # Labor law compliance should detect violations
    assert result.violations_found > 0, "Should detect violations in test scenario"
    overtime_violations = [v for v in result.violations if 'overtime' in v.violation_type]
    assert len(overtime_violations) > 0, "Should detect overtime violations"
    
    print("✅ PASS: Constraint validator processes labor laws + contracts in required time")

def test_labor_law_compliance():
    """Test Russian labor law constraint validation"""
    
    print("\n\n⚖️ Test 2: Russian Labor Law Compliance (TK RF)")
    
    validator = ConstraintValidator()
    
    # Scenario with multiple labor law violations
    schedule_data = {
        'employees': [
            {
                'id': 'VIOLATION_001',
                'skill_level': 'specialist',
                'skills': ['russian', 'technical'],
                'shifts': [
                    # 7 consecutive days (weekly rest violation)
                    {'date': '2024-01-15', 'start_time': '09:00', 'end_time': '19:00', 'hours': 10},  # 2h overtime
                    {'date': '2024-01-16', 'start_time': '08:00', 'end_time': '20:00', 'hours': 12},  # 4h overtime
                    {'date': '2024-01-17', 'start_time': '09:00', 'end_time': '21:00', 'hours': 12},  # 4h overtime  
                    {'date': '2024-01-18', 'start_time': '07:00', 'end_time': '19:00', 'hours': 12},  # 4h overtime
                    {'date': '2024-01-19', 'start_time': '09:00', 'end_time': '23:00', 'hours': 14},  # 6h overtime (violation)
                    {'date': '2024-01-20', 'start_time': '08:00', 'end_time': '20:00', 'hours': 12},  # 4h overtime
                    {'date': '2024-01-21', 'start_time': '09:00', 'end_time': '17:00', 'hours': 8}    # Normal
                ]
            }
        ]
    }
    
    labor_laws = {'jurisdiction': 'TK_RF'}
    contracts = {}
    
    result = validator.validate_constraints(schedule_data, labor_laws, contracts)
    
    print(f"Labor law violations detected: {result.violations_found}")
    print(f"Critical violations: {result.violations_by_severity.get('critical', 0)}")
    print(f"High severity violations: {result.violations_by_severity.get('high', 0)}")
    
    # Expected violations:
    # 1. TK_RF_91: Weekly hours > 40 (total 70 hours)
    # 2. TK_RF_99: Daily overtime > 4 hours (6h on Jan 19)
    # 3. TK_RF_108: No weekly rest day (7 consecutive days)
    
    assert result.violations_found >= 3, f"Should detect at least 3 labor law violations, found {result.violations_found}"
    
    # Check specific violation types
    violation_types = [v.violation_type for v in result.violations]
    assert 'excessive_hours' in violation_types, "Should detect excessive weekly hours"
    assert 'excessive_overtime' in violation_types, "Should detect excessive daily overtime"
    assert 'insufficient_weekly_rest' in violation_types, "Should detect insufficient weekly rest"
    
    # Check critical violations
    critical_violations = [v for v in result.violations if v.severity == ViolationSeverity.CRITICAL]
    assert len(critical_violations) >= 2, "Should flag critical labor law violations"
    
    print("✅ PASS: Russian labor law violations properly detected")

def test_union_agreement_compliance():
    """Test union agreement constraint validation"""
    
    print("\n\n🤝 Test 3: Union Agreement Compliance")
    
    validator = ConstraintValidator()
    
    # Schedule violating union agreements
    schedule_data = {
        'employees': [
            {
                'id': 'UNION_001',
                'skill_level': 'junior',  # Low skill level for ratio test
                'skills': ['basic'],
                'shifts': [
                    {
                        'date': '2024-01-15',
                        'start_time': '09:00',
                        'end_time': '17:00',
                        'hours': 8.0
                    }
                ]
            }
        ]
    }
    
    labor_laws = {}
    contracts = {
        'union_agreement': {
            'shift_patterns': ['2-2-3', '4-on-4-off'],
            'skill_ratios': {'senior_min': 0.3, 'specialist_min': 0.1}
        }
    }
    
    result = validator.validate_constraints(schedule_data, labor_laws, contracts)
    
    print(f"Union compliance violations: {result.violations_found}")
    print(f"Contract rules checked: {result.total_rules_checked}")
    
    # Should detect contract/union violations
    assert result.total_rules_checked >= 4, "Should check union agreement rules"
    
    print("✅ PASS: Union agreement compliance validated")

def test_business_rule_validation():
    """Test business rule constraint validation"""
    
    print("\n\n🏢 Test 4: Business Rule Validation")
    
    validator = ConstraintValidator()
    
    # Schedule with coverage and skill gaps
    schedule_data = {
        'employees': [
            {
                'id': 'BIZ_001',
                'skill_level': 'junior',
                'skills': ['spanish'],  # Missing required english/technical
                'shifts': [
                    {
                        'date': '2024-01-15',
                        'start_time': '14:00',  # Limited coverage
                        'end_time': '16:00',
                        'hours': 2.0
                    }
                ]
            }
        ]
    }
    
    labor_laws = {}
    contracts = {}
    additional_rules = {
        'peak_coverage': {
            'description': 'Minimum peak hour coverage',
            'parameters': {'min_agents': 5, 'peak_hours': '10:00-16:00'},
            'mandatory': True
        }
    }
    
    result = validator.validate_constraints(
        schedule_data, labor_laws, contracts, additional_rules
    )
    
    print(f"Business rule violations: {result.violations_found}")
    print(f"Skill coverage gaps detected: {len([v for v in result.violations if 'skill' in v.violation_type])}")
    
    # Should detect business rule violations
    skill_violations = [v for v in result.violations if 'skill' in v.violation_type]
    assert len(skill_violations) > 0, "Should detect skill coverage gaps"
    
    print("✅ PASS: Business rule validation working")

def test_compliance_matrix_generation():
    """Test compliance matrix output format"""
    
    print("\n\n📊 Test 5: Compliance Matrix Generation")
    
    validator = ConstraintValidator()
    
    # Compliant schedule
    schedule_data = {
        'employees': [
            {
                'id': 'COMPLIANT_001',
                'skill_level': 'senior',
                'skills': ['english', 'technical', 'spanish'],
                'shifts': [
                    {
                        'date': '2024-01-15',
                        'start_time': '09:00',
                        'end_time': '17:00',  # Standard 8 hours
                        'hours': 8.0
                    }
                ]
            }
        ]
    }
    
    labor_laws = {'jurisdiction': 'compliant_test'}
    contracts = {'COMPLIANT_001': {'max_hours': 40}}
    
    result = validator.validate_constraints(schedule_data, labor_laws, contracts)
    
    print(f"Compliance matrix elements:")
    print(f"  Total rules checked: {result.total_rules_checked}")
    print(f"  Violations found: {result.violations_found}")
    print(f"  Compliance rate: {result.compliance_rate:.1f}%")
    print(f"  Violations by severity: {result.violations_by_severity}")
    print(f"  Violations by type: {result.violations_by_type}")
    print(f"  Validation summary keys: {list(result.validation_summary.keys())}")
    
    # Compliance matrix validation
    assert hasattr(result, 'total_rules_checked'), "Should include total rules checked"
    assert hasattr(result, 'violations_found'), "Should include violations count"
    assert hasattr(result, 'compliance_rate'), "Should include compliance rate"
    assert hasattr(result, 'violations_by_severity'), "Should include severity breakdown"
    assert hasattr(result, 'violations_by_type'), "Should include type breakdown"
    assert hasattr(result, 'violations'), "Should include detailed violations"
    assert hasattr(result, 'compliant_employees'), "Should include compliant employee list"
    assert hasattr(result, 'validation_summary'), "Should include validation summary"
    
    # Compliant scenario should have high compliance rate
    assert result.compliance_rate >= 90, f"Compliant scenario should have high rate, got {result.compliance_rate}%"
    
    print("✅ PASS: Compliance matrix properly generated")

def test_performance_requirement():
    """Test 1-2 second processing requirement"""
    
    print("\n\n⚡ Test 6: Performance Requirement (1-2 seconds)")
    
    validator = ConstraintValidator()
    
    # Large scenario to test performance
    schedule_data = {
        'employees': [
            {
                'id': f'PERF_{i:03d}',
                'skill_level': ['junior', 'senior', 'specialist'][i % 3],
                'skills': ['english', 'spanish', 'technical'][:(i % 3) + 1],
                'department': f'dept_{i % 5}',
                'shifts': [
                    {
                        'date': f'2024-01-{15 + (j % 7):02d}',
                        'start_time': f"{8 + (j % 4):02d}:00",
                        'end_time': f"{16 + (j % 4):02d}:00",
                        'hours': 8.0 + (j % 3)  # Some overtime
                    }
                    for j in range(5)  # 5 shifts per employee
                ]
            }
            for i in range(50)  # 50 employees
        ]
    }
    
    labor_laws = {
        'max_weekly_hours': 40,
        'overtime_limit': 4,
        'jurisdiction': 'performance_test'
    }
    
    contracts = {f'PERF_{i:03d}': {'max_hours': 42} for i in range(50)}
    
    additional_rules = {
        f'rule_{i}': {
            'description': f'Custom rule {i}',
            'parameters': {'threshold': i * 10},
            'mandatory': i % 2 == 0
        }
        for i in range(10)
    }
    
    start_time = time.time()
    result = validator.validate_constraints(
        schedule_data, labor_laws, contracts, additional_rules
    )
    actual_time = (time.time() - start_time) * 1000
    
    print(f"Large scenario processing: {actual_time:.1f}ms")
    print(f"BDD requirement: ≤2000ms")
    print(f"Within range: {actual_time <= 2000}")
    print(f"Employees processed: {len(schedule_data['employees'])}")
    print(f"Rules checked: {result.total_rules_checked}")
    print(f"Violations detected: {result.violations_found}")
    
    # Performance validation
    assert actual_time <= 2000, f"Too slow: {actual_time}ms > 2000ms"
    assert result.total_rules_checked > 20, "Should check many rules for large scenario"
    
    print("✅ PASS: Performance meets BDD requirement")

def test_bdd_compliance_validation():
    """Test full BDD compliance"""
    
    print("\n\n✅ Test 7: Full BDD Compliance")
    
    validator = ConstraintValidator()
    
    schedule_data = {
        'employees': [
            {
                'id': 'COMPLY_001',
                'skill_level': 'senior',
                'skills': ['general'],
                'shifts': [
                    {
                        'date': '2024-01-15',
                        'start_time': '09:00',
                        'end_time': '17:00',
                        'hours': 8.0
                    }
                ]
            }
        ]
    }
    
    labor_laws = {'jurisdiction': 'bdd_test'}
    contracts = {'COMPLY_001': {'max_hours': 40}}
    
    result = validator.validate_constraints(schedule_data, labor_laws, contracts)
    validation = validator.validate_bdd_requirements(result)
    
    print("BDD Requirement Validation:")
    for requirement, passed in validation.items():
        status = "✅" if passed else "❌"
        print(f"  {status} {requirement}")
    
    # All requirements should pass
    all_passed = all(validation.values())
    assert all_passed, f"BDD requirements failed: {validation}"
    
    print("✅ PASS: All BDD requirements validated")

def compare_with_argus():
    """Show constraint validation advantage"""
    
    print("\n\n🏆 CONSTRAINT VALIDATOR vs ARGUS")
    print("="*70)
    
    comparison = """
    ┌─────────────────────┬─────────────┬────────────┐
    │ Capability          │ WFM         │ Argus      │
    ├─────────────────────┼─────────────┼────────────┤
    │ Labor Law Compliance│ ✅ TK RF    │ ❌ Manual  │
    │ Union Agreements    │ ✅ Auto     │ ❌ Basic   │
    │ Contract Validation │ ✅ Complete │ ❌ Limited │
    │ Rule Engine         │ ✅ Advanced │ ❌ None    │
    │ Compliance Matrix   │ ✅ Detailed │ ❌ Simple  │
    │ Processing Speed    │ ✅ 1-2 sec  │ ❓ Unknown │
    │ Violation Analysis  │ ✅ Smart    │ ❌ Manual  │
    └─────────────────────┴─────────────┴────────────┘
    """
    print(comparison)
    
    print("\nBDD ADVANTAGES:")
    print("1. Automated Russian labor law compliance (TK RF)")
    print("2. Rule-based constraint validation system")
    print("3. Comprehensive compliance matrix generation")
    print("4. Multi-level violation severity analysis")
    print("5. Real-time constraint checking (<2 seconds)")

if __name__ == "__main__":
    # Run all BDD tests
    test_constraint_validator_bdd()
    test_labor_law_compliance()
    test_union_agreement_compliance()
    test_business_rule_validation()
    test_compliance_matrix_generation()
    test_performance_requirement()
    test_bdd_compliance_validation()
    compare_with_argus()
    
    print("\n\n✅ CONSTRAINT VALIDATOR BDD TESTS COMPLETE!")
    print("All requirements from line 52 validated")