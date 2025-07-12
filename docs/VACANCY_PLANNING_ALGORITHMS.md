# Vacancy Planning Algorithms

## Overview
Vacancy Planning is critical for the Argus demo next week. This module calculates additional staffing needed to cover:
- Planned vacations
- Predicted sick leave
- Training sessions
- Other planned absences

## BDD Specification Reference
From `27-vacancy-planning-module.feature`:
- Calculate coverage for planned absences
- Predict unplanned absences (sick leave)
- Optimize temporary staffing
- Generate coverage recommendations

## Core Algorithms Needed

### 1. Absence Prediction Algorithm
```python
class AbsencePredictor:
    """Predicts unplanned absences based on historical patterns"""
    
    def predict_sick_leave(self, 
                          historical_data: pd.DataFrame,
                          forecast_period: int,
                          seasonality: bool = True) -> Dict[str, float]:
        """
        Predict sick leave rates by day/week
        
        Factors:
        - Historical sick leave patterns
        - Seasonal trends (flu season, holidays)
        - Day of week patterns (Mondays, Fridays)
        - Special events (major sporting events, etc.)
        
        Returns:
            Dict with dates and predicted absence rates (0.0-1.0)
        """
        # Use time series analysis
        # Consider seasonal decomposition
        # Apply ML for pattern recognition
```

### 2. Coverage Calculation Algorithm
```python
class CoverageCalculator:
    """Calculates additional agents needed for coverage"""
    
    def calculate_coverage_needs(self,
                               base_staffing: Dict[str, int],
                               planned_absences: Dict[str, List[str]],
                               predicted_absences: Dict[str, float],
                               service_level_target: float) -> Dict[str, int]:
        """
        Calculate additional agents needed per time period
        
        Formula:
        Coverage_Needed = Base_Staffing × (Planned_Absence_Rate + Predicted_Absence_Rate)
        Adjusted_Coverage = Coverage_Needed × Service_Level_Buffer
        
        Returns:
            Dict with time periods and additional agents needed
        """
```

### 3. Vacation Optimization Algorithm
```python
class VacationOptimizer:
    """Optimizes vacation approvals while maintaining service levels"""
    
    def optimize_vacation_schedule(self,
                                 vacation_requests: List[VacationRequest],
                                 staffing_requirements: Dict[str, int],
                                 constraints: VacationConstraints) -> VacationSchedule:
        """
        Optimize vacation approvals using linear programming
        
        Objective: Maximize approved vacation hours
        Constraints:
        - Maintain minimum staffing levels
        - Respect seniority rules
        - Balance fairness across team
        - Limit concurrent absences
        
        Uses: scipy.optimize.linprog or similar
        """
```

### 4. Training Coverage Algorithm
```python
class TrainingCoverageCalculator:
    """Calculates coverage for training sessions"""
    
    def calculate_training_coverage(self,
                                  training_schedule: List[TrainingSession],
                                  agent_skills: Dict[str, List[str]],
                                  skill_requirements: Dict[str, int]) -> CoverageRequirements:
        """
        Calculate coverage needs during training
        
        Considerations:
        - Skill-specific coverage (can't remove all experts)
        - Training group sizes
        - Overlap prevention (sequential training)
        - Cross-training opportunities
        """
```

## Implementation Approach

### Phase 1: Basic Vacancy Planning (For Demo)
1. **Simple Absence Rate Calculation**
   - Historical average: 5-8% daily absence rate
   - Add 20% buffer for safety
   - Result: Base staffing × 1.25-1.30

2. **Planned Vacation Coverage**
   - Count approved vacations per day
   - Add to base staffing requirements
   - Simple addition, no optimization

3. **Basic UI Integration**
   - Display coverage requirements
   - Show gaps in red
   - Simple approve/deny for requests

### Phase 2: Advanced Features (Post-Demo)
1. **ML-Based Prediction**
   - Train on historical absence data
   - Include external factors (weather, events)
   - Confidence intervals for predictions

2. **Optimization Engine**
   - Linear programming for vacation approval
   - Multi-objective optimization
   - Fairness constraints

3. **Integration with Scheduling**
   - Automatic schedule adjustments
   - Overtime optimization
   - Part-time staff utilization

## Quick Implementation for Demo

```python
# Simple vacancy planning for demo
class SimpleVacancyPlanner:
    def __init__(self, absence_rate: float = 0.08):
        self.absence_rate = absence_rate
        self.buffer = 1.2  # 20% safety buffer
    
    def calculate_total_staffing(self, 
                               base_staffing: int,
                               planned_vacations: int) -> int:
        """Simple calculation for demo"""
        # Account for unplanned absences
        unplanned_coverage = base_staffing * self.absence_rate
        
        # Total needed
        total_needed = base_staffing + planned_vacations + unplanned_coverage
        
        # Apply buffer
        return int(total_needed * self.buffer)
    
    def generate_coverage_report(self,
                               schedule_data: Dict[str, Any]) -> Dict[str, Any]:
        """Generate simple coverage report"""
        results = {}
        
        for date, data in schedule_data.items():
            base = data['base_staffing']
            vacations = data['planned_vacations']
            
            total_needed = self.calculate_total_staffing(base, vacations)
            gap = total_needed - data['scheduled_agents']
            
            results[date] = {
                'base_requirement': base,
                'vacation_coverage': vacations,
                'absence_coverage': int(base * self.absence_rate),
                'total_needed': total_needed,
                'scheduled': data['scheduled_agents'],
                'gap': gap,
                'status': 'OK' if gap <= 0 else 'SHORTAGE'
            }
        
        return results
```

## Integration Points

### With Erlang C
- Use Erlang C to calculate base staffing
- Add vacancy planning on top
- Recalculate service levels with reduced staff

### With ML Forecasting
- Use forecast for base workload
- Apply absence predictions
- Combined forecast for total needs

### With Multi-Skill
- Consider skill-specific absences
- Ensure coverage for critical skills
- Cross-training recommendations

## Performance Targets
- Calculation time: <500ms for weekly planning
- Optimization: <5s for monthly vacation optimization
- Prediction accuracy: >85% for absence prediction

## Next Steps
1. Implement SimpleVacancyPlanner for demo
2. Create UI components for vacancy display
3. Add to API endpoints
4. Test with sample data
5. Prepare demo scenarios