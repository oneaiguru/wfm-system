// BDD: Vacancy Reporting (Feature 27 - @vacancy_planning @reporting @high)
import React, { useState } from 'react';
import { FileText, Download, Send, Calendar, TrendingUp, PieChart, BarChart } from 'lucide-react';
import type { VacancyReport } from '../types/vacancy';

export const VacancyReporting: React.FC = () => {
  const [selectedReportType, setSelectedReportType] = useState<VacancyReport['type']>('ExecutiveSummary');
  const [reportFormat, setReportFormat] = useState<VacancyReport['format']>('PDF');
  const [reportSections, setReportSections] = useState({
    currentState: true,
    gapAnalysis: true,
    recommendations: true,
    financialImpact: true,
    implementationTimeline: true
  });
  const [isGenerating, setIsGenerating] = useState(false);

  // BDD: Report type configurations
  const reportTypes = {
    ExecutiveSummary: {
      name: 'Краткий отчет для руководства',
      description: 'Ключевые выводы и рекомендации на 2-3 страницы',
      audience: 'Высшее руководство',
      formats: ['PDF', 'PowerPoint']
    },
    DetailedAnalysis: {
      name: 'Детальный анализ дефицита',
      description: 'Полный анализ с расчетами и обоснованиями',
      audience: 'Команда планирования',
      formats: ['Excel', 'PDF']
    },
    HiringJustification: {
      name: 'Обоснование найма',
      description: 'Бизнес-кейс для новых позиций',
      audience: 'HR и Финансы',
      formats: ['Word', 'PDF']
    },
    ImplementationPlan: {
      name: 'План реализации найма',
      description: 'Пошаговый план с графиком найма',
      audience: 'Операционная команда',
      formats: ['PDF', 'Excel']
    }
  };

  // BDD: Historical trend data for analysis
  const trendData = [
    { month: 'Январь', headcount: 820, deficit: 30, hiredSuccess: 85 },
    { month: 'Февраль', headcount: 835, deficit: 25, hiredSuccess: 88 },
    { month: 'Март', headcount: 845, deficit: 20, hiredSuccess: 90 },
    { month: 'Апрель', headcount: 850, deficit: 25, hiredSuccess: 86 },
    { month: 'Май', headcount: 855, deficit: 22, hiredSuccess: 87 },
    { month: 'Июнь', headcount: 848, deficit: 28, hiredSuccess: 84 }
  ];

  // BDD: Generate comprehensive vacancy planning reports
  const generateReport = () => {
    setIsGenerating(true);
    
    // Log report generation
    console.log('[AUDIT] Generating vacancy planning report:', {
      type: selectedReportType,
      format: reportFormat,
      sections: reportSections,
      timestamp: new Date().toISOString()
    });
    
    // Simulate report generation
    setTimeout(() => {
      setIsGenerating(false);
      
      // Simulate download
      const filename = `vacancy_report_${selectedReportType.toLowerCase()}_${new Date().toISOString().split('T')[0]}.${reportFormat.toLowerCase()}`;
      alert(`Отчет сгенерирован: ${filename}`);
      
      // In real implementation, this would trigger actual file download
      console.log('[AUDIT] Report generated successfully:', filename);
    }, 3000);
  };

  const currentReport = reportTypes[selectedReportType];

  return (
    <div className="space-y-6">
      {/* Report Type Selection */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-semibold mb-4">Выберите тип отчета</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {Object.entries(reportTypes).map(([type, config]) => (
            <label
              key={type}
              className={`relative flex cursor-pointer rounded-lg border p-4 ${
                selectedReportType === type 
                  ? 'border-blue-500 bg-blue-50' 
                  : 'border-gray-300 hover:border-gray-400'
              }`}
            >
              <input
                type="radio"
                name="reportType"
                value={type}
                checked={selectedReportType === type}
                onChange={(e) => setSelectedReportType(e.target.value as VacancyReport['type'])}
                className="sr-only"
              />
              <div className="flex-1">
                <div className="flex items-center justify-between">
                  <h4 className="font-medium">{config.name}</h4>
                  <FileText className={`h-5 w-5 ${
                    selectedReportType === type ? 'text-blue-500' : 'text-gray-400'
                  }`} />
                </div>
                <p className="text-sm text-gray-600 mt-1">{config.description}</p>
                <p className="text-xs text-gray-500 mt-2">Аудитория: {config.audience}</p>
              </div>
            </label>
          ))}
        </div>
      </div>

      {/* Report Configuration */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-semibold mb-4">Настройки отчета</h3>
        
        <div className="space-y-4">
          {/* Format Selection */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Формат отчета
            </label>
            <div className="flex gap-3">
              {currentReport.formats.map(format => (
                <label key={format} className="flex items-center">
                  <input
                    type="radio"
                    name="format"
                    value={format}
                    checked={reportFormat === format}
                    onChange={(e) => setReportFormat(e.target.value as VacancyReport['format'])}
                    className="mr-2"
                  />
                  <span className="text-sm">{format}</span>
                </label>
              ))}
            </div>
          </div>

          {/* Section Selection */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Разделы отчета
            </label>
            <div className="space-y-2">
              {Object.entries({
                currentState: 'Текущее состояние штата',
                gapAnalysis: 'Анализ кадрового дефицита',
                recommendations: 'Рекомендации по найму',
                financialImpact: 'Финансовое влияние',
                implementationTimeline: 'График реализации'
              }).map(([key, label]) => (
                <label key={key} className="flex items-center">
                  <input
                    type="checkbox"
                    checked={reportSections[key as keyof typeof reportSections]}
                    onChange={(e) => setReportSections({
                      ...reportSections,
                      [key]: e.target.checked
                    })}
                    className="mr-2"
                  />
                  <span className="text-sm">{label}</span>
                </label>
              ))}
            </div>
          </div>
        </div>

        {/* Generate Button */}
        <div className="mt-6 flex items-center gap-4">
          <button
            onClick={generateReport}
            disabled={isGenerating}
            className={`flex items-center gap-2 px-4 py-2 rounded-md ${
              isGenerating 
                ? 'bg-gray-300 text-gray-500 cursor-not-allowed' 
                : 'bg-blue-600 text-white hover:bg-blue-700'
            }`}
          >
            {isGenerating ? (
              <>
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" />
                Генерация отчета...
              </>
            ) : (
              <>
                <Download className="h-4 w-4" />
                Сгенерировать отчет
              </>
            )}
          </button>
          
          <button className="flex items-center gap-2 px-4 py-2 border rounded-md hover:bg-gray-50">
            <Send className="h-4 w-4" />
            Отправить по email
          </button>
        </div>
      </div>

      {/* BDD: Trend Analysis */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-semibold mb-4">Анализ трендов кадровых потребностей</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Staffing Levels Chart */}
          <div className="space-y-3">
            <h4 className="font-medium flex items-center gap-2">
              <TrendingUp className="h-4 w-4 text-gray-500" />
              Уровень укомплектованности
            </h4>
            <div className="space-y-2">
              {trendData.map((month, index) => (
                <div key={index} className="flex items-center justify-between text-sm">
                  <span className="text-gray-600">{month.month}</span>
                  <div className="flex items-center gap-2">
                    <div className="w-32 bg-gray-200 rounded-full h-2">
                      <div 
                        className="bg-blue-500 h-2 rounded-full"
                        style={{ width: `${(month.headcount / 900) * 100}%` }}
                      />
                    </div>
                    <span className="font-medium w-12 text-right">{month.headcount}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Gap Frequency Chart */}
          <div className="space-y-3">
            <h4 className="font-medium flex items-center gap-2">
              <BarChart className="h-4 w-4 text-gray-500" />
              Частота дефицита
            </h4>
            <div className="space-y-2">
              {trendData.map((month, index) => (
                <div key={index} className="flex items-center justify-between text-sm">
                  <span className="text-gray-600">{month.month}</span>
                  <div className="flex items-center gap-2">
                    <div className="w-32 bg-gray-200 rounded-full h-2">
                      <div 
                        className={`h-2 rounded-full ${
                          month.deficit > 25 ? 'bg-red-500' : 
                          month.deficit > 20 ? 'bg-orange-500' : 
                          'bg-green-500'
                        }`}
                        style={{ width: `${(month.deficit / 35) * 100}%` }}
                      />
                    </div>
                    <span className="font-medium w-12 text-right">{month.deficit}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Hiring Effectiveness */}
          <div className="space-y-3">
            <h4 className="font-medium flex items-center gap-2">
              <PieChart className="h-4 w-4 text-gray-500" />
              Эффективность найма
            </h4>
            <div className="space-y-2">
              {trendData.map((month, index) => (
                <div key={index} className="flex items-center justify-between text-sm">
                  <span className="text-gray-600">{month.month}</span>
                  <div className="flex items-center gap-2">
                    <div className="w-32 bg-gray-200 rounded-full h-2">
                      <div 
                        className={`h-2 rounded-full ${
                          month.hiredSuccess >= 90 ? 'bg-green-500' : 
                          month.hiredSuccess >= 85 ? 'bg-yellow-500' : 
                          'bg-red-500'
                        }`}
                        style={{ width: `${month.hiredSuccess}%` }}
                      />
                    </div>
                    <span className="font-medium w-12 text-right">{month.hiredSuccess}%</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Insights */}
        <div className="mt-6 p-4 bg-blue-50 rounded-lg">
          <h4 className="font-medium text-blue-900 mb-2">Ключевые выводы:</h4>
          <ul className="list-disc list-inside space-y-1 text-sm text-blue-800">
            <li>Сезонный рост дефицита наблюдается в апреле-июне</li>
            <li>Эффективность найма снижается при дефиците выше 25 позиций</li>
            <li>Требуется упреждающее планирование на 2-3 месяца вперед</li>
          </ul>
        </div>
      </div>

      {/* Recent Reports */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-semibold mb-4">Последние сгенерированные отчеты</h3>
        
        <div className="space-y-3">
          {[
            { 
              name: 'Краткий отчет для руководства - Июнь 2024',
              date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
              format: 'PDF',
              size: '2.4 MB'
            },
            {
              name: 'Детальный анализ дефицита - Q2 2024',
              date: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
              format: 'Excel',
              size: '5.1 MB'
            },
            {
              name: 'План реализации найма - Май 2024',
              date: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000),
              format: 'PDF',
              size: '1.8 MB'
            }
          ].map((report, index) => (
            <div key={index} className="flex items-center justify-between p-3 border rounded-lg hover:bg-gray-50">
              <div className="flex items-center gap-3">
                <FileText className="h-5 w-5 text-gray-400" />
                <div>
                  <p className="font-medium text-sm">{report.name}</p>
                  <p className="text-xs text-gray-500">
                    {report.date.toLocaleDateString('ru-RU')} • {report.format} • {report.size}
                  </p>
                </div>
              </div>
              <button className="text-blue-600 hover:text-blue-800">
                <Download className="h-4 w-4" />
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};