// BDD: Vacancy Planning Analysis Dashboard (Feature 27 - @vacancy_planning @calculation @monitoring)
import React, { useState, useEffect } from 'react';
import { Play, Pause, X, AlertCircle, CheckCircle, Clock, Users, TrendingUp } from 'lucide-react';
import type { VacancyPlanningSettings, VacancyAnalysisRequest, VacancyTask } from '../types/vacancy';

interface Props {
  settings: VacancyPlanningSettings;
}

export const VacancyAnalysisDashboard: React.FC<Props> = ({ settings }) => {
  const [analysisRequest, setAnalysisRequest] = useState<VacancyAnalysisRequest>({
    period: {
      start: new Date(),
      end: new Date(Date.now() + settings.analysisPeriod * 24 * 60 * 60 * 1000)
    },
    positions: [],
    constraints: {
      budget: undefined,
      hiringLeadTime: 30,
      minServiceLevel: 95
    }
  });

  const [activeTasks, setActiveTasks] = useState<VacancyTask[]>([]);
  const [currentStep, setCurrentStep] = useState<string>('');
  const [progress, setProgress] = useState(0);
  const [isRunning, setIsRunning] = useState(false);

  // BDD: Calculation sequence steps
  const calculationSteps = [
    { step: 1, process: 'Загрузка текущих данных о персонале', dataSource: 'Система управления персоналом', duration: 3000 },
    { step: 2, process: 'Получение прогнозов нагрузки', dataSource: 'Модуль прогнозирования нагрузки', duration: 2000 },
    { step: 3, process: 'Расчет требуемого персонала', dataSource: 'Нагрузка + Уровни обслуживания', duration: 4000 },
    { step: 4, process: 'Определение дефицита', dataSource: 'Требуемый - Текущий', duration: 2000 },
    { step: 5, process: 'Оптимизация рабочих правил', dataSource: 'Анализ гибкости графиков', duration: 3000 },
    { step: 6, process: 'Генерация рекомендаций', dataSource: 'Анализ дефицита + сроки найма', duration: 2000 }
  ];

  // BDD: Execute comprehensive vacancy planning analysis
  const startAnalysis = () => {
    setIsRunning(true);
    setProgress(0);
    
    const newTask: VacancyTask = {
      id: `task-${Date.now()}`,
      name: `Анализ вакансий ${new Date().toLocaleDateString('ru-RU')}`,
      status: 'running',
      priority: 'High',
      progress: 0,
      startTime: new Date(),
      estimatedCompletion: new Date(Date.now() + 16000) // Total duration of all steps
    };
    
    setActiveTasks([newTask, ...activeTasks]);
    
    // BDD: Execute calculation sequence with progress indicators
    let currentStepIndex = 0;
    const executeStep = () => {
      if (currentStepIndex < calculationSteps.length) {
        const step = calculationSteps[currentStepIndex];
        setCurrentStep(step.process);
        
        // Simulate processing time
        setTimeout(() => {
          currentStepIndex++;
          const newProgress = Math.round((currentStepIndex / calculationSteps.length) * 100);
          setProgress(newProgress);
          
          // Update task progress
          setActiveTasks(tasks => 
            tasks.map(t => t.id === newTask.id 
              ? { ...t, progress: newProgress } 
              : t
            )
          );
          
          if (currentStepIndex < calculationSteps.length) {
            executeStep();
          } else {
            // Analysis complete
            setIsRunning(false);
            setCurrentStep('Анализ завершен');
            setActiveTasks(tasks => 
              tasks.map(t => t.id === newTask.id 
                ? { ...t, status: 'completed' } 
                : t
              )
            );
            
            // BDD: Store calculation results
            console.log('[AUDIT] Vacancy analysis completed:', {
              taskId: newTask.id,
              settings,
              request: analysisRequest
            });
          }
        }, step.duration);
      }
    };
    
    executeStep();
  };

  // BDD: Monitor execution progress with real-time updates
  useEffect(() => {
    if (isRunning) {
      const interval = setInterval(() => {
        // Update ETA for active tasks
        setActiveTasks(tasks => 
          tasks.map(task => {
            if (task.status === 'running') {
              const elapsed = Date.now() - task.startTime.getTime();
              const totalDuration = 16000; // Total expected duration
              const remaining = Math.max(0, totalDuration - elapsed);
              return {
                ...task,
                estimatedCompletion: new Date(Date.now() + remaining)
              };
            }
            return task;
          })
        );
      }, 5000); // Update every 5 seconds as per BDD

      return () => clearInterval(interval);
    }
  }, [isRunning]);

  // BDD: Handle task cancellation
  const cancelTask = (taskId: string) => {
    setActiveTasks(tasks => 
      tasks.map(t => t.id === taskId 
        ? { ...t, status: 'failed', error: 'Отменено пользователем' } 
        : t
      )
    );
    if (isRunning) {
      setIsRunning(false);
      setCurrentStep('Анализ отменен');
    }
  };

  return (
    <div className="space-y-6">
      {/* Analysis Configuration */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-semibold mb-4">Параметры анализа</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <div>
            <label className="block text-sm font-medium text-gray-700">Начало периода</label>
            <input
              type="date"
              value={analysisRequest.period.start.toISOString().split('T')[0]}
              onChange={(e) => setAnalysisRequest({
                ...analysisRequest,
                period: { ...analysisRequest.period, start: new Date(e.target.value) }
              })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
              disabled={isRunning}
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700">Конец периода</label>
            <input
              type="date"
              value={analysisRequest.period.end.toISOString().split('T')[0]}
              onChange={(e) => setAnalysisRequest({
                ...analysisRequest,
                period: { ...analysisRequest.period, end: new Date(e.target.value) }
              })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
              disabled={isRunning}
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700">Минимальный уровень обслуживания</label>
            <div className="mt-1 relative">
              <input
                type="number"
                min="70"
                max="100"
                value={analysisRequest.constraints.minServiceLevel}
                onChange={(e) => setAnalysisRequest({
                  ...analysisRequest,
                  constraints: { ...analysisRequest.constraints, minServiceLevel: Number(e.target.value) }
                })}
                className="block w-full rounded-md border-gray-300 shadow-sm"
                disabled={isRunning}
              />
              <span className="absolute right-3 top-2 text-gray-500">%</span>
            </div>
          </div>
        </div>

        {/* BDD: Start analysis button */}
        <button
          onClick={startAnalysis}
          disabled={isRunning}
          className={`flex items-center gap-2 px-4 py-2 rounded-md ${
            isRunning 
              ? 'bg-gray-300 text-gray-500 cursor-not-allowed' 
              : 'bg-blue-600 text-white hover:bg-blue-700'
          }`}
        >
          <Play className="h-4 w-4" />
          Начать анализ
        </button>
      </div>

      {/* BDD: Real-time progress monitoring */}
      {(isRunning || currentStep) && (
        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="text-lg font-semibold mb-4">Ход выполнения анализа</h3>
          
          <div className="space-y-4">
            {/* Overall progress */}
            <div>
              <div className="flex justify-between text-sm mb-1">
                <span className="text-gray-600">Общий прогресс</span>
                <span className="font-medium">{progress}%</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div 
                  className="bg-blue-600 h-2 rounded-full transition-all duration-300"
                  style={{ width: `${progress}%` }}
                />
              </div>
            </div>

            {/* Current step */}
            <div className="flex items-center gap-3 p-3 bg-blue-50 rounded-lg">
              <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-blue-600" />
              <div>
                <p className="text-sm font-medium text-blue-900">Текущий этап</p>
                <p className="text-sm text-blue-700">{currentStep}</p>
              </div>
            </div>

            {/* Step details */}
            <div className="space-y-2">
              {calculationSteps.map((step, index) => {
                const stepProgress = (progress / 100) * calculationSteps.length;
                const isCompleted = index < stepProgress;
                const isCurrent = Math.floor(stepProgress) === index;
                
                return (
                  <div 
                    key={step.step}
                    className={`flex items-start gap-3 p-2 rounded ${
                      isCurrent ? 'bg-blue-50' : ''
                    }`}
                  >
                    {isCompleted ? (
                      <CheckCircle className="h-5 w-5 text-green-500 mt-0.5" />
                    ) : isCurrent ? (
                      <div className="h-5 w-5 rounded-full border-2 border-blue-600 border-t-transparent animate-spin mt-0.5" />
                    ) : (
                      <div className="h-5 w-5 rounded-full border-2 border-gray-300 mt-0.5" />
                    )}
                    <div className="flex-1">
                      <p className={`text-sm font-medium ${
                        isCompleted ? 'text-gray-700' : isCurrent ? 'text-blue-700' : 'text-gray-400'
                      }`}>
                        Шаг {step.step}: {step.process}
                      </p>
                      <p className="text-xs text-gray-500">Источник данных: {step.dataSource}</p>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* BDD: Task management for concurrent execution */}
      {activeTasks.length > 0 && (
        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="text-lg font-semibold mb-4">Активные задачи анализа</h3>
          
          <div className="space-y-3">
            {activeTasks.slice(0, 5).map(task => (
              <div key={task.id} className="border rounded-lg p-4">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-3">
                    <span className={`px-2 py-1 text-xs rounded-full ${
                      task.priority === 'High' ? 'bg-red-100 text-red-700' :
                      task.priority === 'Medium' ? 'bg-yellow-100 text-yellow-700' :
                      'bg-gray-100 text-gray-700'
                    }`}>
                      {task.priority === 'High' ? 'Высокий' : 
                       task.priority === 'Medium' ? 'Средний' : 'Низкий'}
                    </span>
                    <h4 className="font-medium">{task.name}</h4>
                  </div>
                  
                  <div className="flex items-center gap-2">
                    {task.status === 'running' && (
                      <Clock className="h-4 w-4 text-gray-500" />
                    )}
                    {task.status === 'completed' && (
                      <CheckCircle className="h-4 w-4 text-green-500" />
                    )}
                    {task.status === 'failed' && (
                      <AlertCircle className="h-4 w-4 text-red-500" />
                    )}
                    {task.status === 'running' && (
                      <button
                        onClick={() => cancelTask(task.id)}
                        className="text-gray-400 hover:text-red-600"
                      >
                        <X className="h-4 w-4" />
                      </button>
                    )}
                  </div>
                </div>
                
                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600">Прогресс</span>
                    <span>{task.progress}%</span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-1.5">
                    <div 
                      className={`h-1.5 rounded-full ${
                        task.status === 'completed' ? 'bg-green-500' :
                        task.status === 'failed' ? 'bg-red-500' :
                        'bg-blue-600'
                      }`}
                      style={{ width: `${task.progress}%` }}
                    />
                  </div>
                  
                  {task.status === 'running' && (
                    <p className="text-xs text-gray-500">
                      Осталось: ~{Math.ceil((task.estimatedCompletion.getTime() - Date.now()) / 60000)} мин
                    </p>
                  )}
                  
                  {task.error && (
                    <p className="text-xs text-red-600">{task.error}</p>
                  )}
                </div>
              </div>
            ))}
          </div>
          
          {activeTasks.length > 5 && (
            <p className="text-sm text-gray-500 mt-3">
              И еще {activeTasks.length - 5} задач...
            </p>
          )}
        </div>
      )}
    </div>
  );
};