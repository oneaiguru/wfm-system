import React, { useState, useEffect } from 'react';
import { Calendar, Clock, FileText, AlertCircle, CheckCircle, X, Upload, Loader2 } from 'lucide-react';

// Real service imports (no mocks) - SPEC-08 Russian Requests
import realRussianRequestService from '../services/realRussianRequestService';

interface RussianRequestFormProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (request: RussianRequestData) => Promise<void>;
  employeeId?: number;
  initialRequestType?: 'больничный' | 'отгул' | 'отпуск';
}

interface RussianRequestData {
  type: 'больничный' | 'отгул' | 'отпуск' | 'внеочередной отпуск';
  startDate: string;
  endDate: string;
  reason: string;
  description?: string;
  medicalCertificate?: File;
  medicalCertificateNumber?: string;
  emergencyContact?: string;
  halfDay?: boolean;
  workingDaysCount?: number;
  replacementEmployee?: string;
  urgencyLevel?: 'normal' | 'urgent' | 'emergency';
}

interface ValidationErrors {
  [key: string]: string;
}

// Complete Russian translations for SPEC-08
const translations = {
  title: 'Создание заявки',
  requestTypes: {
    'больничный': 'Больничный лист',
    'отгул': 'Отгул',
    'отпуск': 'Отпуск',
    'внеочередной отпуск': 'Внеочередной отпуск'
  },
  labels: {
    requestType: 'Тип заявки',
    startDate: 'Дата начала',
    endDate: 'Дата окончания',
    reason: 'Причина',
    description: 'Дополнительная информация',
    medicalCertificate: 'Медицинская справка',
    emergencyContact: 'Контакт для экстренной связи',
    halfDay: 'Половина дня',
    workingDays: 'Рабочих дней',
    replacementEmployee: 'Замещающий сотрудник',
    submit: 'Создать заявку',
    cancel: 'Отмена',
    uploadFile: 'Прикрепить файл',
    fileUploaded: 'Файл загружен'
  },
  placeholders: {
    reason: 'Укажите причину запроса...',
    description: 'Дополнительная информация о заявке...',
    emergencyContact: '+7 (___) ___-__-__',
    replacementEmployee: 'Выберите сотрудника'
  },
  validation: {
    required: 'Это поле обязательно',
    dateRequired: 'Дата обязательна',
    endDateAfterStart: 'Дата окончания должна быть позже даты начала',
    medicalCertRequired: 'Медицинская справка обязательна для больничного',
    reasonRequired: 'Причина обязательна',
    phoneFormat: 'Неверный формат телефона',
    fileSize: 'Размер файла не должен превышать 5 МБ',
    fileType: 'Разрешены только файлы: PDF, JPG, PNG'
  },
  requestTypeDescriptions: {
    'больничный': 'Временная нетрудоспособность по состоянию здоровья',
    'отгул': 'Дополнительный выходной день за переработку',
    'отпуск': 'Очередной отпуск',
    'внеочередной отпуск': 'Экстренный отпуск по семейным обстоятельствам'
  }
};

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

export const RussianRequestForm: React.FC<RussianRequestFormProps> = ({
  isOpen,
  onClose,
  onSubmit,
  employeeId,
  initialRequestType = 'отпуск'
}) => {
  const [formData, setFormData] = useState<RussianRequestData>({
    type: initialRequestType,
    startDate: '',
    endDate: '',
    reason: '',
    description: '',
    emergencyContact: '',
    halfDay: false,
    workingDaysCount: 0,
    replacementEmployee: '',
    medicalCertificateNumber: '',
    urgencyLevel: 'normal'
  });

  const [errors, setErrors] = useState<ValidationErrors>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [loading, setLoading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);

  // Calculate working days when dates change
  useEffect(() => {
    if (formData.startDate && formData.endDate) {
      const workingDays = calculateWorkingDays(formData.startDate, formData.endDate);
      setFormData(prev => ({ ...prev, workingDaysCount: workingDays }));
    }
  }, [formData.startDate, formData.endDate]);

  const calculateWorkingDays = (startDate: string, endDate: string): number => {
    const start = new Date(startDate);
    const end = new Date(endDate);
    let workingDays = 0;
    
    for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
      const dayOfWeek = d.getDay();
      if (dayOfWeek !== 0 && dayOfWeek !== 6) { // Not Sunday (0) or Saturday (6)
        workingDays++;
      }
    }
    
    return formData.halfDay ? Math.ceil(workingDays / 2) : workingDays;
  };

  const validateForm = (): boolean => {
    const newErrors: ValidationErrors = {};

    // Request type validation
    if (!formData.type) {
      newErrors.type = translations.validation.required;
    }

    // Date validation
    if (!formData.startDate) {
      newErrors.startDate = translations.validation.dateRequired;
    }

    if (!formData.endDate) {
      newErrors.endDate = translations.validation.dateRequired;
    }

    if (formData.startDate && formData.endDate && new Date(formData.endDate) < new Date(formData.startDate)) {
      newErrors.endDate = translations.validation.endDateAfterStart;
    }

    // Reason validation
    if (!formData.reason.trim()) {
      newErrors.reason = translations.validation.reasonRequired;
    }

    // Medical certificate for sick leave
    if (formData.type === 'больничный' && !formData.medicalCertificate) {
      newErrors.medicalCertificate = translations.validation.medicalCertRequired;
    }

    // Emergency contact validation for sick leave
    if (formData.type === 'больничный' && formData.emergencyContact) {
      const phoneRegex = /^\+7\s?\(\d{3}\)\s?\d{3}-\d{2}-\d{2}$/;
      if (!phoneRegex.test(formData.emergencyContact)) {
        newErrors.emergencyContact = translations.validation.phoneFormat;
      }
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    setIsSubmitting(true);
    
    try {
      // Convert employeeId to string for API compatibility
      const employee_id = employeeId ? employeeId.toString() : '1'; // Default for demo
      
      // Prepare request data for SPEC-08 API
      const requestData = {
        employee_id,
        type: formData.type,
        start_date: formData.startDate,
        end_date: formData.endDate,
        reason: formData.reason,
        description: formData.description,
        medical_certificate_number: formData.medicalCertificateNumber,
        emergency_contact: formData.emergencyContact,
        replacement_employee: formData.replacementEmployee,
        urgency_level: formData.urgencyLevel,
        working_days_count: formData.workingDaysCount,
        half_day: formData.halfDay
      };

      console.log('[RUSSIAN REQUEST] Submitting:', formData.type, requestData);

      // Call appropriate SPEC-08 endpoint based on request type
      let result;
      switch (formData.type) {
        case 'больничный':
          result = await realRussianRequestService.submitSickLeaveRequest(
            requestData, 
            formData.medicalCertificate
          );
          break;
        case 'отгул':
          result = await realRussianRequestService.submitTimeOffRequest(requestData);
          break;
        case 'внеочередной отпуск':
          result = await realRussianRequestService.submitUnscheduledVacationRequest(requestData);
          break;
        case 'отпуск':
        default:
          // Use standard vacation endpoint for regular vacation
          result = await realRussianRequestService.submitUnscheduledVacationRequest({
            ...requestData,
            urgency_level: 'normal'
          });
          break;
      }

      if (result.success) {
        console.log('✅ SPEC-08 Russian request submitted successfully:', result.data);
        await onSubmit(formData);
        onClose();
        
        // Reset form
        setFormData({
          type: initialRequestType,
          startDate: '',
          endDate: '',
          reason: '',
          description: '',
          emergencyContact: '',
          halfDay: false,
          workingDaysCount: 0,
          replacementEmployee: '',
          medicalCertificateNumber: '',
          urgencyLevel: 'normal'
        });
      } else {
        console.error('❌ SPEC-08 Russian request failed:', result.error);
        setErrors({ submit: result.error || 'Ошибка отправки заявки' });
      }

    } catch (error) {
      console.error('[RUSSIAN REQUEST] Submission error:', error);
      setErrors({ submit: 'Ошибка отправки заявки. Попробуйте позже.' });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Validate file size (5MB max)
    if (file.size > 5 * 1024 * 1024) {
      setErrors(prev => ({ ...prev, medicalCertificate: translations.validation.fileSize }));
      return;
    }

    // Validate file type
    const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png'];
    if (!allowedTypes.includes(file.type)) {
      setErrors(prev => ({ ...prev, medicalCertificate: translations.validation.fileType }));
      return;
    }

    setFormData(prev => ({ ...prev, medicalCertificate: file }));
    setErrors(prev => ({ ...prev, medicalCertificate: '' }));
  };

  const getRequestTypeIcon = (type: string) => {
    switch (type) {
      case 'больничный': return <AlertCircle className="h-5 w-5 text-red-600" />;
      case 'отгул': return <Clock className="h-5 w-5 text-blue-600" />;
      case 'отпуск': return <Calendar className="h-5 w-5 text-green-600" />;
      case 'внеочередной отпуск': return <AlertCircle className="h-5 w-5 text-orange-600" />;
      default: return <FileText className="h-5 w-5 text-gray-600" />;
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="p-6 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-semibold text-gray-900">{translations.title}</h2>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600"
              disabled={isSubmitting}
            >
              <X className="h-6 w-6" />
            </button>
          </div>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {/* Request Type Selection */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-3">
              {translations.labels.requestType}
            </label>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
              {Object.entries(translations.requestTypes).map(([key, label]) => (
                <button
                  key={key}
                  type="button"
                  onClick={() => setFormData(prev => ({ ...prev, type: key as any }))}
                  className={`p-4 rounded-lg border-2 transition-colors text-left ${
                    formData.type === key
                      ? 'border-blue-500 bg-blue-50 text-blue-900'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  <div className="flex items-center gap-3 mb-2">
                    {getRequestTypeIcon(key)}
                    <span className="font-medium">{label}</span>
                  </div>
                  <p className="text-sm text-gray-600">
                    {translations.requestTypeDescriptions[key as keyof typeof translations.requestTypeDescriptions]}
                  </p>
                </button>
              ))}
            </div>
            {errors.type && <p className="mt-1 text-sm text-red-600">{errors.type}</p>}
          </div>

          {/* Date Range */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                {translations.labels.startDate}
              </label>
              <input
                type="date"
                value={formData.startDate}
                onChange={(e) => setFormData(prev => ({ ...prev, startDate: e.target.value }))}
                className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 ${
                  errors.startDate ? 'border-red-300' : 'border-gray-300'
                }`}
                min={new Date().toISOString().split('T')[0]}
              />
              {errors.startDate && <p className="mt-1 text-sm text-red-600">{errors.startDate}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                {translations.labels.endDate}
              </label>
              <input
                type="date"
                value={formData.endDate}
                onChange={(e) => setFormData(prev => ({ ...prev, endDate: e.target.value }))}
                className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 ${
                  errors.endDate ? 'border-red-300' : 'border-gray-300'
                }`}
                min={formData.startDate || new Date().toISOString().split('T')[0]}
              />
              {errors.endDate && <p className="mt-1 text-sm text-red-600">{errors.endDate}</p>}
            </div>
          </div>

          {/* Working Days Counter */}
          {formData.workingDaysCount > 0 && (
            <div className="bg-blue-50 p-3 rounded-lg">
              <div className="flex items-center gap-2">
                <Calendar className="h-4 w-4 text-blue-600" />
                <span className="text-sm font-medium text-blue-900">
                  {translations.labels.workingDays}: {formData.workingDaysCount}
                </span>
              </div>
            </div>
          )}

          {/* Half Day Option */}
          <div className="flex items-center">
            <input
              id="halfDay"
              type="checkbox"
              checked={formData.halfDay}
              onChange={(e) => setFormData(prev => ({ ...prev, halfDay: e.target.checked }))}
              className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
            />
            <label htmlFor="halfDay" className="ml-2 block text-sm text-gray-900">
              {translations.labels.halfDay}
            </label>
          </div>

          {/* Reason */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              {translations.labels.reason}
            </label>
            <textarea
              value={formData.reason}
              onChange={(e) => setFormData(prev => ({ ...prev, reason: e.target.value }))}
              placeholder={translations.placeholders.reason}
              rows={3}
              className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 ${
                errors.reason ? 'border-red-300' : 'border-gray-300'
              }`}
            />
            {errors.reason && <p className="mt-1 text-sm text-red-600">{errors.reason}</p>}
          </div>

          {/* Medical Certificate Upload (for sick leave) */}
          {formData.type === 'больничный' && (
            <>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {translations.labels.medicalCertificate}
                </label>
                <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center">
                  <input
                    type="file"
                    id="medicalCert"
                    onChange={handleFileUpload}
                    accept=".pdf,.jpg,.jpeg,.png"
                    className="hidden"
                  />
                  <label
                    htmlFor="medicalCert"
                    className="cursor-pointer flex flex-col items-center"
                  >
                    <Upload className="h-8 w-8 text-gray-400 mb-2" />
                    <span className="text-sm text-gray-600">
                      {formData.medicalCertificate 
                        ? `${translations.labels.fileUploaded}: ${formData.medicalCertificate.name}`
                        : translations.labels.uploadFile
                      }
                    </span>
                  </label>
                </div>
                {errors.medicalCertificate && (
                  <p className="mt-1 text-sm text-red-600">{errors.medicalCertificate}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Номер медицинской справки
                </label>
                <input
                  type="text"
                  value={formData.medicalCertificateNumber}
                  onChange={(e) => setFormData(prev => ({ ...prev, medicalCertificateNumber: e.target.value }))}
                  placeholder="Например: 12345-АБ"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
            </>
          )}

          {/* Emergency Contact (for sick leave) */}
          {formData.type === 'больничный' && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                {translations.labels.emergencyContact}
              </label>
              <input
                type="tel"
                value={formData.emergencyContact}
                onChange={(e) => setFormData(prev => ({ ...prev, emergencyContact: e.target.value }))}
                placeholder={translations.placeholders.emergencyContact}
                className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 ${
                  errors.emergencyContact ? 'border-red-300' : 'border-gray-300'
                }`}
              />
              {errors.emergencyContact && (
                <p className="mt-1 text-sm text-red-600">{errors.emergencyContact}</p>
              )}
            </div>
          )}

          {/* Urgency Level (for unscheduled vacation) */}
          {formData.type === 'внеочередной отпуск' && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Уровень срочности
              </label>
              <select
                value={formData.urgencyLevel}
                onChange={(e) => setFormData(prev => ({ ...prev, urgencyLevel: e.target.value as any }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="normal">Обычный</option>
                <option value="urgent">Срочный</option>
                <option value="emergency">Экстренный</option>
              </select>
            </div>
          )}

          {/* Additional Description */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              {translations.labels.description}
            </label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
              placeholder={translations.placeholders.description}
              rows={2}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>

          {/* Submit Error Display */}
          {errors.submit && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-3">
              <p className="text-sm text-red-600">{errors.submit}</p>
            </div>
          )}

          {/* Submit Buttons */}
          <div className="flex gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              disabled={isSubmitting}
              className="flex-1 px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors disabled:opacity-50"
            >
              {translations.labels.cancel}
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
            >
              {isSubmitting && <Loader2 className="h-4 w-4 animate-spin" />}
              {translations.labels.submit}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default RussianRequestForm;