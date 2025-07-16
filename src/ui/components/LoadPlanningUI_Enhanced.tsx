import React, { useState, useEffect } from 'react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Upload, Download, TrendingUp, BarChart3, Calendar, Users } from 'lucide-react';
import OptimizationPanel from './optimization/OptimizationPanel';

interface ForecastData {
  period: string;
  service_name: string;
  forecast_values: Record<string, number>;
  accuracy_metrics?: {
    mape: number;
    wape: number;
    mfa: number;
    wfa: number;
  };
}

interface ScheduleBlock {
  employee_id: string;
  start_time: string;
  end_time: string;
  skill_level: string;
  days_per_week: number;
}

export const LoadPlanningUIEnhanced: React.FC = () => {
  const [selectedService, setSelectedService] = useState('Technical Support');
  const [selectedPeriod, setPeriod] = useState('2024-07-01_2024-07-31');
  const [forecastData, setForecastData] = useState<ForecastData | null>(null);
  const [currentSchedule, setCurrentSchedule] = useState<ScheduleBlock[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [accuracyMetrics, setAccuracyMetrics] = useState(null);

  // Load initial forecast data
  useEffect(() => {
    loadForecastData();
    loadCurrentSchedule();
  }, [selectedService, selectedPeriod]);

  const loadForecastData = async () => {
    setIsLoading(true);
    try {
      const response = await fetch(
        `/api/v1/forecasting/forecasts?period=${selectedPeriod}&service_name=${encodeURIComponent(selectedService)}`
      );
      
      if (response.ok) {
        const data = await response.json();
        
        // Convert forecast data to hourly format for optimization
        const hourlyForecast: Record<string, number> = {};
        if (data.forecasts && data.forecasts.length > 0) {
          // Use first forecast's intervals
          const forecast = data.forecasts[0];
          forecast.intervals?.forEach((interval: any, index: number) => {
            const hour = 8 + index; // Start from 8 AM
            if (hour < 18) { // Business hours only
              hourlyForecast[`${hour.toString().padStart(2, '0')}:00`] = interval.agents_required || 2;
            }
          });
        } else {
          // Default forecast data for demo
          for (let hour = 8; hour < 18; hour++) {
            hourlyForecast[`${hour.toString().padStart(2, '0')}:00`] = 2 + Math.floor(Math.random() * 3);
          }
        }

        setForecastData({
          period: selectedPeriod,
          service_name: selectedService,
          forecast_values: hourlyForecast,
          accuracy_metrics: data.accuracy_metrics
        });
      }
    } catch (error) {
      console.error('Failed to load forecast data:', error);
      
      // Fallback demo data
      const demoForecast: Record<string, number> = {};
      for (let hour = 8; hour < 18; hour++) {
        demoForecast[`${hour.toString().padStart(2, '0')}:00`] = 2 + Math.floor(Math.random() * 3);
      }
      
      setForecastData({
        period: selectedPeriod,
        service_name: selectedService,
        forecast_values: demoForecast
      });
    } finally {
      setIsLoading(false);
    }
  };

  const loadCurrentSchedule = async () => {
    try {
      // In a real implementation, this would load from personnel API
      // For demo, we'll create sample schedule data
      const sampleSchedule: ScheduleBlock[] = [
        {
          employee_id: 'EMP_001',
          start_time: '08:00',
          end_time: '16:00',
          skill_level: 'intermediate',
          days_per_week: 5
        },
        {
          employee_id: 'EMP_002',
          start_time: '09:00',
          end_time: '17:00',
          skill_level: 'expert',
          days_per_week: 5
        },
        {
          employee_id: 'EMP_003',
          start_time: '10:00',
          end_time: '18:00',
          skill_level: 'basic',
          days_per_week: 4
        }
      ];
      
      setCurrentSchedule(sampleSchedule);
    } catch (error) {
      console.error('Failed to load current schedule:', error);
    }
  };

  const loadAccuracyMetrics = async () => {
    try {
      const response = await fetch(
        `/api/v1/forecasting/accuracy?service_name=${encodeURIComponent(selectedService)}`
      );
      
      if (response.ok) {
        const data = await response.json();
        setAccuracyMetrics(data);
      }
    } catch (error) {
      console.error('Failed to load accuracy metrics:', error);
    }
  };

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    const formData = new FormData();
    formData.append('file', file);
    formData.append('service_name', selectedService);
    formData.append('period_start', selectedPeriod.split('_')[0]);
    formData.append('period_end', selectedPeriod.split('_')[1]);

    setIsLoading(true);
    try {
      const response = await fetch('/api/v1/forecasting/import', {
        method: 'POST',
        body: formData
      });

      if (response.ok) {
        await loadForecastData(); // Reload data after import
        alert('File uploaded successfully!');
      } else {
        alert('Upload failed. Please check file format.');
      }
    } catch (error) {
      alert('Upload error. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleOptimizationApply = (optimization: any) => {
    // Handle applying optimization suggestions to the schedule
    console.log('Applying optimization:', optimization);
    // In real implementation, this would update the schedule via API
  };

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Load Planning & Optimization</h1>
          <p className="text-gray-600">Demand forecasting with real-time optimization analysis</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={loadAccuracyMetrics}>
            <BarChart3 className="w-4 h-4 mr-2" />
            Accuracy Metrics
          </Button>
          <Button onClick={loadForecastData} disabled={isLoading}>
            <TrendingUp className="w-4 h-4 mr-2" />
            Refresh Data
          </Button>
        </div>
      </div>

      {/* Service and Period Selection */}
      <Card>
        <CardHeader>
          <CardTitle>Configuration</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Service Group</label>
              <Select value={selectedService} onValueChange={setSelectedService}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Technical Support">Technical Support</SelectItem>
                  <SelectItem value="Customer Care">Customer Care</SelectItem>
                  <SelectItem value="Sales">Sales</SelectItem>
                  <SelectItem value="Billing">Billing</SelectItem>
                </SelectContent>
              </Select>
            </div>
            
            <div>
              <label className="block text-sm font-medium mb-2">Period</label>
              <Select value={selectedPeriod} onValueChange={setPeriod}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="2024-07-01_2024-07-31">July 2024</SelectItem>
                  <SelectItem value="2024-08-01_2024-08-31">August 2024</SelectItem>
                  <SelectItem value="2024-09-01_2024-09-30">September 2024</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div>
              <label className="block text-sm font-medium mb-2">Upload Data</label>
              <div className="flex gap-2">
                <Input
                  type="file"
                  accept=".xlsx,.xls,.csv"
                  onChange={handleFileUpload}
                  className="hidden"
                  id="file-upload"
                />
                <Button 
                  variant="outline" 
                  onClick={() => document.getElementById('file-upload')?.click()}
                  disabled={isLoading}
                  className="w-full"
                >
                  <Upload className="w-4 h-4 mr-2" />
                  Import Excel/CSV
                </Button>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Main Content - Tabs */}
      <Tabs defaultValue="forecasting" className="space-y-4">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="forecasting" className="flex items-center gap-2">
            <BarChart3 className="w-4 h-4" />
            Forecasting
          </TabsTrigger>
          <TabsTrigger value="optimization" className="flex items-center gap-2">
            <TrendingUp className="w-4 h-4" />
            Optimization
          </TabsTrigger>
          <TabsTrigger value="schedule" className="flex items-center gap-2">
            <Calendar className="w-4 h-4" />
            Current Schedule
          </TabsTrigger>
        </TabsList>

        {/* Forecasting Tab */}
        <TabsContent value="forecasting">
          <Card>
            <CardHeader>
              <CardTitle>Demand Forecast - {selectedService}</CardTitle>
            </CardHeader>
            <CardContent>
              {forecastData ? (
                <div className="space-y-4">
                  {/* Forecast Chart Placeholder */}
                  <div className="h-64 bg-gray-100 rounded-lg flex items-center justify-center">
                    <div className="text-center">
                      <BarChart3 className="w-12 h-12 mx-auto mb-4 text-gray-400" />
                      <div className="font-medium">Hourly Demand Forecast</div>
                      <div className="text-sm text-gray-500">
                        {Object.keys(forecastData.forecast_values).length} hourly intervals loaded
                      </div>
                    </div>
                  </div>

                  {/* Forecast Summary */}
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div className="text-center p-3 bg-blue-50 rounded-lg">
                      <div className="text-2xl font-bold text-blue-600">
                        {Math.max(...Object.values(forecastData.forecast_values))}
                      </div>
                      <div className="text-sm font-medium">Peak Demand</div>
                    </div>
                    <div className="text-center p-3 bg-green-50 rounded-lg">
                      <div className="text-2xl font-bold text-green-600">
                        {Math.round(Object.values(forecastData.forecast_values).reduce((a, b) => a + b, 0) / Object.values(forecastData.forecast_values).length)}
                      </div>
                      <div className="text-sm font-medium">Avg Demand</div>
                    </div>
                    <div className="text-center p-3 bg-purple-50 rounded-lg">
                      <div className="text-2xl font-bold text-purple-600">
                        {Object.values(forecastData.forecast_values).reduce((a, b) => a + b, 0)}
                      </div>
                      <div className="text-sm font-medium">Total Hours</div>
                    </div>
                    <div className="text-center p-3 bg-orange-50 rounded-lg">
                      <div className="text-2xl font-bold text-orange-600">
                        {forecastData.accuracy_metrics?.mape?.toFixed(1) || 'N/A'}%
                      </div>
                      <div className="text-sm font-medium">MAPE</div>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="text-center py-8 text-gray-500">
                  {isLoading ? 'Loading forecast data...' : 'No forecast data available'}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* Optimization Tab - THE MAIN INTEGRATION! */}
        <TabsContent value="optimization">
          <OptimizationPanel
            currentSchedule={currentSchedule}
            forecastData={forecastData?.forecast_values || {}}
            onOptimizationApply={handleOptimizationApply}
          />
        </TabsContent>

        {/* Current Schedule Tab */}
        <TabsContent value="schedule">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Users className="w-5 h-5" />
                Current Schedule Configuration
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {currentSchedule.map((block, index) => (
                  <div key={index} className="flex items-center justify-between p-3 border rounded-lg">
                    <div className="flex items-center gap-4">
                      <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
                        <Users className="w-6 h-6 text-blue-600" />
                      </div>
                      <div>
                        <div className="font-medium">{block.employee_id}</div>
                        <div className="text-sm text-gray-500">
                          {block.start_time} - {block.end_time} • {block.days_per_week} days/week
                        </div>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className={`inline-block px-2 py-1 rounded text-xs font-medium ${
                        block.skill_level === 'expert' ? 'bg-green-100 text-green-700' :
                        block.skill_level === 'intermediate' ? 'bg-yellow-100 text-yellow-700' :
                        'bg-gray-100 text-gray-700'
                      }`}>
                        {block.skill_level}
                      </div>
                    </div>
                  </div>
                ))}
                
                {currentSchedule.length === 0 && (
                  <div className="text-center py-8 text-gray-500">
                    No schedule data available
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
};

export default LoadPlanningUIEnhanced;