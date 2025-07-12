// BDD: Vacancy Planning Settings Configuration (Feature 27 - @vacancy_planning @configuration)
import React, { useState } from 'react';
import { Save, AlertCircle, Info } from 'lucide-react';
import type { VacancyPlanningSettings as Settings, WorkRuleParameter } from '../types/vacancy';

interface Props {
  settings: Settings;
  onSave: (settings: Settings) => void;
}

export const VacancyPlanningSettings: React.FC<Props> = ({ settings, onSave }) => {
  const [formData, setFormData] = useState(settings);
  const [workRules, setWorkRules] = useState<WorkRuleParameter>({
    shiftFlexibility: 'Flexible',
    overtimeAllowance: 10,
    crossTrainingUtilization: 80,
    scheduleRotationFrequency: 'Weekly'
  });
  const [errors, setErrors] = useState<Record<string, string>>({});

  // BDD: Validate business logic compliance
  const validateSettings = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (formData.minimumVacancyEfficiency < 1 || formData.minimumVacancyEfficiency > 100) {
      newErrors.minimumVacancyEfficiency = 'Эффективность должна быть от 1 до 100%';
    }

    if (formData.analysisPeriod < 1 || formData.analysisPeriod > 365) {
      newErrors.analysisPeriod = 'Период анализа должен быть от 1 до 365 дней';
    }

    if (formData.forecastConfidence < 50 || formData.forecastConfidence > 99) {
      newErrors.forecastConfidence = 'Доверительный уровень должен быть от 50 до 99%';
    }

    if (workRules.overtimeAllowance < 0 || workRules.overtimeAllowance > 20) {
      newErrors.overtimeAllowance = 'Сверхурочные должны быть от 0 до 20 часов в неделю';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSave = () => {
    if (validateSettings()) {
      onSave(formData);
      // BDD: Log configuration changes
      console.log('[AUDIT] Vacancy planning settings updated:', formData);
    }
  };

  return (
    <div className="bg-white rounded-lg shadow">
      <div className="p-6 border-b">
        <h2 className="text-lg font-semibold">Настройки планирования вакансий</h2>
        <p className="text-sm text-gray-600 mt-1">
          Настройте параметры для анализа кадровых потребностей
        </p>
      </div>

      <div className="p-6 space-y-6">
        {/* BDD: Essential planning parameters */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Минимальная эффективность вакансии
              <Info className="inline-block h-4 w-4 ml-1 text-gray-400" />
            </label>
            <div className="mt-1 relative">
              <input
                type="number"
                min="1"
                max="100"
                value={formData.minimumVacancyEfficiency}
                onChange={(e) => setFormData({ ...formData, minimumVacancyEfficiency: Number(e.target.value) })}
                className={`block w-full rounded-md shadow-sm ${
                  errors.minimumVacancyEfficiency ? 'border-red-300' : 'border-gray-300'
                }`}
              />
              <span className="absolute right-3 top-2 text-gray-500">%</span>
            </div>
            {errors.minimumVacancyEfficiency && (
              <p className="mt-1 text-sm text-red-600">{errors.minimumVacancyEfficiency}</p>
            )}
            <p className="mt-1 text-xs text-gray-500">
              Минимальная требуемая эффективность для новых позиций
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">
              Период анализа
            </label>
            <div className="mt-1 relative">
              <input
                type="number"
                min="1"
                max="365"
                value={formData.analysisPeriod}
                onChange={(e) => setFormData({ ...formData, analysisPeriod: Number(e.target.value) })}
                className={`block w-full rounded-md shadow-sm ${
                  errors.analysisPeriod ? 'border-red-300' : 'border-gray-300'
                }`}
              />
              <span className="absolute right-3 top-2 text-gray-500">дней</span>
            </div>
            {errors.analysisPeriod && (
              <p className="mt-1 text-sm text-red-600">{errors.analysisPeriod}</p>
            )}
            <p className="mt-1 text-xs text-gray-500">
              Период прогнозирования для анализа дефицита
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">
              Доверительный уровень прогноза
            </label>
            <div className="mt-1 relative">
              <input
                type="number"
                min="50"
                max="99"
                value={formData.forecastConfidence}
                onChange={(e) => setFormData({ ...formData, forecastConfidence: Number(e.target.value) })}
                className={`block w-full rounded-md shadow-sm ${
                  errors.forecastConfidence ? 'border-red-300' : 'border-gray-300'
                }`}
              />
              <span className="absolute right-3 top-2 text-gray-500">%</span>
            </div>
            {errors.forecastConfidence && (
              <p className="mt-1 text-sm text-red-600">{errors.forecastConfidence}</p>
            )}
            <p className="mt-1 text-xs text-gray-500">
              Статистический уровень достоверности прогнозов
            </p>
          </div>
        </div>

        {/* BDD: Boolean settings */}
        <div className="space-y-4">
          <label className="flex items-center">
            <input
              type="checkbox"
              checked={formData.workRuleOptimization}
              onChange={(e) => setFormData({ ...formData, workRuleOptimization: e.target.checked })}
              className="rounded border-gray-300 text-blue-600"
            />
            <span className="ml-2 text-sm text-gray-700">
              Включить оптимизацию рабочих правил для устранения дефицита
            </span>
          </label>

          <label className="flex items-center">
            <input
              type="checkbox"
              checked={formData.integrationWithExchange}
              onChange={(e) => setFormData({ ...formData, integrationWithExchange: e.target.checked })}
              className="rounded border-gray-300 text-blue-600"
            />
            <span className="ml-2 text-sm text-gray-700">
              Передавать результаты в систему обмена сменами
            </span>
          </label>
        </div>

        {/* BDD: Work rule configuration for optimization */}
        {formData.workRuleOptimization && (
          <div className="border-t pt-6">
            <h3 className="text-md font-medium mb-4">Параметры оптимизации рабочих правил</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Гибкость смен
                </label>
                <select
                  value={workRules.shiftFlexibility}
                  onChange={(e) => setWorkRules({ ...workRules, shiftFlexibility: e.target.value as any })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
                >
                  <option value="Fixed">Фиксированные</option>
                  <option value="Flexible">Гибкие</option>
                  <option value="Hybrid">Гибридные</option>
                </select>
                <p className="mt-1 text-xs text-gray-500">
                  Влияет на возможности замещения позиций
                </p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Допустимые сверхурочные
                </label>
                <div className="mt-1 relative">
                  <input
                    type="number"
                    min="0"
                    max="20"
                    value={workRules.overtimeAllowance}
                    onChange={(e) => setWorkRules({ ...workRules, overtimeAllowance: Number(e.target.value) })}
                    className={`block w-full rounded-md shadow-sm ${
                      errors.overtimeAllowance ? 'border-red-300' : 'border-gray-300'
                    }`}
                  />
                  <span className="absolute right-3 top-2 text-gray-500">ч/нед</span>
                </div>
                {errors.overtimeAllowance && (
                  <p className="mt-1 text-sm text-red-600">{errors.overtimeAllowance}</p>
                )}
                <p className="mt-1 text-xs text-gray-500">
                  Снижает расчетные потребности в персонале
                </p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Использование кросс-обучения
                </label>
                <div className="mt-1 relative">
                  <input
                    type="number"
                    min="0"
                    max="100"
                    value={workRules.crossTrainingUtilization}
                    onChange={(e) => setWorkRules({ ...workRules, crossTrainingUtilization: Number(e.target.value) })}
                    className="block w-full rounded-md border-gray-300 shadow-sm"
                  />
                  <span className="absolute right-3 top-2 text-gray-500">%</span>
                </div>
                <p className="mt-1 text-xs text-gray-500">
                  Позволяет анализировать мультинавыковое покрытие
                </p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Частота ротации графиков
                </label>
                <select
                  value={workRules.scheduleRotationFrequency}
                  onChange={(e) => setWorkRules({ ...workRules, scheduleRotationFrequency: e.target.value as any })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
                >
                  <option value="Daily">Ежедневно</option>
                  <option value="Weekly">Еженедельно</option>
                  <option value="Monthly">Ежемесячно</option>
                </select>
                <p className="mt-1 text-xs text-gray-500">
                  Влияет на точность долгосрочного планирования
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Save button */}
        <div className="flex justify-end pt-6 border-t">
          <button
            onClick={handleSave}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
          >
            <Save className="h-4 w-4" />
            Сохранить настройки
          </button>
        </div>
      </div>
    </div>
  );
};