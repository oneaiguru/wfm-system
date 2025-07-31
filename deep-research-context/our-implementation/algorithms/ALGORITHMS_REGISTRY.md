# Algorithm Registry

Total algorithms: 69
Working: 13 (Updated Sprint 1)

## Production Algorithms (Real Data Integration)

### ApprovalWorkflowEngine
- Purpose: Complete approval workflow management with routing and decisions
- Path: workflows/approval_workflow_engine.py
- Usage: `from algorithms.workflows.approval_workflow_engine import ApprovalWorkflowEngine`

### ErlangCEnhanced
- Purpose: Enhanced Erlang C queueing calculations for staffing optimization
- Path: core/erlang_c_enhanced.py
- Usage: `from algorithms.core.erlang_c_enhanced import ErlangCEnhanced`

### ZUPTimeCodeGenerator
- Purpose: Generate Russian labor law compliant time codes for 1C ZUP integration
- Path: russian/zup_time_code_generator.py
- Usage: `from algorithms.russian.zup_time_code_generator import ZUPTimeCodeGenerator`

### ForecastAccuracyMetrics
- Purpose: Calculate MAPE/WAPE forecast accuracy metrics
- Path: ml/forecast_accuracy_metrics.py
- Usage: `from algorithms.ml.forecast_accuracy_metrics import ForecastAccuracyMetrics`

### AutoLearningCoefficientsReal
- Purpose: Auto-adjust forecasting coefficients based on historical performance
- Path: ml/auto_learning_coefficients_real.py
- Usage: `from algorithms.ml.auto_learning_coefficients_real import AutoLearningCoefficientsReal`

### CallVolumePredictorReal (NEW - July 18, 2025)
- Purpose: Multi-channel call volume forecasting with seasonal patterns and historical analysis
- Path: prediction/call_volume_predictor_real.py
- Usage: `from algorithms.prediction.call_volume_predictor_real import CallVolumePredictorReal`
- Database: contact_statistics, forecast_results, seasonal_patterns
- Performance: <500ms per BDD spec
- BDD: 08-load-forecasting-demand-planning.feature

### AHTTrendAnalyzerReal (NEW - July 18, 2025)
- Purpose: Average Handling Time trend analysis and prediction with volatility assessment
- Path: prediction/aht_trend_analyzer_real.py
- Usage: `from algorithms.prediction.aht_trend_analyzer_real import AHTTrendAnalyzerReal`
- Database: contact_statistics, aht_trend_results, aht_volatility_tracking
- Performance: <500ms per BDD spec
- BDD: 08-load-forecasting-demand-planning.feature

### ForecastAccuracyCalculatorReal (NEW - July 18, 2025)
- Purpose: Calculate MAPE, WAPE, MAE, RMSE with real-time degradation detection
- Path: prediction/forecast_accuracy_calculator_real.py
- Usage: `from algorithms.prediction.forecast_accuracy_calculator_real import ForecastAccuracyCalculatorReal`
- Database: forecast_results, contact_statistics, forecast_accuracy_metrics
- Performance: <300ms per BDD spec
- BDD: 08-load-forecasting-demand-planning.feature (lines 331-341)

### WhatIfScenarioEngineReal (NEW - July 18, 2025)
- Purpose: What-if scenario modeling with growth factors and impact analysis
- Path: prediction/what_if_scenario_engine_real.py
- Usage: `from algorithms.prediction.what_if_scenario_engine_real import WhatIfScenarioEngineReal`
- Database: forecast_results, scenario_definitions, scenario_results, scenario_comparisons
- Performance: <2000ms per BDD spec
- BDD: 08-load-forecasting-demand-planning.feature (lines 85-95)



## Sprint 1 Additions (July 18, 2025)

### CallVolumePredictor
- Purpose: Predicts future call volumes using time series analysis
- Path: prediction/call_volume_predictor.py
- Status: ✅ Real data from contact_statistics table
- Performance: <500ms for 30-day prediction

### AHTTrendAnalyzer  
- Purpose: Analyzes average handle time trends and patterns
- Path: analytics/aht_trend_analyzer.py
- Status: ✅ Real data integration
- Performance: <200ms analysis time

### ForecastAccuracyCalculator
- Purpose: Calculates MAPE/WAPE forecast accuracy metrics
- Path: metrics/forecast_accuracy_calculator.py
- Status: ✅ Real implementation
- Output: Accuracy percentage with confidence intervals

### WhatIfScenarioEngine
- Purpose: Simulates different staffing scenarios
- Path: simulation/what_if_scenario_engine.py
- Status: ✅ Real calculations
- Features: Multi-variable optimization
