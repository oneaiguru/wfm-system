"""
Analytics Algorithms Module
===========================

Advanced analytics algorithms for WFM system with real database integration.
Provides statistical analysis, trend detection, optimization recommendations,
and competitive benchmarking capabilities.

All algorithms use real data from PostgreSQL Schema 001.
"""

from .performance_correlation_analyzer_real import PerformanceCorrelationAnalyzerReal
from .trend_detection_engine_real import TrendDetectionEngineReal
from .efficiency_optimization_recommender_real import EfficiencyOptimizationRecommenderReal
from .competitive_benchmarking_engine_real import CompetitiveBenchmarkingEngineReal

__all__ = [
    'PerformanceCorrelationAnalyzerReal',
    'TrendDetectionEngineReal',
    'EfficiencyOptimizationRecommenderReal',
    'CompetitiveBenchmarkingEngineReal'
]