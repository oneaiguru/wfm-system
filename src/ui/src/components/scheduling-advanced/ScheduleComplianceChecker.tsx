import React, { useState, useEffect } from 'react';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

const ScheduleComplianceChecker: React.FC = () => {
  const [complianceReport, setComplianceReport] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const checkCompliance = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/scheduling/compliance/check`);
        const data = await response.json();
        setComplianceReport(data);
      } catch (err) {
        console.error('Ошибка проверки соответствия');
      } finally {
        setLoading(false);
      }
    };
    checkCompliance();
  }, []);

  if (loading) return <div>Проверка соответствия расписания...</div>;

  return (
    <div className="schedule-compliance-checker">
      <h1>Контроль соответствия расписания</h1>
      
      {complianceReport && (
        <div className="compliance-report">
          <div className="compliance-score">
            <h2>Общая оценка соответствия</h2>
            <div className={`score ${complianceReport.overallScore >= 90 ? 'good' : complianceReport.overallScore >= 70 ? 'warning' : 'danger'}`}>
              {complianceReport.overallScore}%
            </div>
          </div>

          <div className="compliance-categories">
            <div className="category-card">
              <h3>Трудовое законодательство</h3>
              <div className="compliance-details">
                <div className="compliance-item">
                  <span>Максимальные часы в неделю</span>
                  <span className={complianceReport.laborLaw.maxWeeklyHours ? 'pass' : 'fail'}>
                    {complianceReport.laborLaw.maxWeeklyHours ? '✅' : '❌'}
                  </span>
                </div>
                <div className="compliance-item">
                  <span>Минимальный отдых между сменами</span>
                  <span className={complianceReport.laborLaw.minRestPeriod ? 'pass' : 'fail'}>
                    {complianceReport.laborLaw.minRestPeriod ? '✅' : '❌'}
                  </span>
                </div>
                <div className="compliance-item">
                  <span>Ограничения ночных смен</span>
                  <span className={complianceReport.laborLaw.nightShiftLimits ? 'pass' : 'fail'}>
                    {complianceReport.laborLaw.nightShiftLimits ? '✅' : '❌'}
                  </span>
                </div>
              </div>
            </div>

            <div className="category-card">
              <h3>Корпоративные политики</h3>
              <div className="compliance-details">
                <div className="compliance-item">
                  <span>Покрытие навыков</span>
                  <span className={complianceReport.policies.skillCoverage ? 'pass' : 'fail'}>
                    {complianceReport.policies.skillCoverage ? '✅' : '❌'}
                  </span>
                </div>
                <div className="compliance-item">
                  <span>Справедливое распределение</span>
                  <span className={complianceReport.policies.fairDistribution ? 'pass' : 'fail'}>
                    {complianceReport.policies.fairDistribution ? '✅' : '❌'}
                  </span>
                </div>
              </div>
            </div>

            <div className="category-card">
              <h3>Требования к покрытию</h3>
              <div className="compliance-details">
                <div className="compliance-item">
                  <span>Минимальное покрытие</span>
                  <span className={complianceReport.coverage.minimum ? 'pass' : 'fail'}>
                    {complianceReport.coverage.minimum ? '✅' : '❌'}
                  </span>
                </div>
                <div className="compliance-item">
                  <span>Пиковое покрытие</span>
                  <span className={complianceReport.coverage.peak ? 'pass' : 'fail'}>
                    {complianceReport.coverage.peak ? '✅' : '❌'}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <div className="violations-section">
            <h3>Нарушения и рекомендации</h3>
            {complianceReport.violations?.map((violation: any, index: number) => (
              <div key={index} className="violation-item">
                <div className="violation-severity">{violation.severity}</div>
                <div className="violation-description">{violation.description}</div>
                <div className="violation-recommendation">{violation.recommendation}</div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default ScheduleComplianceChecker;