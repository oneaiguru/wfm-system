#!/usr/bin/env python3
"""
Mobile Workforce Scheduler Pattern - Example Usage
Demonstrates real multi-skill allocation using database integration
"""

import asyncio
import logging
import sys
from datetime import datetime, timedelta
from pathlib import Path

# Add project root to Python path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from algorithms.optimization.multi_skill_allocation import MultiSkillAllocator

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


async def demonstrate_basic_allocation():
    """Demonstrate basic multi-skill allocation with real data."""
    logger.info("🚀 Mobile Workforce Scheduler - Basic Allocation Example")
    logger.info("=" * 60)
    
    # Initialize the allocator
    allocator = MultiSkillAllocator()
    await allocator.initialize()
    
    try:
        # Run optimization with default settings
        logger.info("📊 Running multi-skill allocation optimization...")
        
        result = await allocator.optimize_allocation({
            'optimization_method': 'greedy'
        })
        
        # Display results
        logger.info(f"✅ Optimization completed successfully!")
        logger.info(f"💰 Total cost: ${result.total_cost:.2f}")
        logger.info(f"⚡ Efficiency score: {result.efficiency_score:.3f}")
        logger.info(f"🎯 Service levels achieved:")
        
        for skill, level in result.service_level_achieved.items():
            status = "✅" if level >= 0.8 else "⚠️" if level >= 0.6 else "❌"
            logger.info(f"   {status} {skill}: {level:.1%}")
        
        logger.info(f"📈 Skill coverage:")
        for skill, coverage in result.skill_coverage.items():
            status = "✅" if coverage >= 0.8 else "⚠️" if coverage >= 0.6 else "❌"
            logger.info(f"   {status} {skill}: {coverage:.1%}")
        
        # Show agent allocations
        active_allocations = {k: v for k, v in result.agent_allocations.items() 
                            if sum(v.values()) > 0}
        
        logger.info(f"👥 Agent allocations ({len(active_allocations)} active):")
        for agent_id, skills in active_allocations.items():
            total_hours = sum(skills.values())
            skill_list = [f"{skill}: {hours:.1f}h" for skill, hours in skills.items() if hours > 0]
            logger.info(f"   Agent {agent_id[:8]}...: {total_hours:.1f}h total ({', '.join(skill_list)})")
        
        return result
        
    finally:
        await allocator.close()


async def demonstrate_cost_optimization():
    """Demonstrate cost analysis and optimization."""
    logger.info("\n💼 Mobile Workforce Scheduler - Cost Optimization Example")
    logger.info("=" * 60)
    
    allocator = MultiSkillAllocator()
    await allocator.initialize()
    
    try:
        # Run optimization
        result = await allocator.optimize_allocation({
            'optimization_method': 'greedy'
        })
        
        # Get detailed cost analysis
        data = await allocator._load_real_data(None, None)
        cost_impact = await allocator.calculate_cost_impact(result, data['allocation_constraints'])
        
        # Display cost analysis
        logger.info("💰 Cost Impact Analysis:")
        logger.info(f"   📊 Baseline cost (all full-time): ${cost_impact['baseline_cost']:.2f}")
        logger.info(f"   🎯 Optimized cost: ${cost_impact['optimized_cost']:.2f}")
        logger.info(f"   💵 Cost savings: ${cost_impact['cost_savings']:.2f}")
        logger.info(f"   📉 Savings percentage: {cost_impact['savings_percentage']:.1f}%")
        
        roi = cost_impact['roi_analysis']
        logger.info(f"📈 ROI Analysis:")
        logger.info(f"   💻 Implementation cost: ${roi['implementation_cost']:.2f}")
        logger.info(f"   💰 Annual savings: ${roi['annual_savings']:.2f}")
        
        if roi['payback_period_months'] != float('inf'):
            logger.info(f"   ⏰ Payback period: {roi['payback_period_months']:.1f} months")
        else:
            logger.info(f"   ⏰ Immediate ROI - no payback period needed")
        
        return cost_impact
        
    finally:
        await allocator.close()


async def demonstrate_performance_tracking():
    """Demonstrate performance metrics and tracking."""
    logger.info("\n📊 Mobile Workforce Scheduler - Performance Tracking Example")
    logger.info("=" * 60)
    
    allocator = MultiSkillAllocator()
    await allocator.initialize()
    
    try:
        # Run optimization
        result = await allocator.optimize_allocation({
            'optimization_method': 'greedy'
        })
        
        # Calculate detailed performance metrics
        service_targets = {
            'Customer Service': 0.85,
            'Technical Support': 0.80,
            'Sales': 0.75,
            'Billing Support': 0.80,
            'Chat Support': 0.90
        }
        
        metrics = await allocator.calculate_performance_metrics(result, service_targets)
        
        # Display performance metrics
        logger.info("🎯 Performance Metrics:")
        logger.info(f"   ⚡ Overall efficiency: {metrics['overall_efficiency']:.3f}")
        logger.info(f"   💰 Total cost: ${metrics['total_cost']:.2f}")
        
        logger.info("📈 Service Level Compliance:")
        compliant_skills = 0
        for skill, compliance_data in metrics['service_level_compliance'].items():
            status = "✅" if compliance_data['status'] == 'compliant' else "❌"
            if compliance_data['status'] == 'compliant':
                compliant_skills += 1
            
            logger.info(f"   {status} {skill}:")
            logger.info(f"      Target: {compliance_data['target']:.1%}")
            logger.info(f"      Achieved: {compliance_data['achieved']:.1%}")
            logger.info(f"      Compliance: {compliance_data['compliance']:.1%}")
        
        logger.info(f"📊 Overall compliance: {compliant_skills}/{len(service_targets)} skills compliant")
        
        # Agent utilization analysis
        high_util = sum(1 for data in metrics['agent_utilization'].values() 
                       if data['utilization_percentage'] >= 0.8)
        medium_util = sum(1 for data in metrics['agent_utilization'].values() 
                         if 0.5 <= data['utilization_percentage'] < 0.8)
        low_util = sum(1 for data in metrics['agent_utilization'].values() 
                      if 0 < data['utilization_percentage'] < 0.5)
        unused = sum(1 for data in metrics['agent_utilization'].values() 
                    if data['utilization_percentage'] == 0)
        
        total_agents = len(metrics['agent_utilization'])
        
        logger.info("👥 Agent Utilization Summary:")
        logger.info(f"   🔴 High utilization (≥80%): {high_util}/{total_agents}")
        logger.info(f"   🟡 Medium utilization (50-79%): {medium_util}/{total_agents}")
        logger.info(f"   🟢 Low utilization (1-49%): {low_util}/{total_agents}")
        logger.info(f"   ⚪ Unused: {unused}/{total_agents}")
        
        return metrics
        
    finally:
        await allocator.close()


async def demonstrate_skill_based_allocation():
    """Demonstrate skill proficiency and certification impact."""
    logger.info("\n🎓 Mobile Workforce Scheduler - Skill-Based Allocation Example")
    logger.info("=" * 60)
    
    allocator = MultiSkillAllocator()
    await allocator.initialize()
    
    try:
        # Load employee data to show skill proficiency
        data = await allocator._load_real_data(None, None)
        
        logger.info("👨‍💼 Employee Skill Analysis:")
        
        # Show top performers by skill
        skill_leaders = {}
        for emp_id, emp_data in data['employee_data'].items():
            emp_info = emp_data['employee_info']
            emp_name = f"{emp_info['first_name']} {emp_info['last_name']}"
            
            for skill_name, skill_data in emp_data['skills'].items():
                efficiency = data['agent_efficiency'][emp_id][skill_name]
                
                if skill_name not in skill_leaders:
                    skill_leaders[skill_name] = []
                
                skill_leaders[skill_name].append({
                    'name': emp_name,
                    'proficiency': skill_data['proficiency_level'],
                    'certified': skill_data['certified'],
                    'efficiency': efficiency
                })
        
        # Sort and display top performers
        for skill_name, employees in skill_leaders.items():
            employees.sort(key=lambda x: x['efficiency'], reverse=True)
            top_3 = employees[:3]
            
            logger.info(f"🏆 {skill_name} - Top Performers:")
            for i, emp in enumerate(top_3, 1):
                cert_status = "✓ Certified" if emp['certified'] else "○ Not Certified"
                logger.info(f"   {i}. {emp['name']}: "
                          f"Level {emp['proficiency']}/5, {cert_status}, "
                          f"Efficiency: {emp['efficiency']:.2f}")
        
        # Run optimization and show how proficiency affected allocation
        result = await allocator.optimize_allocation()
        
        logger.info("\n🎯 Allocation Results Based on Proficiency:")
        for agent_id, skills in result.agent_allocations.items():
            if sum(skills.values()) > 0:
                emp_data = data['employee_data'][agent_id]
                emp_name = f"{emp_data['employee_info']['first_name']} {emp_data['employee_info']['last_name']}"
                
                logger.info(f"👤 {emp_name}:")
                for skill, hours in skills.items():
                    if hours > 0:
                        skill_info = emp_data['skills'][skill]
                        efficiency = data['agent_efficiency'][agent_id][skill]
                        cert_status = "✓" if skill_info['certified'] else "○"
                        logger.info(f"   {skill}: {hours:.1f}h "
                                  f"(Level {skill_info['proficiency_level']}/5 {cert_status}, "
                                  f"Eff: {efficiency:.2f})")
        
        return result
        
    finally:
        await allocator.close()


async def main():
    """Run comprehensive demonstration of Mobile Workforce Scheduler pattern."""
    logger.info("🌟 Mobile Workforce Scheduler Pattern Demonstration")
    logger.info("Real-time multi-skill allocation with database integration")
    logger.info("=" * 80)
    
    try:
        # Run all demonstrations
        basic_result = await demonstrate_basic_allocation()
        cost_impact = await demonstrate_cost_optimization()
        performance_metrics = await demonstrate_performance_tracking()
        skill_result = await demonstrate_skill_based_allocation()
        
        # Summary
        logger.info("\n" + "=" * 80)
        logger.info("🎉 DEMONSTRATION COMPLETE")
        logger.info("=" * 80)
        logger.info("✅ Successfully demonstrated Mobile Workforce Scheduler pattern")
        logger.info("✅ Real database integration working correctly")
        logger.info("✅ Multi-skill allocation optimization functional")
        logger.info("✅ Cost optimization and ROI analysis complete")
        logger.info("✅ Performance tracking and metrics generation working")
        logger.info("✅ Skill-based proficiency allocation demonstrated")
        
        logger.info(f"\n📊 Key Results:")
        logger.info(f"   💰 Optimized cost: ${basic_result.total_cost:.2f}")
        logger.info(f"   💵 Cost savings: {cost_impact['savings_percentage']:.1f}%")
        logger.info(f"   ⚡ Efficiency score: {basic_result.efficiency_score:.3f}")
        logger.info(f"   📈 Allocation coverage: {basic_result.optimization_metadata['demand_coverage']:.1%}")
        
        logger.info("\n🚀 Ready for production deployment!")
        
    except Exception as e:
        logger.error(f"❌ Demonstration failed: {str(e)}")
        raise


if __name__ == "__main__":
    asyncio.run(main())