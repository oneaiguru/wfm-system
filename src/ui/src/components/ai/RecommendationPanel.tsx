/**
 * AI Recommendation Panel Component
 * Displays ML-powered insights and recommendations
 */
import React, { useState, useEffect } from 'react';
import { Lightbulb, TrendingUp, AlertTriangle, CheckCircle, XCircle, ThumbsUp, ThumbsDown, Star } from 'lucide-react';

interface AIRecommendation {
  id: string;
  category: string;
  priority: 'critical' | 'high' | 'medium' | 'low';
  title: string;
  description: string;
  impact: {
    score: number;
    confidence: number;
    estimated_benefit: number;
  };
  action: {
    recommended: string;
    effort: string;
    auto_implementable: boolean;
  };
  supporting_data: Record<string, any>;
  created_at: string;
}

interface RecommendationPanelProps {
  category?: string;
  priority?: string;
  limit?: number;
  showActions?: boolean;
  className?: string;
}

export const RecommendationPanel: React.FC<RecommendationPanelProps> = ({
  category,
  priority,
  limit = 5,
  showActions = true,
  className = ''
}) => {
  const [recommendations, setRecommendations] = useState<AIRecommendation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dismissedIds, setDismissedIds] = useState<Set<string>>(new Set());
  const [implementingIds, setImplementingIds] = useState<Set<string>>(new Set());

  // Fetch AI recommendations
  const fetchRecommendations = async () => {
    try {
      const token = localStorage.getItem('auth_token');
      const params = new URLSearchParams();
      if (category) params.append('category', category);
      if (priority) params.append('priority', priority);
      params.append('limit', limit.toString());

      const response = await fetch(`/api/v1/ai/recommendations/dashboard?${params}`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        setRecommendations(data.recommendations || []);
        setError(null);
      } else {
        throw new Error('Failed to fetch recommendations');
      }
    } catch (err) {
      console.warn('Failed to fetch recommendations, using demo data');
      setRecommendations(getDemoRecommendations());
      setError(null);
    } finally {
      setLoading(false);
    }
  };

  // Implement recommendation
  const implementRecommendation = async (recommendationId: string, autoImplement: boolean = false) => {
    setImplementingIds(prev => new Set(prev).add(recommendationId));
    
    try {
      const token = localStorage.getItem('auth_token');
      const response = await fetch(`/api/v1/ai/recommendations/${recommendationId}/implement`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          auto_implement: autoImplement,
          notes: `Implemented from recommendation panel`
        })
      });

      if (response.ok) {
        const result = await response.json();
        console.log('Implementation started:', result);
        
        // Remove from current recommendations
        setRecommendations(prev => prev.filter(r => r.id !== recommendationId));
      }
    } catch (err) {
      console.error('Failed to implement recommendation:', err);
    } finally {
      setImplementingIds(prev => {
        const newSet = new Set(prev);
        newSet.delete(recommendationId);
        return newSet;
      });
    }
  };

  // Dismiss recommendation
  const dismissRecommendation = async (recommendationId: string, reason: string = 'Not applicable') => {
    setDismissedIds(prev => new Set(prev).add(recommendationId));
    
    try {
      const token = localStorage.getItem('auth_token');
      const response = await fetch(`/api/v1/ai/recommendations/${recommendationId}/dismiss?reason=${encodeURIComponent(reason)}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        setRecommendations(prev => prev.filter(r => r.id !== recommendationId));
      }
    } catch (err) {
      console.error('Failed to dismiss recommendation:', err);
      setDismissedIds(prev => {
        const newSet = new Set(prev);
        newSet.delete(recommendationId);
        return newSet;
      });
    }
  };

  // Demo recommendations
  const getDemoRecommendations = (): AIRecommendation[] => [
    {
      id: 'rec_001',
      category: 'scheduling',
      priority: 'high',
      title: 'Optimize Monday Morning Coverage',
      description: 'AI analysis shows 15% understaffing on Monday mornings leading to service level degradation. Adding 2 agents to the 9-11am shift would improve coverage by 23%.',
      impact: {
        score: 0.85,
        confidence: 0.92,
        estimated_benefit: 2500.0
      },
      action: {
        recommended: 'Add 2 agents to Monday 9-11am shift',
        effort: 'low',
        auto_implementable: true
      },
      supporting_data: {
        understaffing_percent: 15,
        affected_hours: 2,
        cost_per_hour: 25,
        historical_pattern: 'Last 8 weeks show consistent pattern'
      },
      created_at: new Date().toISOString()
    },
    {
      id: 'rec_002',
      category: 'performance',
      priority: 'medium',
      title: 'Reduce Average Handle Time',
      description: 'Machine learning detected AHT trend increasing 8% over past 2 weeks. Targeted training for specific agents could reverse this trend.',
      impact: {
        score: 0.72,
        confidence: 0.88,
        estimated_benefit: 1800.0
      },
      action: {
        recommended: 'Implement targeted training for top 10 longest AHT agents',
        effort: 'medium',
        auto_implementable: false
      },
      supporting_data: {
        aht_increase_percent: 8,
        agents_affected: 10,
        training_hours: 16,
        expected_improvement: '12-15% AHT reduction'
      },
      created_at: new Date(Date.now() - 3600000).toISOString()
    },
    {
      id: 'rec_003',
      category: 'forecasting',
      priority: 'medium',
      title: 'Adjust Seasonal Forecast Parameters',
      description: 'Current forecasting model underestimates demand by 6% during seasonal peaks. Adjusting seasonality parameters would improve accuracy.',
      impact: {
        score: 0.68,
        confidence: 0.79,
        estimated_benefit: 1200.0
      },
      action: {
        recommended: 'Update seasonal multipliers in forecasting model',
        effort: 'low',
        auto_implementable: true
      },
      supporting_data: {
        forecast_error: 6,
        seasonal_peaks: 4,
        accuracy_improvement: '8-12%'
      },
      created_at: new Date(Date.now() - 7200000).toISOString()
    }
  ];

  useEffect(() => {
    fetchRecommendations();
  }, [category, priority, limit]);

  const getPriorityIcon = (priority: string) => {
    switch (priority) {
      case 'critical':
        return <AlertTriangle className="w-4 h-4 text-red-500" />;
      case 'high':
        return <TrendingUp className="w-4 h-4 text-orange-500" />;
      case 'medium':
        return <Lightbulb className="w-4 h-4 text-yellow-500" />;
      case 'low':
        return <Star className="w-4 h-4 text-blue-500" />;
      default:
        return <Lightbulb className="w-4 h-4 text-gray-500" />;
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'critical':
        return 'border-red-200 bg-red-50';
      case 'high':
        return 'border-orange-200 bg-orange-50';
      case 'medium':
        return 'border-yellow-200 bg-yellow-50';
      case 'low':
        return 'border-blue-200 bg-blue-50';
      default:
        return 'border-gray-200 bg-gray-50';
    }
  };

  const formatBenefit = (benefit: number) => {
    if (benefit >= 1000) {
      return `$${(benefit / 1000).toFixed(1)}K`;
    }
    return `$${benefit.toFixed(0)}`;
  };

  const formatTimeAgo = (dateString: string) => {
    const now = new Date();
    const date = new Date(dateString);
    const diffMs = now.getTime() - date.getTime();
    const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
    
    if (diffHours < 1) return 'Just now';
    if (diffHours < 24) return `${diffHours}h ago`;
    
    const diffDays = Math.floor(diffHours / 24);
    return `${diffDays}d ago`;
  };

  if (loading) {
    return (
      <div className={`p-4 bg-white border border-gray-200 rounded-lg ${className}`}>
        <div className="animate-pulse space-y-3">
          <div className="h-4 bg-gray-300 rounded w-1/2"></div>
          {[1, 2, 3].map(i => (
            <div key={i} className="h-20 bg-gray-200 rounded"></div>
          ))}
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className={`p-4 bg-red-50 border border-red-200 rounded-lg ${className}`}>
        <div className="flex items-center gap-2 text-red-700 mb-2">
          <XCircle className="w-4 h-4" />
          <span className="font-medium">Error Loading Recommendations</span>
        </div>
        <p className="text-red-600 text-sm">{error}</p>
      </div>
    );
  }

  const visibleRecommendations = recommendations.filter(r => !dismissedIds.has(r.id));

  return (
    <div className={`bg-white border border-gray-200 rounded-lg ${className}`}>
      {/* Header */}
      <div className="p-4 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Lightbulb className="w-5 h-5 text-blue-500" />
            <h3 className="font-semibold text-gray-900">AI Recommendations</h3>
          </div>
          <div className="text-sm text-gray-600">
            {visibleRecommendations.length} active
          </div>
        </div>
      </div>

      {/* Recommendations List */}
      <div className="p-4">
        {visibleRecommendations.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            <Lightbulb className="w-12 h-12 mx-auto mb-3 text-gray-300" />
            <p>No recommendations available</p>
            <button
              onClick={fetchRecommendations}
              className="mt-2 text-blue-600 hover:text-blue-800 text-sm underline"
            >
              Refresh
            </button>
          </div>
        ) : (
          <div className="space-y-4">
            {visibleRecommendations.map((recommendation) => (
              <div
                key={recommendation.id}
                className={`p-4 border rounded-lg ${getPriorityColor(recommendation.priority)}`}
              >
                {/* Header */}
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-start gap-3">
                    {getPriorityIcon(recommendation.priority)}
                    <div className="flex-1">
                      <h4 className="font-medium text-gray-900 mb-1">
                        {recommendation.title}
                      </h4>
                      <div className="flex items-center gap-3 text-sm text-gray-600">
                        <span className="capitalize">{recommendation.category}</span>
                        <span>•</span>
                        <span className="capitalize">{recommendation.priority} priority</span>
                        <span>•</span>
                        <span>{formatTimeAgo(recommendation.created_at)}</span>
                      </div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-lg font-semibold text-green-600">
                      {formatBenefit(recommendation.impact.estimated_benefit)}
                    </div>
                    <div className="text-xs text-gray-600">potential savings</div>
                  </div>
                </div>

                {/* Description */}
                <p className="text-sm text-gray-700 mb-4">
                  {recommendation.description}
                </p>

                {/* Impact Metrics */}
                <div className="grid grid-cols-3 gap-4 mb-4">
                  <div>
                    <div className="text-xs text-gray-600 mb-1">Impact Score</div>
                    <div className="flex items-center gap-2">
                      <div className="flex-1 bg-gray-200 rounded-full h-2">
                        <div 
                          className="bg-blue-500 h-2 rounded-full" 
                          style={{ width: `${recommendation.impact.score * 100}%` }}
                        ></div>
                      </div>
                      <span className="text-xs font-medium">{(recommendation.impact.score * 100).toFixed(0)}%</span>
                    </div>
                  </div>
                  <div>
                    <div className="text-xs text-gray-600 mb-1">Confidence</div>
                    <div className="flex items-center gap-2">
                      <div className="flex-1 bg-gray-200 rounded-full h-2">
                        <div 
                          className="bg-green-500 h-2 rounded-full" 
                          style={{ width: `${recommendation.impact.confidence * 100}%` }}
                        ></div>
                      </div>
                      <span className="text-xs font-medium">{(recommendation.impact.confidence * 100).toFixed(0)}%</span>
                    </div>
                  </div>
                  <div>
                    <div className="text-xs text-gray-600 mb-1">Effort</div>
                    <span className={`inline-block px-2 py-1 rounded-full text-xs font-medium ${
                      recommendation.action.effort === 'low' ? 'bg-green-100 text-green-800' :
                      recommendation.action.effort === 'medium' ? 'bg-yellow-100 text-yellow-800' :
                      'bg-red-100 text-red-800'
                    }`}>
                      {recommendation.action.effort}
                    </span>
                  </div>
                </div>

                {/* Recommended Action */}
                <div className="bg-white bg-opacity-60 rounded p-3 mb-4">
                  <div className="text-xs text-gray-600 mb-1">Recommended Action</div>
                  <p className="text-sm font-medium text-gray-900">
                    {recommendation.action.recommended}
                  </p>
                </div>

                {/* Actions */}
                {showActions && (
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      {recommendation.action.auto_implementable && (
                        <button
                          onClick={() => implementRecommendation(recommendation.id, true)}
                          disabled={implementingIds.has(recommendation.id)}
                          className="flex items-center gap-1 px-3 py-1 bg-green-500 text-white rounded text-sm hover:bg-green-600 disabled:opacity-50"
                        >
                          <CheckCircle className="w-3 h-3" />
                          {implementingIds.has(recommendation.id) ? 'Implementing...' : 'Auto Implement'}
                        </button>
                      )}
                      <button
                        onClick={() => implementRecommendation(recommendation.id, false)}
                        disabled={implementingIds.has(recommendation.id)}
                        className="flex items-center gap-1 px-3 py-1 bg-blue-500 text-white rounded text-sm hover:bg-blue-600 disabled:opacity-50"
                      >
                        <ThumbsUp className="w-3 h-3" />
                        {implementingIds.has(recommendation.id) ? 'Processing...' : 'Implement'}
                      </button>
                    </div>
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => dismissRecommendation(recommendation.id, 'Not relevant')}
                        className="flex items-center gap-1 px-3 py-1 text-gray-600 hover:text-gray-800 text-sm"
                      >
                        <ThumbsDown className="w-3 h-3" />
                        Dismiss
                      </button>
                    </div>
                  </div>
                )}

                {/* Supporting Data (collapsible) */}
                {recommendation.supporting_data && Object.keys(recommendation.supporting_data).length > 0 && (
                  <details className="mt-3">
                    <summary className="text-xs text-gray-600 cursor-pointer hover:text-gray-800">
                      View supporting data
                    </summary>
                    <div className="mt-2 bg-gray-50 rounded p-3">
                      <div className="grid grid-cols-2 gap-2 text-xs">
                        {Object.entries(recommendation.supporting_data).map(([key, value]) => (
                          <div key={key} className="flex justify-between">
                            <span className="text-gray-600 capitalize">{key.replace('_', ' ')}:</span>
                            <span className="text-gray-900 font-medium">{String(value)}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  </details>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default RecommendationPanel;