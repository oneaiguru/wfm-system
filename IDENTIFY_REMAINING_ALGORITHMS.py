#!/usr/bin/env python3
"""
Identify which algorithms still need Mobile Workforce Scheduler pattern application
"""

import os
import re
from pathlib import Path

def check_for_mock_patterns(file_path):
    """Check if file contains mock patterns that need fixing"""
    mock_indicators = [
        r'random\.uniform\(',
        r'np\.random\.',
        r'mock.*=.*True',
        r'fake.*data',
        r'simulated.*data',
        r'# TODO.*mock',
        r'Mock[A-Z]\w*\(',
        r'generate.*mock',
        r'create.*fake'
    ]
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            for pattern in mock_indicators:
                if re.search(pattern, content, re.IGNORECASE):
                    return True
    except:
        pass
    return False

def identify_remaining_algorithms():
    """Identify algorithms that still need fixing"""
    algorithms_dir = Path("src/algorithms")
    remaining = []
    
    # Categories to check
    categories = {
        "intraday": ["multi_skill_optimizer.py", "statistics_engine.py", "timetable_generator.py"],
        "multisite": ["communication_manager.py", "multilocation_scheduler.py"], 
        "optimization": ["constraint_validator.py", "cost_optimizer.py", "erlang_c_cache.py", 
                        "erlang_c_precompute_enhanced.py", "linear_programming_cost_calculator.py",
                        "multi_skill_allocation.py", "schedule_scorer.py"],
        "core": ["multi_skill_accuracy_demo.py", "real_time_erlang_optimizer.py"],
        "ml": ["auto_learning_patterns_demo.py"],
        "analytics": ["advanced_reporting.py"],
        "russian": ["zup_integration_service.py"],
        "workflows": ["automation_orchestrator.py"],
        "runner": ["runner.py"]
    }
    
    for category, files in categories.items():
        category_dir = algorithms_dir / category
        for file in files:
            file_path = category_dir / file
            if file_path.exists():
                has_mock = check_for_mock_patterns(file_path)
                remaining.append({
                    'category': category,
                    'file': file,
                    'path': str(file_path),
                    'has_mock_patterns': has_mock,
                    'priority': 'high' if has_mock else 'medium'
                })
    
    return remaining

if __name__ == "__main__":
    remaining = identify_remaining_algorithms()
    
    print(f"🎯 REMAINING ALGORITHMS TO FIX: {len(remaining)}")
    print("=" * 60)
    
    by_category = {}
    for algo in remaining:
        cat = algo['category']
        if cat not in by_category:
            by_category[cat] = []
        by_category[cat].append(algo)
    
    total_high_priority = sum(1 for a in remaining if a['priority'] == 'high')
    
    for category, algorithms in by_category.items():
        print(f"\n📁 {category.upper()}: {len(algorithms)} algorithms")
        for algo in algorithms:
            priority_icon = "🔥" if algo['priority'] == 'high' else "📋"
            mock_status = "HAS MOCKS" if algo['has_mock_patterns'] else "Check needed"
            print(f"   {priority_icon} {algo['file']} - {mock_status}")
    
    print(f"\n📊 SUMMARY:")
    print(f"   High Priority (with mock patterns): {total_high_priority}")
    print(f"   Total algorithms to fix: {len(remaining)}")