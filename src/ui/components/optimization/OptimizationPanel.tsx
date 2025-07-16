import React, { useState, useEffect } from 'react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { AlertTriangle, TrendingUp, DollarSign, Clock, Zap } from 'lucide-react';

interface OptimizationResult {
  total_gaps: number;
  coverage_score: number;
  average_gap_percentage: number;
  critical_intervals: string[];
  recommendations: string[];
}

interface OptimizationPanelProps {
  currentSchedule: any[];
  forecastData: Record<string, number>;
  onOptimizationApply?: (optimization: any) => void;
}

export const OptimizationPanel: React.FC<OptimizationPanelProps> = ({
  currentSchedule,
  forecastData,
  onOptimizationApply
}) => {
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [optimizationResult, setOptimizationResult] = useState<OptimizationResult | null>(null);
  const [processingTime, setProcessingTime] = useState<number>(0);
  const [fullOptimizationJob, setFullOptimizationJob] = useState<any>(null);
  const [optimizationProgress, setOptimizationProgress] = useState(0);

  // Real-time quick analysis
  const runQuickAnalysis = async () => {
    if (!currentSchedule.length || !Object.keys(forecastData).length) return;

    setIsAnalyzing(true);
    const startTime = Date.now();

    try {
      const response = await fetch('/api/v1/algorithm/analyze/quick', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          algorithm_type: 'gap_analysis',
          current_schedule: currentSchedule,
          forecast_data: forecastData
        })
      });

      const data = await response.json();
      setOptimizationResult(data.result);
      setProcessingTime(Date.now() - startTime);
    } catch (error) {
      console.error('Quick analysis failed:', error);
    } finally {
      setIsAnalyzing(false);
    }
  };

  // Full optimization workflow
  const startFullOptimization = async () => {
    try {
      const response = await fetch('/api/v1/algorithm/optimize', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          service_id: 'load_planning',
          period_start: '2024-07-01',
          period_end: '2024-07-31',
          optimization_goals: ['coverage', 'cost'],
          mode: 'phased',
          constraints: {
            labor_laws: { max_hours_week: 40 },
            staffing_costs: { base_hourly: 25.0 }
          }
        })
      });

      const jobData = await response.json();
      setFullOptimizationJob(jobData);
      
      // Start polling for progress
      pollOptimizationProgress(jobData.job_id);
    } catch (error) {
      console.error('Full optimization failed:', error);
    }
  };

  // Poll optimization progress
  const pollOptimizationProgress = async (jobId: string) => {
    const poll = async () => {
      try {
        const response = await fetch(`/api/v1/algorithm/optimize/${jobId}/status`);
        const status = await response.json();
        
        setOptimizationProgress(status.progress || 0);
        
        if (status.status === 'completed') {
          // Get full results
          const resultResponse = await fetch(`/api/v1/algorithm/optimize/${jobId}`);
          const fullResults = await resultResponse.json();
          setFullOptimizationJob({ ...fullResults, status: 'completed' });
          return;
        } else if (status.status === 'failed') {
          setFullOptimizationJob({ ...fullOptimizationJob, status: 'failed' });
          return;
        }
        
        // Continue polling
        setTimeout(poll, 2000);
      } catch (error) {
        console.error('Polling failed:', error);
      }
    };
    
    poll();
  };

  // Auto-run quick analysis when data changes
  useEffect(() => {
    const debounceTimer = setTimeout(() => {
      runQuickAnalysis();
    }, 500);

    return () => clearTimeout(debounceTimer);
  }, [currentSchedule, forecastData]);

  const getSeverityColor = (score: number) => {
    if (score >= 85) return 'bg-green-500';
    if (score >= 70) return 'bg-yellow-500';
    return 'bg-red-500';
  };

  const getSeverityText = (score: number) => {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    return 'Needs Improvement';
  };

  return (
    <div className="space-y-4">
      {/* Quick Analysis Results */}
      <Card className="border-blue-200">
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2">
            <Zap className="w-5 h-5 text-blue-500" />
            Real-time Optimization Analysis
            {isAnalyzing && (
              <Badge variant="secondary" className="ml-auto">
                <Clock className="w-3 h-3 mr-1" />
                Analyzing...
              </Badge>
            )}
            {processingTime > 0 && (
              <Badge variant="outline" className="ml-auto">
                {processingTime}ms
              </Badge>
            )}
          </CardTitle>
        </CardHeader>
        <CardContent>
          {optimizationResult ? (
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {/* Coverage Score */}
              <div className="text-center p-3 bg-gray-50 rounded-lg">
                <div className={`w-12 h-12 rounded-full ${getSeverityColor(optimizationResult.coverage_score)} mx-auto mb-2 flex items-center justify-center text-white font-bold`}>
                  {Math.round(optimizationResult.coverage_score)}
                </div>
                <div className="text-sm font-medium">Coverage Score</div>
                <div className="text-xs text-gray-500">{getSeverityText(optimizationResult.coverage_score)}</div>
              </div>

              {/* Total Gaps */}
              <div className="text-center p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center justify-center mb-2">
                  <AlertTriangle className={`w-8 h-8 ${optimizationResult.total_gaps > 5 ? 'text-red-500' : 'text-green-500'}`} />
                </div>
                <div className="text-2xl font-bold">{optimizationResult.total_gaps}</div>
                <div className="text-sm font-medium">Coverage Gaps</div>
                <div className="text-xs text-gray-500">
                  {optimizationResult.average_gap_percentage > 0 ? 
                    `${(optimizationResult.average_gap_percentage * 100).toFixed(1)}% avg gap` : 
                    'Fully covered'
                  }
                </div>
              </div>

              {/* Critical Intervals */}
              <div className="text-center p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center justify-center mb-2">
                  <Clock className={`w-8 h-8 ${optimizationResult.critical_intervals.length > 0 ? 'text-red-500' : 'text-green-500'}`} />
                </div>
                <div className="text-2xl font-bold">{optimizationResult.critical_intervals.length}</div>
                <div className="text-sm font-medium">Critical Periods</div>
                <div className="text-xs text-gray-500">
                  {optimizationResult.critical_intervals.length > 0 ? 
                    optimizationResult.critical_intervals.slice(0, 2).join(', ') : 
                    'All periods covered'
                  }
                </div>
              </div>
            </div>
          ) : (
            <div className="text-center py-8 text-gray-500">
              <Zap className="w-12 h-12 mx-auto mb-4 opacity-50" />
              <div>Load forecast data to see real-time optimization analysis</div>
            </div>
          )}

          {/* Recommendations */}
          {optimizationResult?.recommendations && optimizationResult.recommendations.length > 0 && (
            <div className="mt-4 p-3 bg-blue-50 rounded-lg">
              <div className="font-medium text-blue-900 mb-2">💡 Quick Recommendations:</div>
              <ul className="space-y-1">
                {optimizationResult.recommendations.slice(0, 3).map((rec, index) => (
                  <li key={index} className="text-sm text-blue-800 flex items-start gap-2">
                    <TrendingUp className="w-4 h-4 mt-0.5 flex-shrink-0" />
                    {rec}
                  </li>
                ))}
              </ul>
            </div>
          )}

          {/* Action Buttons */}
          <div className="flex gap-2 mt-4">
            <Button 
              onClick={runQuickAnalysis} 
              disabled={isAnalyzing}
              variant="outline"
              size="sm"
            >
              <Zap className="w-4 h-4 mr-2" />
              Refresh Analysis
            </Button>
            
            <Button 
              onClick={startFullOptimization}
              disabled={!optimizationResult || fullOptimizationJob?.status === 'processing'}
              className="bg-blue-600 hover:bg-blue-700"
              size="sm"
            >
              <TrendingUp className="w-4 h-4 mr-2" />
              Full Optimization
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Full Optimization Progress */}
      {fullOptimizationJob && (
        <Card className="border-green-200">
          <CardHeader className="pb-3">
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="w-5 h-5 text-green-500" />
              Complete Schedule Optimization
              <Badge 
                variant={fullOptimizationJob.status === 'completed' ? 'default' : 'secondary'}
                className="ml-auto"
              >
                {fullOptimizationJob.status}
              </Badge>
            </CardTitle>
          </CardHeader>
          <CardContent>
            {fullOptimizationJob.status === 'processing' && (
              <div className="space-y-3">
                <div className="flex justify-between text-sm">
                  <span>Running optimization algorithms...</span>
                  <span>{optimizationProgress}%</span>
                </div>
                <Progress value={optimizationProgress} className="w-full" />
              </div>
            )}

            {fullOptimizationJob.status === 'completed' && fullOptimizationJob.ui_integration && (
              <div className="space-y-4">
                {/* Dashboard Widgets */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  {fullOptimizationJob.ui_integration.dashboard_widgets?.map((widget: any, index: number) => (
                    <div key={index} className="text-center p-3 bg-gray-50 rounded-lg">
                      <div className={`text-2xl font-bold text-${widget.color}-600`}>
                        {widget.format === 'percentage' ? `${widget.value}%` : 
                         widget.format === 'currency' ? `$${widget.value}` : widget.value}
                      </div>
                      <div className="text-sm font-medium capitalize">
                        {widget.type.replace('_', ' ')}
                      </div>
                    </div>
                  ))}
                </div>

                {/* Suggestion Cards */}
                {fullOptimizationJob.ui_integration.suggestion_cards?.map((card: any, index: number) => (
                  <div key={index} className={`p-4 border-l-4 border-${card.color}-500 bg-${card.color}-50`}>
                    <div className="flex justify-between items-start">
                      <div>
                        <div className="font-medium">{card.title}</div>
                        <div className="text-sm text-gray-600 mt-1">
                          Coverage: {card.coverage_improvement} | Cost: {card.cost_impact} | Risk: {card.risk_level}
                        </div>
                      </div>
                      <div className="flex gap-2">
                        {card.action_buttons?.map((action: string) => (
                          <Button key={action} variant="outline" size="sm">
                            {action}
                          </Button>
                        ))}
                      </div>
                    </div>
                  </div>
                ))}

                {/* Implementation Timeline */}
                {fullOptimizationJob.ui_integration.implementation_timeline && (
                  <div className="p-3 bg-blue-50 rounded-lg">
                    <div className="font-medium text-blue-900 mb-2">📅 Implementation Plan:</div>
                    <ul className="space-y-1">
                      {fullOptimizationJob.ui_integration.implementation_timeline.map((phase: string, index: number) => (
                        <li key={index} className="text-sm text-blue-800">• {phase}</li>
                      ))}
                    </ul>
                  </div>
                )}
              </div>
            )}

            {fullOptimizationJob.status === 'failed' && (
              <div className="text-center py-4 text-red-600">
                <AlertTriangle className="w-8 h-8 mx-auto mb-2" />
                Optimization failed. Please try again.
              </div>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  );
};

export default OptimizationPanel;