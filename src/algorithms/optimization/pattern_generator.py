#!/usr/bin/env python3
"""
Pattern Generator for Automatic Schedule Optimization
BDD File: 24-automatic-schedule-optimization.feature
Scenarios: Genetic Algorithm, Schedule Variants Generation
"""

import numpy as np
import random
from datetime import datetime, timedelta, time
from typing import Dict, List, Optional, Any, Set, Tuple
from dataclasses import dataclass, field
from enum import Enum
import logging
from collections import defaultdict
import time as time_module
from copy import deepcopy

logger = logging.getLogger(__name__)

class PatternType(Enum):
    """Types of schedule patterns"""
    TRADITIONAL = "traditional"      # Standard 8-hour shifts
    FLEXIBLE = "flexible"           # Variable start/end times
    SPLIT_SHIFT = "split_shift"     # Two work periods with break
    COMPRESSED = "compressed"       # Longer days, fewer days
    PART_TIME = "part_time"         # Reduced hours
    STAGGERED = "staggered"         # Overlapping shifts
    WEEKEND_FOCUS = "weekend_focus" # Heavy weekend coverage
    PEAK_FOCUS = "peak_focus"       # Coverage during peak hours

class MutationType(Enum):
    """Types of genetic mutations"""
    SHIFT_TIME = "shift_time"       # Adjust start/end times
    SWAP_AGENTS = "swap_agents"     # Exchange agents between shifts
    ADD_HOURS = "add_hours"         # Extend coverage
    REMOVE_HOURS = "remove_hours"   # Reduce coverage
    SPLIT_SHIFT = "split_shift"     # Break shift into parts
    MERGE_SHIFTS = "merge_shifts"   # Combine adjacent shifts

@dataclass
class ScheduleVariant:
    """Individual schedule variant (chromosome)"""
    variant_id: str
    pattern_type: PatternType
    generation: int
    fitness_score: float
    coverage_improvement: float
    cost_impact: float
    implementation_complexity: float
    schedule_blocks: List[Dict[str, Any]]
    constraint_violations: List[str]
    service_level_projection: float

@dataclass
class GenerationResult:
    """Result of pattern generation process"""
    generation_number: int
    population_size: int
    best_variant: ScheduleVariant
    top_variants: List[ScheduleVariant]
    average_fitness: float
    convergence_rate: float
    processing_time: float

class PatternGenerator:
    """Genetic algorithm for schedule pattern generation (5-8 seconds)"""
    
    def __init__(self):
        self.processing_target = 8.0  # 5-8 seconds from BDD
        self.population_size = 50
        self.max_generations = 20
        self.mutation_rate = 0.1
        self.crossover_rate = 0.8
        self.elite_size = 5
        self.constraint_weights = {
            'coverage': 0.4,
            'cost': 0.3,
            'service_level': 0.2,
            'complexity': 0.1
        }
        
    def generate_schedule_variants(self,
                                 current_schedule: List[Dict[str, Any]],
                                 coverage_gaps: List[Dict[str, Any]],
                                 constraints: Dict[str, Any],
                                 target_improvements: Dict[str, float]) -> List[ScheduleVariant]:
        """Generate optimized schedule variants using genetic algorithm"""
        start_time = time_module.time()
        
        # Initialize population
        population = self._initialize_population(current_schedule, coverage_gaps, constraints)
        
        # Evolution process
        best_variants = []
        generation_results = []
        
        for generation in range(self.max_generations):
            # Evaluate fitness
            population = self._evaluate_fitness(population, coverage_gaps, target_improvements)
            
            # Track best variants
            population.sort(key=lambda x: x.fitness_score, reverse=True)
            best_variants.append(deepcopy(population[0]))
            
            # Check convergence
            if self._check_convergence(generation_results):
                break
            
            # Selection and reproduction
            new_population = self._evolve_population(population)
            population = new_population
            
            # Record generation results
            avg_fitness = sum(v.fitness_score for v in population) / len(population)
            generation_results.append(GenerationResult(
                generation_number=generation,
                population_size=len(population),
                best_variant=population[0],
                top_variants=population[:5],
                average_fitness=avg_fitness,
                convergence_rate=0.0,  # Calculated later
                processing_time=time_module.time() - start_time
            ))
        
        # Final evaluation and selection
        final_variants = self._select_final_variants(population)
        
        processing_time = time_module.time() - start_time
        assert processing_time <= self.processing_target, f"Processing {processing_time:.3f}s exceeds 8s target"
        
        return final_variants
    
    def _initialize_population(self,
                             current_schedule: List[Dict[str, Any]],
                             coverage_gaps: List[Dict[str, Any]],
                             constraints: Dict[str, Any]) -> List[ScheduleVariant]:
        """Initialize population with diverse schedule patterns"""
        population = []
        
        # Pattern distribution
        pattern_counts = {
            PatternType.TRADITIONAL: 10,
            PatternType.FLEXIBLE: 10,
            PatternType.STAGGERED: 8,
            PatternType.SPLIT_SHIFT: 6,
            PatternType.COMPRESSED: 6,
            PatternType.PART_TIME: 5,
            PatternType.PEAK_FOCUS: 3,
            PatternType.WEEKEND_FOCUS: 2
        }
        
        variant_id = 0
        for pattern_type, count in pattern_counts.items():
            for _ in range(count):
                variant = self._create_pattern_variant(
                    variant_id, pattern_type, current_schedule, coverage_gaps, constraints
                )
                population.append(variant)
                variant_id += 1
        
        return population
    
    def _create_pattern_variant(self,
                              variant_id: int,
                              pattern_type: PatternType,
                              current_schedule: List[Dict[str, Any]],
                              coverage_gaps: List[Dict[str, Any]],
                              constraints: Dict[str, Any]) -> ScheduleVariant:
        """Create schedule variant based on pattern type"""
        base_blocks = deepcopy(current_schedule)
        
        if pattern_type == PatternType.TRADITIONAL:
            schedule_blocks = self._apply_traditional_pattern(base_blocks, coverage_gaps)
        elif pattern_type == PatternType.FLEXIBLE:
            schedule_blocks = self._apply_flexible_pattern(base_blocks, coverage_gaps)
        elif pattern_type == PatternType.STAGGERED:
            schedule_blocks = self._apply_staggered_pattern(base_blocks, coverage_gaps)
        elif pattern_type == PatternType.SPLIT_SHIFT:
            schedule_blocks = self._apply_split_shift_pattern(base_blocks, coverage_gaps)
        elif pattern_type == PatternType.COMPRESSED:
            schedule_blocks = self._apply_compressed_pattern(base_blocks, coverage_gaps)
        elif pattern_type == PatternType.PART_TIME:
            schedule_blocks = self._apply_part_time_pattern(base_blocks, coverage_gaps)
        elif pattern_type == PatternType.PEAK_FOCUS:
            schedule_blocks = self._apply_peak_focus_pattern(base_blocks, coverage_gaps)
        elif pattern_type == PatternType.WEEKEND_FOCUS:
            schedule_blocks = self._apply_weekend_focus_pattern(base_blocks, coverage_gaps)
        else:
            schedule_blocks = base_blocks
        
        return ScheduleVariant(
            variant_id=f"VAR_{variant_id:03d}",
            pattern_type=pattern_type,
            generation=0,
            fitness_score=0.0,
            coverage_improvement=0.0,
            cost_impact=0.0,
            implementation_complexity=0.0,
            schedule_blocks=schedule_blocks,
            constraint_violations=[],
            service_level_projection=80.0
        )
    
    def _apply_traditional_pattern(self,
                                 blocks: List[Dict[str, Any]],
                                 gaps: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Apply traditional 8-hour shift pattern"""
        # Standard 8-hour shifts: 8:00-16:00, 16:00-24:00, 24:00-08:00
        modified_blocks = []
        
        for block in blocks:
            modified_block = deepcopy(block)
            
            # Align to traditional shift boundaries
            start_hour = modified_block.get('start_time', '09:00')[:2]
            if start_hour < '08':
                modified_block['start_time'] = '08:00'
                modified_block['end_time'] = '16:00'
            elif start_hour < '16':
                modified_block['start_time'] = '08:00'
                modified_block['end_time'] = '16:00'
            else:
                modified_block['start_time'] = '16:00'
                modified_block['end_time'] = '24:00'
            
            modified_blocks.append(modified_block)
        
        return modified_blocks
    
    def _apply_flexible_pattern(self,
                              blocks: List[Dict[str, Any]],
                              gaps: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Apply flexible start/end times to cover gaps"""
        modified_blocks = []
        
        # Analyze gap times to determine optimal start times
        gap_hours = set()
        for gap in gaps:
            gap_start = gap.get('start_time')
            if gap_start:
                if isinstance(gap_start, str):
                    hour = int(gap_start.split(':')[0])
                else:
                    hour = gap_start.hour
                gap_hours.add(hour)
        
        for block in blocks:
            modified_block = deepcopy(block)
            
            # Adjust start time to cover gaps
            if gap_hours:
                target_hour = min(gap_hours)
                new_start = max(6, target_hour - 1)  # Start 1 hour before gap
                modified_block['start_time'] = f"{new_start:02d}:00"
                modified_block['end_time'] = f"{new_start + 8:02d}:00"
            
            modified_blocks.append(modified_block)
        
        return modified_blocks
    
    def _apply_staggered_pattern(self,
                               blocks: List[Dict[str, Any]],
                               gaps: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Apply staggered overlapping shifts"""
        modified_blocks = []
        
        # Create overlapping shifts
        base_starts = [7, 8, 9, 10, 11, 14, 15, 16]
        
        for i, block in enumerate(blocks):
            modified_block = deepcopy(block)
            
            # Assign staggered start time
            start_hour = base_starts[i % len(base_starts)]
            modified_block['start_time'] = f"{start_hour:02d}:00"
            modified_block['end_time'] = f"{start_hour + 8:02d}:00"
            
            # Add overlap indicator
            modified_block['pattern_type'] = 'staggered'
            modified_block['overlap_shift'] = True
            
            modified_blocks.append(modified_block)
        
        return modified_blocks
    
    def _apply_split_shift_pattern(self,
                                 blocks: List[Dict[str, Any]],
                                 gaps: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Apply split shift pattern with extended breaks"""
        modified_blocks = []
        
        for block in blocks:
            # Split 8-hour shift into 4+4 with 2-hour break
            first_half = deepcopy(block)
            first_half['start_time'] = '08:00'
            first_half['end_time'] = '12:00'
            first_half['shift_part'] = 'first'
            
            second_half = deepcopy(block)
            second_half['start_time'] = '14:00'
            second_half['end_time'] = '18:00'
            second_half['shift_part'] = 'second'
            
            modified_blocks.extend([first_half, second_half])
        
        return modified_blocks
    
    def _apply_compressed_pattern(self,
                                blocks: List[Dict[str, Any]],
                                gaps: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Apply compressed work week (longer days, fewer days)"""
        modified_blocks = []
        
        # 10-hour shifts, 4 days per week
        for block in blocks:
            modified_block = deepcopy(block)
            
            # Extend shift duration
            start_hour = int(modified_block.get('start_time', '08:00')[:2])
            modified_block['start_time'] = f"{start_hour:02d}:00"
            modified_block['end_time'] = f"{start_hour + 10:02d}:00"
            modified_block['compressed_schedule'] = True
            modified_block['days_per_week'] = 4
            
            modified_blocks.append(modified_block)
        
        return modified_blocks
    
    def _apply_part_time_pattern(self,
                               blocks: List[Dict[str, Any]],
                               gaps: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Apply part-time coverage pattern"""
        modified_blocks = []
        
        # 4-6 hour shifts to fill specific gaps
        for i, block in enumerate(blocks):
            modified_block = deepcopy(block)
            
            # Assign part-time hours
            if i % 2 == 0:  # Morning part-time
                modified_block['start_time'] = '08:00'
                modified_block['end_time'] = '12:00'
            else:  # Afternoon part-time
                modified_block['start_time'] = '14:00'
                modified_block['end_time'] = '18:00'
            
            modified_block['part_time'] = True
            modified_blocks.append(modified_block)
        
        return modified_blocks
    
    def _apply_peak_focus_pattern(self,
                                blocks: List[Dict[str, Any]],
                                gaps: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Apply peak hours focused pattern"""
        modified_blocks = []
        
        # Concentrate coverage during identified peak times
        peak_hours = self._identify_peak_hours(gaps)
        
        for block in blocks:
            modified_block = deepcopy(block)
            
            if peak_hours:
                peak_start = min(peak_hours)
                modified_block['start_time'] = f"{max(6, peak_start - 1):02d}:00"
                modified_block['end_time'] = f"{min(22, peak_start + 7):02d}:00"
            
            modified_block['peak_focused'] = True
            modified_blocks.append(modified_block)
        
        return modified_blocks
    
    def _apply_weekend_focus_pattern(self,
                                   blocks: List[Dict[str, Any]],
                                   gaps: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Apply weekend-focused coverage pattern"""
        modified_blocks = []
        
        for block in blocks:
            modified_block = deepcopy(block)
            
            # Adjust for weekend coverage
            modified_block['weekend_priority'] = True
            modified_block['weekday_hours'] = 6  # Reduced weekday hours
            modified_block['weekend_hours'] = 10  # Increased weekend hours
            
            modified_blocks.append(modified_block)
        
        return modified_blocks
    
    def _identify_peak_hours(self, gaps: List[Dict[str, Any]]) -> List[int]:
        """Identify peak hours from gap analysis"""
        hour_gaps = defaultdict(int)
        
        for gap in gaps:
            gap_start = gap.get('start_time')
            if gap_start:
                if isinstance(gap_start, str):
                    hour = int(gap_start.split(':')[0])
                else:
                    hour = gap_start.hour
                hour_gaps[hour] += gap.get('shortage', 1)
        
        # Return hours with highest gap counts
        sorted_hours = sorted(hour_gaps.items(), key=lambda x: x[1], reverse=True)
        return [hour for hour, _ in sorted_hours[:4]]  # Top 4 peak hours
    
    def _evaluate_fitness(self,
                         population: List[ScheduleVariant],
                         coverage_gaps: List[Dict[str, Any]],
                         target_improvements: Dict[str, float]) -> List[ScheduleVariant]:
        """Evaluate fitness of each variant"""
        for variant in population:
            # Calculate coverage improvement
            coverage_score = self._calculate_coverage_score(variant, coverage_gaps)
            
            # Calculate cost impact
            cost_score = self._calculate_cost_score(variant)
            
            # Calculate service level projection
            service_level = self._calculate_service_level(variant, coverage_gaps)
            
            # Calculate implementation complexity
            complexity_score = self._calculate_complexity_score(variant)
            
            # Validate constraints
            violations = self._validate_constraints(variant)
            
            # Calculate weighted fitness score
            fitness = (
                coverage_score * self.constraint_weights['coverage'] +
                cost_score * self.constraint_weights['cost'] +
                service_level * self.constraint_weights['service_level'] +
                complexity_score * self.constraint_weights['complexity']
            )
            
            # Apply penalty for constraint violations
            penalty = len(violations) * 10
            fitness = max(0, fitness - penalty)
            
            # Update variant
            variant.fitness_score = fitness
            variant.coverage_improvement = coverage_score
            variant.cost_impact = 100 - cost_score  # Invert cost score
            variant.service_level_projection = service_level
            variant.implementation_complexity = 100 - complexity_score
            variant.constraint_violations = violations
        
        return population
    
    def _calculate_coverage_score(self, 
                                variant: ScheduleVariant,
                                gaps: List[Dict[str, Any]]) -> float:
        """Calculate coverage improvement score (0-100)"""
        # Simplified coverage calculation
        total_coverage_hours = sum(
            8 for block in variant.schedule_blocks  # Assuming 8-hour blocks
        )
        
        # Base score from coverage hours
        base_score = min(100, total_coverage_hours * 2)
        
        # Bonus for addressing specific gaps
        gap_bonus = 0
        for gap in gaps:
            gap_hour = self._extract_hour_from_gap(gap)
            for block in variant.schedule_blocks:
                block_start = self._extract_hour_from_block(block, 'start_time')
                block_end = self._extract_hour_from_block(block, 'end_time')
                
                if block_start <= gap_hour <= block_end:
                    gap_bonus += 5  # 5 points per gap covered
                    break
        
        return min(100, base_score + gap_bonus)
    
    def _calculate_cost_score(self, variant: ScheduleVariant) -> float:
        """Calculate cost efficiency score (0-100, higher is better)"""
        # Simplified cost calculation
        total_hours = sum(
            8 for block in variant.schedule_blocks  # Base hours
        )
        
        # Cost factors
        overtime_penalty = 0
        complexity_penalty = 0
        
        for block in variant.schedule_blocks:
            # Overtime penalty for extended hours
            if block.get('end_time', '16:00') > '18:00':
                overtime_penalty += 10
            
            # Complexity penalty for split shifts
            if block.get('shift_part'):
                complexity_penalty += 5
        
        base_score = max(10, 100 - (total_hours * 1.5))
        cost_score = max(0, base_score - overtime_penalty - complexity_penalty)
        
        return min(100, cost_score)
    
    def _calculate_service_level(self,
                               variant: ScheduleVariant,
                               gaps: List[Dict[str, Any]]) -> float:
        """Calculate projected service level (0-100)"""
        # Base service level
        base_sl = 80.0
        
        # Improvement from gap coverage
        gaps_covered = 0
        total_gaps = len(gaps)
        
        for gap in gaps:
            gap_hour = self._extract_hour_from_gap(gap)
            for block in variant.schedule_blocks:
                block_start = self._extract_hour_from_block(block, 'start_time')
                block_end = self._extract_hour_from_block(block, 'end_time')
                
                if block_start <= gap_hour <= block_end:
                    gaps_covered += 1
                    break
        
        if total_gaps > 0:
            coverage_ratio = gaps_covered / total_gaps
            sl_improvement = coverage_ratio * 15  # Up to 15% improvement
            return min(95, base_sl + sl_improvement)
        
        return base_sl
    
    def _calculate_complexity_score(self, variant: ScheduleVariant) -> float:
        """Calculate implementation simplicity score (0-100, higher is simpler)"""
        complexity_factors = {
            PatternType.TRADITIONAL: 100,
            PatternType.FLEXIBLE: 80,
            PatternType.STAGGERED: 70,
            PatternType.COMPRESSED: 60,
            PatternType.PART_TIME: 75,
            PatternType.SPLIT_SHIFT: 40,
            PatternType.PEAK_FOCUS: 65,
            PatternType.WEEKEND_FOCUS: 55
        }
        
        base_score = complexity_factors.get(variant.pattern_type, 50)
        
        # Additional complexity from special features
        for block in variant.schedule_blocks:
            if block.get('overlap_shift'):
                base_score -= 5
            if block.get('split_shift'):
                base_score -= 10
            if block.get('compressed_schedule'):
                base_score -= 5
        
        return max(0, min(100, base_score))
    
    def _validate_constraints(self, variant: ScheduleVariant) -> List[str]:
        """Validate schedule variant against constraints"""
        violations = []
        
        # Check minimum coverage requirements
        total_hours = sum(8 for _ in variant.schedule_blocks)  # Simplified
        if total_hours < 40:
            violations.append("Insufficient total coverage hours")
        
        # Check maximum hours per day
        for block in variant.schedule_blocks:
            start_time = block.get('start_time', '08:00')
            end_time = block.get('end_time', '16:00')
            
            start_hour = int(start_time.split(':')[0])
            end_hour = int(end_time.split(':')[0])
            hours = end_hour - start_hour
            
            if hours > 12:
                violations.append(f"Shift exceeds 12-hour limit: {hours} hours")
        
        # Check rest period requirements
        # (Simplified - would need actual schedule analysis)
        
        return violations
    
    def _extract_hour_from_gap(self, gap: Dict[str, Any]) -> int:
        """Extract hour from gap data"""
        gap_start = gap.get('start_time', '09:00')
        if isinstance(gap_start, str):
            return int(gap_start.split(':')[0])
        else:
            return gap_start.hour
    
    def _extract_hour_from_block(self, block: Dict[str, Any], time_field: str) -> int:
        """Extract hour from schedule block"""
        time_str = block.get(time_field, '08:00')
        return int(time_str.split(':')[0])
    
    def _evolve_population(self, population: List[ScheduleVariant]) -> List[ScheduleVariant]:
        """Evolve population through selection, crossover, and mutation"""
        # Sort by fitness
        population.sort(key=lambda x: x.fitness_score, reverse=True)
        
        # Keep elite individuals
        new_population = population[:self.elite_size]
        
        # Generate offspring
        while len(new_population) < self.population_size:
            # Selection
            parent1 = self._tournament_selection(population)
            parent2 = self._tournament_selection(population)
            
            # Crossover
            if random.random() < self.crossover_rate:
                child1, child2 = self._crossover(parent1, parent2)
            else:
                child1, child2 = deepcopy(parent1), deepcopy(parent2)
            
            # Mutation
            if random.random() < self.mutation_rate:
                self._mutate(child1)
            if random.random() < self.mutation_rate:
                self._mutate(child2)
            
            # Update generation
            child1.generation = parent1.generation + 1
            child2.generation = parent2.generation + 1
            
            new_population.extend([child1, child2])
        
        # Trim to population size
        return new_population[:self.population_size]
    
    def _tournament_selection(self, population: List[ScheduleVariant]) -> ScheduleVariant:
        """Tournament selection for parent choice"""
        tournament_size = 3
        tournament = random.sample(population, min(tournament_size, len(population)))
        return max(tournament, key=lambda x: x.fitness_score)
    
    def _crossover(self, parent1: ScheduleVariant, parent2: ScheduleVariant) -> Tuple[ScheduleVariant, ScheduleVariant]:
        """Crossover two parents to create offspring"""
        child1 = deepcopy(parent1)
        child2 = deepcopy(parent2)
        
        # Simple block exchange crossover
        if len(parent1.schedule_blocks) > 2 and len(parent2.schedule_blocks) > 2:
            crossover_point = len(parent1.schedule_blocks) // 2
            
            child1.schedule_blocks = (
                parent1.schedule_blocks[:crossover_point] +
                parent2.schedule_blocks[crossover_point:]
            )
            
            child2.schedule_blocks = (
                parent2.schedule_blocks[:crossover_point] +
                parent1.schedule_blocks[crossover_point:]
            )
        
        # Reset fitness scores
        child1.fitness_score = 0.0
        child2.fitness_score = 0.0
        
        return child1, child2
    
    def _mutate(self, variant: ScheduleVariant):
        """Apply random mutation to variant"""
        if not variant.schedule_blocks:
            return
        
        mutation_type = random.choice(list(MutationType))
        
        if mutation_type == MutationType.SHIFT_TIME:
            # Randomly adjust start/end times
            block = random.choice(variant.schedule_blocks)
            start_hour = int(block.get('start_time', '08:00').split(':')[0])
            adjustment = random.choice([-1, 1])
            new_start = max(6, min(18, start_hour + adjustment))
            block['start_time'] = f"{new_start:02d}:00"
            block['end_time'] = f"{new_start + 8:02d}:00"
            
        elif mutation_type == MutationType.ADD_HOURS:
            # Extend a random block
            block = random.choice(variant.schedule_blocks)
            end_hour = int(block.get('end_time', '16:00').split(':')[0])
            block['end_time'] = f"{min(22, end_hour + 1):02d}:00"
        
        # Reset fitness to force re-evaluation
        variant.fitness_score = 0.0
    
    def _check_convergence(self, generation_results: List[GenerationResult]) -> bool:
        """Check if population has converged"""
        if len(generation_results) < 5:
            return False
        
        # Check if fitness improvement has plateaued
        recent_fitness = [gr.best_variant.fitness_score for gr in generation_results[-5:]]
        improvement = recent_fitness[-1] - recent_fitness[0]
        
        return improvement < 1.0  # Less than 1 point improvement in 5 generations
    
    def _select_final_variants(self, population: List[ScheduleVariant]) -> List[ScheduleVariant]:
        """Select final variants for presentation"""
        # Sort by fitness
        population.sort(key=lambda x: x.fitness_score, reverse=True)
        
        # Select top variants with diversity
        selected = []
        pattern_types_used = set()
        
        for variant in population:
            if len(selected) >= 5:  # Limit to top 5
                break
            
            # Ensure pattern diversity
            if variant.pattern_type not in pattern_types_used or len(selected) < 3:
                selected.append(variant)
                pattern_types_used.add(variant.pattern_type)
        
        return selected