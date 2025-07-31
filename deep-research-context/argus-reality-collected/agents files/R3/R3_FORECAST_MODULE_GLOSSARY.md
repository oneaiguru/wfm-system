# R3-ForecastAnalytics Russian Forecast Module Glossary

**Purpose**: Forecast-specific Russian terminology in Argus analytics interfaces  
**Scope**: Forecast, analytics, and reporting modules only  
**Reference**: Extends R1's RUSSIAN_GLOSSARY.md with forecast-specific terms  
**Last Updated**: 2025-07-28

## 🔄 7-TAB FORECAST WORKFLOW TERMINOLOGY

| Russian Term | English Translation | Tab Context | Interface Location |
|--------------|-------------------|-------------|-------------------|
| Данные | Data/Input | Tab 1 | Main data entry tab |
| Импорт | Import | Tab 2 | Historical data import |
| Обработка | Processing | Tab 3 | Data processing configuration |
| Прогноз | Forecast | Tab 4 | Algorithm selection |
| Результаты | Results | Tab 5 | Forecast output display |
| Отчеты | Reports | Tab 6 | Report generation |
| Экспорт | Export | Tab 7 | Data export options |

## 📊 FORECAST ALGORITHMS & METHODS

| Russian Term | English Translation | Context | Technical Notes |
|--------------|-------------------|---------|----------------|
| Экспоненциальное сглаживание | Exponential smoothing | Algorithm dropdown | Common forecasting method |
| ARIMA модель | ARIMA model | Advanced algorithms | Auto-Regressive Integrated Moving Average |
| Линейная регрессия | Linear regression | Basic algorithms | Trend-based forecasting |
| Сезонная декомпозиция | Seasonal decomposition | Seasonal analysis | Pattern separation |
| Скользящее среднее | Moving average | Smoothing options | Data smoothing technique |
| Горизонт прогноза | Forecast horizon | Time settings | Prediction time period |
| Доверительный интервал | Confidence interval | Result metrics | Uncertainty measurement |
| Точность прогноза | Forecast accuracy | Quality metrics | Prediction reliability |

## 📈 ANALYTICS DASHBOARD TERMS

| Russian Term | English Translation | Context | Dashboard Section |
|--------------|-------------------|---------|------------------|
| Аналитическая панель | Analytics dashboard | Main interface | Dashboard title |
| КПИ | KPI | Performance metrics | Key Performance Indicators |
| Виджет | Widget | Dashboard elements | Interactive components |
| Графики | Charts | Data visualization | Chart components |
| Тренды | Trends | Pattern analysis | Trend displays |
| Метрики | Metrics | Performance data | Measurement displays |
| Фильтры | Filters | Data selection | Filter controls |
| Детализация | Drill-down | Data exploration | Detail view access |

## 📋 DATA PROCESSING TERMINOLOGY

| Russian Term | English Translation | Context | Processing Stage |
|--------------|-------------------|---------|-----------------|
| Исторические данные | Historical data | Data input | Source data |
| Качество данных | Data quality | Validation | Data assessment |
| Сглаживание данных | Data smoothing | Processing | Noise reduction |
| Выбросы | Outliers | Data cleaning | Anomaly detection |
| Параметры обработки | Processing parameters | Configuration | Processing settings |
| Валидация данных | Data validation | Quality check | Data verification |
| Предобработка | Preprocessing | Data preparation | Initial processing |
| Агрегация | Aggregation | Data summarization | Data grouping |

## 📊 FORECAST RESULTS & METRICS

| Russian Term | English Translation | Context | Results Section |
|--------------|-------------------|---------|----------------|
| Прогнозные значения | Forecast values | Results table | Predicted data |
| Средняя абсолютная ошибка | Mean Absolute Error (MAE) | Accuracy metrics | Error measurement |
| Среднеквадратичная ошибка | Root Mean Square Error (RMSE) | Quality metrics | Prediction accuracy |
| Коэффициент детерминации | Coefficient of determination (R²) | Model fit | Statistical measure |
| Остатки | Residuals | Error analysis | Prediction errors |
| Сезонность | Seasonality | Pattern analysis | Recurring patterns |
| Волатильность | Volatility | Risk metrics | Data variability |
| Стабильность модели | Model stability | Reliability | Prediction consistency |

## 📑 REPORTING SYSTEM TERMS

| Russian Term | English Translation | Context | Report Feature |
|--------------|-------------------|---------|---------------|
| Шаблон отчета | Report template | Report builder | Predefined formats |
| Сводка прогноза | Forecast summary | Report type | Summary report |
| Детальный отчет | Detailed report | Report type | Comprehensive report |
| Автоматическая генерация | Automatic generation | Scheduling | Auto-report creation |
| Формат вывода | Output format | Export options | File format selection |
| Периодичность | Frequency | Schedule settings | Report timing |
| Получатели | Recipients | Distribution | Report delivery |
| Визуализация | Visualization | Chart options | Data presentation |

## 🔧 SYSTEM CONFIGURATION TERMS

| Russian Term | English Translation | Context | Configuration Area |
|--------------|-------------------|---------|-------------------|
| Настройки алгоритма | Algorithm settings | Configuration | Algorithm parameters |
| Временные ряды | Time series | Data type | Sequential data |
| Интервал дискретизации | Sampling interval | Time settings | Data frequency |
| Базовый период | Base period | Reference time | Historical baseline |
| Модель тренда | Trend model | Pattern analysis | Trend configuration |
| Коррекция сезонности | Seasonal adjustment | Data processing | Seasonal correction |
| Лаг | Lag | Time delay | Data delay periods |
| Автокорреляция | Autocorrelation | Statistical analysis | Self-correlation |

## ⚠️ ERROR MESSAGES & STATUS INDICATORS

| Russian Term | English Translation | Context | Error Type |
|--------------|-------------------|---------|------------|
| Ошибка обработки данных | Data processing error | Processing failures | Calculation errors |
| Недостаточно данных | Insufficient data | Data validation | Data shortage |
| Превышено время ожидания | Timeout exceeded | Processing limits | Long calculations |
| Неверные параметры | Invalid parameters | Input validation | Configuration errors |
| Модель не сходится | Model does not converge | Algorithm failure | Calculation failure |
| Данные повреждены | Data corrupted | Data integrity | Data quality issues |
| Обработка завершена | Processing completed | Success status | Completion indicator |
| Готов к экспорту | Ready for export | Export status | Final stage indicator |

## 🆔 FORECAST-SPECIFIC ID PATTERNS

| Pattern | Example | Context | Generation Context |
|---------|---------|---------|-------------------|
| Forecast-XXXXXXX | Forecast-12919876 | Forecast job ID | Algorithm execution |
| Model-XXXXXXX | Model-12919877 | Model instance ID | Model creation |
| Report-XXXXXXX | Report-12919878 | Report generation ID | Report creation |
| Dataset-XXXXXXX | Dataset-12919879 | Data import ID | Data loading |

## 📝 R3-SPECIFIC USAGE NOTES

### Forecast Terminology Standards
- **Always capture exact Russian text** from forecast interfaces
- **Include technical context** (algorithm, processing stage, results)
- **Note tab location** where term appears in 7-tab workflow
- **Document mathematical meanings** for statistical terms

### Update Process During MCP Testing
- **During tab navigation**: Capture all new forecast terms
- **During algorithm testing**: Record technical terminology
- **During results review**: Document metric and accuracy terms
- **During report generation**: Capture report-specific language

### Special Forecast Considerations
- **Mathematical terms**: May have standard statistical meanings
- **Algorithm names**: Often transliterated (ARIMA → ARIMA)
- **English abbreviations**: KPI, MAE, RMSE may appear unchanged
- **Processing status**: Dynamic text changes during calculations

This glossary focuses exclusively on forecast-specific terminology. For general Argus terms (login, navigation, errors), reference R1's RUSSIAN_GLOSSARY.md.