#!/usr/bin/env python3
"""
Analytics Algorithm Service
==========================

INTEGRATION-OPUS ready service wrapper for analytics algorithms with
Redis-optimized forecasting and trend analysis capabilities.

Performance targets:
- Demand forecasting: <200ms for 30-day analysis
- Trend analysis: <100ms for pattern detection
- Health check: <50ms response
- Cache hit rate: >80%

Key features:
- Vectorized analytics operations
- Redis-backed performance optimization
- Real-time KPI calculations
- Multi-service analytics aggregation
"""

import logging
import time
import asyncio
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple
import uuid

from pydantic import BaseModel, Field

from .base_service import (
    AlgorithmServiceBase, ServiceRequest, ServiceResponse,
    service_operation, ServiceException
)

# Import existing optimized analytics algorithms
import sys
sys.path.append('/Users/m/Documents/wfm/main/project/src')

from algorithms.analytics.forecast_demand_redis import DemandForecaster
from algorithms.analytics.analyze_trends_redis import TrendAnalyzer
from algorithms.analytics.analytics_service_redis import AnalyticsServiceRedis

logger = logging.getLogger(__name__)


class ForecastRequest(ServiceRequest):
    """Demand forecasting request model"""
    service_type: str  # 'call_center', 'support', 'sales'
    forecast_days: int = Field(default=30, ge=1, le=365)
    historical_days: int = Field(default=90, ge=30, le=730)
    confidence_level: float = Field(default=0.95, ge=0.5, le=0.99)
    include_seasonality: bool = Field(default=True)
    include_trends: bool = Field(default=True)


class ForecastResponse(ServiceResponse):
    """Demand forecasting response model"""
    forecast_data: List[Dict[str, Any]]
    forecast_accuracy_metrics: Dict[str, float]
    confidence_intervals: List[Tuple[float, float]]
    seasonal_patterns: Dict[str, Any]
    trend_analysis: Dict[str, Any]
    service_type: str
    forecast_days: int


class TrendAnalysisRequest(ServiceRequest):
    """Trend analysis request model"""
    metric_name: str
    time_period_days: int = Field(default=30, ge=7, le=365)
    granularity: str = Field(default="daily")  # hourly, daily, weekly
    detect_anomalies: bool = Field(default=True)
    include_patterns: bool = Field(default=True)


class TrendAnalysisResponse(ServiceResponse):
    """Trend analysis response model"""
    trend_direction: str  # 'increasing', 'decreasing', 'stable', 'volatile'
    trend_strength: float  # 0.0-1.0
    anomalies_detected: List[Dict[str, Any]]
    seasonal_patterns: List[Dict[str, Any]]
    statistical_summary: Dict[str, float]
    recommendations: List[str]
    metric_name: str


class KPICalculationRequest(ServiceRequest):
    """KPI calculation request model"""
    kpi_names: List[str]
    calculation_period: str = Field(default="last_30_days")
    department_ids: Optional[List[int]] = None
    employee_ids: Optional[List[int]] = None
    include_comparisons: bool = Field(default=True)


class KPICalculationResponse(ServiceResponse):
    """KPI calculation response model"""
    kpi_values: Dict[str, float]
    period_comparisons: Dict[str, Dict[str, float]]
    performance_indicators: Dict[str, str]  # 'improving', 'declining', 'stable'
    target_achievement: Dict[str, float]  # Percentage of target achieved
    calculation_period: str


class MultiServiceAnalyticsRequest(ServiceRequest):
    """Multi-service analytics aggregation request"""
    service_types: List[str]
    analysis_types: List[str]  # 'forecast', 'trends', 'kpis'
    date_range: Tuple[str, str]
    aggregation_level: str = Field(default="department")  # employee, team, department, company


class MultiServiceAnalyticsResponse(ServiceResponse):
    """Multi-service analytics response model"""
    aggregated_results: Dict[str, Dict[str, Any]]
    cross_service_insights: List[Dict[str, Any]]
    performance_summary: Dict[str, float]
    recommendations: List[str]
    services_analyzed: int


class AnalyticsService(AlgorithmServiceBase[ForecastRequest, ForecastResponse]):
    """Analytics algorithm service with Redis optimization"""
    
    def __init__(
        self,
        service_name: str = "analytics",
        database_url: Optional[str] = None,
        redis_url: Optional[str] = None,
        config: Optional[Dict[str, Any]] = None
    ):
        super().__init__(service_name, database_url, redis_url, config)
        
        # Initialize core analytics algorithms
        self.demand_forecaster = DemandForecaster(
            redis_url=redis_url,
            database_url=database_url
        )
        
        self.trend_analyzer = TrendAnalyzer(
            redis_url=redis_url,
            database_url=database_url
        )
        
        self.analytics_service = AnalyticsServiceRedis(
            redis_url=redis_url,
            database_url=database_url
        )
        
        # Service configuration
        self.max_forecast_days = config.get('max_forecast_days', 365)
        self.default_confidence_level = config.get('default_confidence_level', 0.95)
        self.cache_forecast_ttl = config.get('cache_forecast_ttl', 1800)  # 30 minutes
        
        logger.info(f"Analytics service initialized with vectorized operations")
    
    async def process(self, request: ForecastRequest) -> ForecastResponse:
        """
        Process demand forecasting request.
        
        Args:
            request: Demand forecasting request
            
        Returns:
            ForecastResponse with forecast data and analysis
        """
        start_time = time.time()
        
        try:
            self._validate_request(request)
            
            # Validate forecast parameters
            if request.forecast_days > self.max_forecast_days:
                raise ServiceException(
                    f"Forecast days exceed maximum: {request.forecast_days} > {self.max_forecast_days}",
                    error_code="FORECAST_DAYS_EXCEEDED"
                )
            
            # Execute forecasting in thread pool
            loop = asyncio.get_event_loop()
            
            forecast_result = await loop.run_in_executor(
                None,
                self._forecast_demand_sync,
                request.service_type,
                request.forecast_days,
                request.historical_days,
                request.confidence_level,
                request.include_seasonality,
                request.include_trends
            )
            
            response_time_ms = (time.time() - start_time) * 1000
            
            return ForecastResponse(
                request_id=request.request_id,
                success=True,
                response_time_ms=response_time_ms,
                cache_hit=forecast_result.get('cache_hit', False),
                forecast_data=forecast_result['forecast_data'],
                forecast_accuracy_metrics=forecast_result['accuracy_metrics'],
                confidence_intervals=forecast_result['confidence_intervals'],
                seasonal_patterns=forecast_result['seasonal_patterns'],
                trend_analysis=forecast_result['trend_analysis'],
                service_type=request.service_type,
                forecast_days=request.forecast_days
            )
            
        except Exception as e:
            response_time_ms = (time.time() - start_time) * 1000
            logger.error(f"Demand forecasting failed: {e}")
            
            return ForecastResponse(
                request_id=request.request_id,
                success=False,
                response_time_ms=response_time_ms,
                error_message=str(e),
                error_code="FORECASTING_FAILED",
                forecast_data=[],
                forecast_accuracy_metrics={},
                confidence_intervals=[],
                seasonal_patterns={},
                trend_analysis={},
                service_type=request.service_type,
                forecast_days=request.forecast_days
            )
    
    @service_operation("forecast_demand")
    async def forecast_demand_async(self, request: ForecastRequest) -> ForecastResponse:
        """Async demand forecasting with metrics"""
        return await self.process(request)
    
    @service_operation("analyze_trends")
    async def analyze_trends_async(self, request: TrendAnalysisRequest) -> TrendAnalysisResponse:
        """
        Analyze trends in metrics data with anomaly detection.
        
        Args:
            request: Trend analysis request
            
        Returns:
            TrendAnalysisResponse with trend analysis results
        """
        start_time = time.time()
        
        try:
            # Execute trend analysis
            loop = asyncio.get_event_loop()
            
            trend_result = await loop.run_in_executor(
                None,
                self._analyze_trends_sync,
                request.metric_name,
                request.time_period_days,
                request.granularity,
                request.detect_anomalies,
                request.include_patterns
            )
            
            response_time_ms = (time.time() - start_time) * 1000
            
            return TrendAnalysisResponse(
                request_id=request.request_id,
                success=True,
                response_time_ms=response_time_ms,
                cache_hit=trend_result.get('cache_hit', False),
                trend_direction=trend_result['trend_direction'],
                trend_strength=trend_result['trend_strength'],
                anomalies_detected=trend_result['anomalies'],
                seasonal_patterns=trend_result['seasonal_patterns'],
                statistical_summary=trend_result['statistical_summary'],
                recommendations=trend_result['recommendations'],
                metric_name=request.metric_name
            )
            
        except Exception as e:
            response_time_ms = (time.time() - start_time) * 1000
            logger.error(f"Trend analysis failed: {e}")
            
            return TrendAnalysisResponse(
                request_id=request.request_id,
                success=False,
                response_time_ms=response_time_ms,
                error_message=str(e),
                error_code="TREND_ANALYSIS_FAILED",
                trend_direction="unknown",
                trend_strength=0.0,
                anomalies_detected=[],
                seasonal_patterns=[],
                statistical_summary={},
                recommendations=[],
                metric_name=request.metric_name
            )
    
    @service_operation("calculate_kpis")
    async def calculate_kpis_async(self, request: KPICalculationRequest) -> KPICalculationResponse:
        """
        Calculate KPIs for specified metrics and time period.
        
        Args:
            request: KPI calculation request
            
        Returns:
            KPICalculationResponse with KPI values and comparisons
        """
        start_time = time.time()
        
        try:
            # Execute KPI calculation
            loop = asyncio.get_event_loop()
            
            kpi_result = await loop.run_in_executor(
                None,
                self._calculate_kpis_sync,
                request.kpi_names,
                request.calculation_period,
                request.department_ids,
                request.employee_ids,
                request.include_comparisons
            )
            
            response_time_ms = (time.time() - start_time) * 1000
            
            return KPICalculationResponse(
                request_id=request.request_id,
                success=True,
                response_time_ms=response_time_ms,
                cache_hit=kpi_result.get('cache_hit', False),
                kpi_values=kpi_result['kpi_values'],
                period_comparisons=kpi_result['period_comparisons'],
                performance_indicators=kpi_result['performance_indicators'],
                target_achievement=kpi_result['target_achievement'],
                calculation_period=request.calculation_period
            )
            
        except Exception as e:
            response_time_ms = (time.time() - start_time) * 1000
            logger.error(f"KPI calculation failed: {e}")
            
            return KPICalculationResponse(
                request_id=request.request_id,
                success=False,
                response_time_ms=response_time_ms,
                error_message=str(e),
                error_code="KPI_CALCULATION_FAILED",
                kpi_values={},
                period_comparisons={},
                performance_indicators={},
                target_achievement={},
                calculation_period=request.calculation_period
            )
    
    @service_operation("multi_service_analytics")
    async def multi_service_analytics_async(
        self, 
        request: MultiServiceAnalyticsRequest
    ) -> MultiServiceAnalyticsResponse:
        """
        Perform multi-service analytics aggregation.
        
        Args:
            request: Multi-service analytics request
            
        Returns:
            MultiServiceAnalyticsResponse with aggregated results
        """
        start_time = time.time()
        
        try:
            # Parse date range
            start_date = datetime.fromisoformat(request.date_range[0])
            end_date = datetime.fromisoformat(request.date_range[1])
            
            # Execute multi-service analytics
            loop = asyncio.get_event_loop()
            
            analytics_result = await loop.run_in_executor(
                None,
                self._multi_service_analytics_sync,
                request.service_types,
                request.analysis_types,
                (start_date, end_date),
                request.aggregation_level
            )
            
            response_time_ms = (time.time() - start_time) * 1000
            
            return MultiServiceAnalyticsResponse(
                request_id=request.request_id,
                success=True,
                response_time_ms=response_time_ms,
                cache_hit=analytics_result.get('cache_hit', False),
                aggregated_results=analytics_result['aggregated_results'],
                cross_service_insights=analytics_result['cross_service_insights'],
                performance_summary=analytics_result['performance_summary'],
                recommendations=analytics_result['recommendations'],
                services_analyzed=len(request.service_types)
            )
            
        except Exception as e:
            response_time_ms = (time.time() - start_time) * 1000
            logger.error(f"Multi-service analytics failed: {e}")
            
            return MultiServiceAnalyticsResponse(
                request_id=request.request_id,
                success=False,
                response_time_ms=response_time_ms,
                error_message=str(e),
                error_code="MULTI_SERVICE_ANALYTICS_FAILED",
                aggregated_results={},
                cross_service_insights=[],
                performance_summary={},
                recommendations=[],
                services_analyzed=0
            )
    
    def _forecast_demand_sync(
        self,
        service_type: str,
        forecast_days: int,
        historical_days: int,
        confidence_level: float,
        include_seasonality: bool,
        include_trends: bool
    ) -> Dict[str, Any]:
        """Synchronous demand forecasting using optimized algorithm"""
        
        # Use existing Redis-optimized forecaster
        result = self.demand_forecaster.forecast_demand(
            service_type=service_type,
            forecast_days=forecast_days,
            historical_days=historical_days,
            confidence_level=confidence_level
        )
        
        return {
            'forecast_data': result.forecast_values,
            'accuracy_metrics': {
                'mape': result.mape_score,
                'rmse': result.rmse_score,
                'accuracy_score': result.accuracy_score
            },
            'confidence_intervals': result.confidence_intervals,
            'seasonal_patterns': result.seasonal_patterns,
            'trend_analysis': {
                'trend_direction': result.trend_direction,
                'trend_strength': result.trend_strength
            },
            'cache_hit': result.cache_hit
        }
    
    def _analyze_trends_sync(
        self,
        metric_name: str,
        time_period_days: int,
        granularity: str,
        detect_anomalies: bool,
        include_patterns: bool
    ) -> Dict[str, Any]:
        """Synchronous trend analysis using optimized algorithm"""
        
        # Use existing Redis-optimized trend analyzer
        result = self.trend_analyzer.analyze_trends(
            metric_name=metric_name,
            time_period_days=time_period_days,
            granularity=granularity
        )
        
        return {
            'trend_direction': result.trend_direction,
            'trend_strength': result.trend_strength,
            'anomalies': result.anomalies_detected if detect_anomalies else [],
            'seasonal_patterns': result.seasonal_patterns if include_patterns else [],
            'statistical_summary': {
                'mean': result.statistical_summary.get('mean', 0.0),
                'std_dev': result.statistical_summary.get('std_dev', 0.0),
                'min_value': result.statistical_summary.get('min_value', 0.0),
                'max_value': result.statistical_summary.get('max_value', 0.0)
            },
            'recommendations': result.recommendations,
            'cache_hit': result.cache_hit
        }
    
    def _calculate_kpis_sync(
        self,
        kpi_names: List[str],
        calculation_period: str,
        department_ids: Optional[List[int]],
        employee_ids: Optional[List[int]],
        include_comparisons: bool
    ) -> Dict[str, Any]:
        """Synchronous KPI calculation using analytics service"""
        
        # Use existing analytics service
        result = self.analytics_service.calculate_kpis(
            kpi_names=kpi_names,
            period=calculation_period,
            filters={
                'department_ids': department_ids,
                'employee_ids': employee_ids
            }
        )
        
        return {
            'kpi_values': result.kpi_values,
            'period_comparisons': result.period_comparisons if include_comparisons else {},
            'performance_indicators': result.performance_trends,
            'target_achievement': result.target_achievement,
            'cache_hit': result.cache_hit
        }
    
    def _multi_service_analytics_sync(
        self,
        service_types: List[str],
        analysis_types: List[str],
        date_range: Tuple[datetime, datetime],
        aggregation_level: str
    ) -> Dict[str, Any]:
        """Synchronous multi-service analytics aggregation"""
        
        aggregated_results = {}
        cross_service_insights = []
        performance_summary = {}
        
        # Process each service type
        for service_type in service_types:
            service_results = {}
            
            # Forecasting
            if 'forecast' in analysis_types:
                forecast_result = self.demand_forecaster.forecast_demand(
                    service_type=service_type,
                    forecast_days=30
                )
                service_results['forecast'] = {
                    'forecast_values': forecast_result.forecast_values,
                    'accuracy_score': forecast_result.accuracy_score
                }
            
            # Trend analysis
            if 'trends' in analysis_types:
                trend_result = self.trend_analyzer.analyze_trends(
                    metric_name=f"{service_type}_volume",
                    time_period_days=30
                )
                service_results['trends'] = {
                    'trend_direction': trend_result.trend_direction,
                    'trend_strength': trend_result.trend_strength
                }
            
            # KPI calculation
            if 'kpis' in analysis_types:
                kpi_result = self.analytics_service.calculate_kpis(
                    kpi_names=[f"{service_type}_efficiency", f"{service_type}_satisfaction"],
                    period="last_30_days"
                )
                service_results['kpis'] = kpi_result.kpi_values
            
            aggregated_results[service_type] = service_results
        
        # Cross-service insights
        if len(service_types) > 1:
            cross_service_insights = self._generate_cross_service_insights(aggregated_results)
        
        # Performance summary
        performance_summary = self._calculate_performance_summary(aggregated_results)
        
        return {
            'aggregated_results': aggregated_results,
            'cross_service_insights': cross_service_insights,
            'performance_summary': performance_summary,
            'recommendations': self._generate_analytics_recommendations(aggregated_results),
            'cache_hit': False  # Multi-service is always computed fresh
        }
    
    def _generate_cross_service_insights(
        self, 
        aggregated_results: Dict[str, Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """Generate insights across multiple services"""
        
        insights = []
        
        service_types = list(aggregated_results.keys())
        
        # Compare trend directions
        trend_directions = {}
        for service_type in service_types:
            if 'trends' in aggregated_results[service_type]:
                trend_directions[service_type] = aggregated_results[service_type]['trends']['trend_direction']
        
        if len(trend_directions) > 1:
            if all(direction == 'increasing' for direction in trend_directions.values()):
                insights.append({
                    'type': 'cross_service_trend',
                    'insight': 'All services showing increasing demand trend',
                    'recommendation': 'Consider scaling resources across all services',
                    'confidence': 0.8
                })
        
        return insights
    
    def _calculate_performance_summary(
        self, 
        aggregated_results: Dict[str, Dict[str, Any]]
    ) -> Dict[str, float]:
        """Calculate overall performance summary"""
        
        summary = {
            'overall_efficiency': 0.0,
            'forecast_accuracy': 0.0,
            'trend_stability': 0.0
        }
        
        service_count = len(aggregated_results)
        if service_count == 0:
            return summary
        
        # Calculate averages across services
        total_accuracy = 0.0
        accuracy_count = 0
        
        for service_results in aggregated_results.values():
            if 'forecast' in service_results:
                total_accuracy += service_results['forecast']['accuracy_score']
                accuracy_count += 1
        
        if accuracy_count > 0:
            summary['forecast_accuracy'] = total_accuracy / accuracy_count
        
        return summary
    
    def _generate_analytics_recommendations(
        self, 
        aggregated_results: Dict[str, Dict[str, Any]]
    ) -> List[str]:
        """Generate recommendations based on analytics results"""
        
        recommendations = []
        
        for service_type, results in aggregated_results.items():
            # Forecast-based recommendations
            if 'forecast' in results:
                accuracy = results['forecast']['accuracy_score']
                if accuracy < 0.8:
                    recommendations.append(
                        f"Improve data quality for {service_type} forecasting (accuracy: {accuracy:.1%})"
                    )
            
            # Trend-based recommendations
            if 'trends' in results:
                trend_direction = results['trends']['trend_direction']
                if trend_direction == 'increasing':
                    recommendations.append(
                        f"Plan capacity increases for {service_type} due to growing demand"
                    )
        
        return recommendations
    
    async def _check_algorithm_health(self) -> bool:
        """Check algorithm component health"""
        try:
            # Test demand forecaster
            if not hasattr(self.demand_forecaster, 'forecast_demand'):
                return False
            
            # Test trend analyzer
            if not hasattr(self.trend_analyzer, 'analyze_trends'):
                return False
            
            # Test analytics service
            if not hasattr(self.analytics_service, 'calculate_kpis'):
                return False
            
            return True
        except Exception as e:
            logger.warning(f"Analytics algorithm health check failed: {e}")
            return False


if __name__ == "__main__":
    # Demo usage
    async def main():
        service = AnalyticsService(
            database_url="postgresql://postgres:postgres@localhost:5432/wfm_enterprise",
            redis_url="redis://localhost:6379/0"
        )
        
        print("Analytics Service Demo")
        print("=" * 50)
        
        # Test demand forecasting
        forecast_request = ForecastRequest(
            service_type="call_center",
            forecast_days=30,
            historical_days=90,
            confidence_level=0.95
        )
        
        forecast_response = await service.forecast_demand_async(forecast_request)
        
        print(f"Demand Forecasting Results:")
        print(f"  Success: {forecast_response.success}")
        print(f"  Response Time: {forecast_response.response_time_ms:.1f}ms")
        print(f"  Forecast Points: {len(forecast_response.forecast_data)}")
        print(f"  Accuracy Score: {forecast_response.forecast_accuracy_metrics.get('accuracy_score', 0):.1%}")
        print(f"  Cache Hit: {forecast_response.cache_hit}")
        
        # Test trend analysis
        trend_request = TrendAnalysisRequest(
            metric_name="call_volume",
            time_period_days=30,
            granularity="daily",
            detect_anomalies=True
        )
        
        trend_response = await service.analyze_trends_async(trend_request)
        
        print(f"\nTrend Analysis Results:")
        print(f"  Success: {trend_response.success}")
        print(f"  Response Time: {trend_response.response_time_ms:.1f}ms")
        print(f"  Trend Direction: {trend_response.trend_direction}")
        print(f"  Trend Strength: {trend_response.trend_strength:.2f}")
        print(f"  Anomalies Detected: {len(trend_response.anomalies_detected)}")
        
        # Test KPI calculation
        kpi_request = KPICalculationRequest(
            kpi_names=["service_level", "response_time", "customer_satisfaction"],
            calculation_period="last_30_days",
            include_comparisons=True
        )
        
        kpi_response = await service.calculate_kpis_async(kpi_request)
        
        print(f"\nKPI Calculation Results:")
        print(f"  Success: {kpi_response.success}")
        print(f"  Response Time: {kpi_response.response_time_ms:.1f}ms")
        print(f"  KPIs Calculated: {len(kpi_response.kpi_values)}")
        print(f"  Target Achievement: {len(kpi_response.target_achievement)} metrics")
        
        # Health check
        health = await service.health_check()
        print(f"\nService Health:")
        print(f"  Status: {health.status.value}")
        print(f"  Response Time: {health.response_time_ms:.1f}ms")
        print(f"  Algorithm Ready: {health.checks.get('algorithm_ready', False)}")
        
        await service.shutdown()
    
    # Run demo
    asyncio.run(main())