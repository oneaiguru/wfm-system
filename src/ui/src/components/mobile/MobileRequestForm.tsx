import React, { useState, useEffect, useRef } from 'react';
import { offlineStorage, addOfflineRequest } from '../offline/OfflineStorage';
import OfflineIndicator from '../offline/OfflineIndicator';
import { realMobileService } from '../../services/realMobileService';
import './MobileRequestForm.css';

interface RequestType {
  id: string;
  name: string;
  description: string;
  icon: string;
  requires_approval: boolean;
  max_advance_days: number;
  allow_recurring: boolean;
}

interface FormField {
  name: string;
  type: 'text' | 'date' | 'time' | 'select' | 'textarea' | 'checkbox' | 'radio' | 'file';
  label: string;
  required: boolean;
  options?: string[];
  placeholder?: string;
  min?: string;
  max?: string;
}

interface AttachmentFile {
  file: File;
  preview?: string;
  uploaded?: boolean;
}

interface MobileRequestFormProps {
  employeeId: string;
  onSubmit: (request: any) => Promise<void>;
  onCancel?: () => void;
  initialRequestType?: string;
}

const MobileRequestForm: React.FC<MobileRequestFormProps> = ({
  employeeId,
  onSubmit,
  onCancel,
  initialRequestType
}) => {
  const [requestTypes, setRequestTypes] = useState<RequestType[]>([]);
  const [selectedType, setSelectedType] = useState<RequestType | null>(null);
  const [formFields, setFormFields] = useState<FormField[]>([]);
  const [formData, setFormData] = useState<Record<string, any>>({});
  const [attachments, setAttachments] = useState<AttachmentFile[]>([]);
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [step, setStep] = useState<'type' | 'form' | 'preview'>('type');
  const [isOffline, setIsOffline] = useState(!navigator.onLine);
  const [pendingSync, setPendingSync] = useState(0);
  
  const fileInputRef = useRef<HTMLInputElement>(null);
  const formRef = useRef<HTMLFormElement>(null);

  useEffect(() => {
    loadRequestTypes();
    
    // Monitor network status
    const handleOnline = () => setIsOffline(false);
    const handleOffline = () => setIsOffline(true);
    
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    
    // Check pending sync items
    checkPendingSync();
    
    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  useEffect(() => {
    if (selectedType) {
      loadFormFields(selectedType.id);
    }
  }, [selectedType]);

  const checkPendingSync = async () => {
    const syncStatus = realMobileService.getSyncStatus();
    setPendingSync(syncStatus.pendingActions);
  };

  const loadRequestTypes = async () => {
    setLoading(true);
    try {
      // Try cache first
      const cached = await offlineStorage.getCache('request_types');
      if (cached) {
        setRequestTypes(cached);
      }

      // Try network if online
      if (navigator.onLine) {
        const response = await fetch('/api/v1/mobile/requests/types', {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
            'Content-Type': 'application/json'
          }
        });

        if (response.ok) {
          const types = await response.json();
          setRequestTypes(types);
          
          // Cache for offline use
          await offlineStorage.setCache('request_types', types, 3600); // 1 hour
          
          if (initialRequestType) {
            const initialType = types.find((t: RequestType) => t.id === initialRequestType);
            if (initialType) {
              setSelectedType(initialType);
              setStep('form');
            }
          }
        }
      } else if (!cached) {
        // Provide default request types for offline use
        const defaultTypes: RequestType[] = [
          {
            id: 'vacation',
            name: 'Отпуск',
            description: 'Заявка на отпуск',
            icon: '🏖️',
            requires_approval: true,
            max_advance_days: 30,
            allow_recurring: false
          },
          {
            id: 'sick_leave',
            name: 'Больничный',
            description: 'Заявка на больничный',
            icon: '🏥',
            requires_approval: false,
            max_advance_days: 0,
            allow_recurring: false
          }
        ];
        setRequestTypes(defaultTypes);
        await offlineStorage.setCache('request_types', defaultTypes, 3600);
      }
    } catch (error) {
      console.error('Ошибка загрузки типов запросов:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadFormFields = async (typeId: string) => {
    try {
      const response = await fetch(`/api/v1/mobile/requests/fields/${typeId}`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const fields = await response.json();
        setFormFields(fields);
        
        // Initialize form data with default values
        const initialData: Record<string, any> = {};
        fields.forEach((field: FormField) => {
          if (field.type === 'checkbox') {
            initialData[field.name] = false;
          } else if (field.type === 'date' && field.name === 'date_from') {
            initialData[field.name] = new Date().toISOString().split('T')[0];
          } else {
            initialData[field.name] = '';
          }
        });
        setFormData(initialData);
      }
    } catch (error) {
      console.error('Ошибка загрузки полей формы:', error);
    }
  };

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};
    
    formFields.forEach(field => {
      if (field.required && !formData[field.name]) {
        newErrors[field.name] = `Поле "${field.label}" обязательно для заполнения`;
      }
      
      if (field.type === 'date' && formData[field.name]) {
        const selectedDate = new Date(formData[field.name]);
        const today = new Date();
        const maxDate = new Date(today.getTime() + (selectedType?.max_advance_days || 30) * 24 * 60 * 60 * 1000);
        
        if (selectedDate < today) {
          newErrors[field.name] = 'Дата не может быть в прошлом';
        } else if (selectedDate > maxDate) {
          newErrors[field.name] = `Максимальная дата: ${maxDate.toLocaleDateString('ru-RU')}`;
        }
      }
      
      if (field.type === 'time' && formData[field.name]) {
        const timeRegex = /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/;
        if (!timeRegex.test(formData[field.name])) {
          newErrors[field.name] = 'Неверный формат времени';
        }
      }
    });
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleFieldChange = (fieldName: string, value: any) => {
    setFormData(prev => ({ ...prev, [fieldName]: value }));
    
    // Clear error for this field
    if (errors[fieldName]) {
      setErrors(prev => ({ ...prev, [fieldName]: '' }));
    }
  };

  const handleFileSelection = (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(event.target.files || []);
    
    files.forEach(file => {
      if (file.size > 10 * 1024 * 1024) { // 10MB limit
        alert(`Файл "${file.name}" слишком большой. Максимальный размер: 10MB`);
        return;
      }
      
      const attachment: AttachmentFile = { file };
      
      // Create preview for images
      if (file.type.startsWith('image/')) {
        const reader = new FileReader();
        reader.onload = (e) => {
          attachment.preview = e.target?.result as string;
          setAttachments(prev => [...prev, attachment]);
        };
        reader.readAsDataURL(file);
      } else {
        setAttachments(prev => [...prev, attachment]);
      }
    });
    
    // Reset file input
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const removeAttachment = (index: number) => {
    setAttachments(prev => prev.filter((_, i) => i !== index));
  };

  const submitRequest = async () => {
    if (!validateForm()) return;
    
    setSubmitting(true);
    try {
      const requestData = {
        employee_id: employeeId,
        request_type_id: selectedType!.id,
        form_data: formData,
        attachments: attachments.map(a => ({
          name: a.file.name,
          size: a.file.size,
          type: a.file.type
        })),
        created_offline: !navigator.onLine,
        timestamp: new Date().toISOString()
      };

      if (navigator.onLine) {
        // Online submission
        const formDataToSubmit = new FormData();
        
        // Add form fields
        formDataToSubmit.append('employee_id', employeeId);
        formDataToSubmit.append('request_type_id', selectedType!.id);
        formDataToSubmit.append('form_data', JSON.stringify(formData));
        
        // Add attachments
        attachments.forEach((attachment, index) => {
          formDataToSubmit.append(`attachment_${index}`, attachment.file);
        });
        
        const response = await fetch('/api/v1/mobile/requests/submit', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
          },
          body: formDataToSubmit
        });
        
        if (response.ok) {
          const result = await response.json();
          await onSubmit(result);
          
          // Reset form
          setFormData({});
          setAttachments([]);
          setStep('type');
          setSelectedType(null);
          
          alert('Заявка успешно отправлена!');
        } else {
          throw new Error('Ошибка отправки заявки');
        }
      } else {
        // Offline submission - queue for sync
        const offlineId = await addOfflineRequest(requestData);
        
        // Queue in mobile service for sync
        await realMobileService.queueOfflineAction({
          type: 'request',
          data: requestData
        });
        
        await onSubmit({
          id: offlineId,
          status: 'pending_sync',
          ...requestData
        });
        
        // Reset form
        setFormData({});
        setAttachments([]);
        setStep('type');
        setSelectedType(null);
        
        // Update pending count
        await checkPendingSync();
        
        alert('Заявка сохранена для отправки при подключении к сети!');
      }
    } catch (error) {
      console.error('Ошибка отправки заявки:', error);
      alert(isOffline 
        ? 'Заявка сохранена для отправки при подключении к сети!' 
        : 'Ошибка отправки заявки. Попробуйте позже.'
      );
    } finally {
      setSubmitting(false);
    }
  };

  const renderField = (field: FormField) => {
    const value = formData[field.name] || '';
    const hasError = !!errors[field.name];
    
    const baseProps = {
      className: `mobile-form__input ${hasError ? 'mobile-form__input--error' : ''}`,
      value,
      onChange: (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => 
        handleFieldChange(field.name, e.target.value),
      required: field.required,
      placeholder: field.placeholder
    };

    switch (field.type) {
      case 'text':
        return (
          <input
            type="text"
            {...baseProps}
          />
        );
      
      case 'date':
        return (
          <input
            type="date"
            {...baseProps}
            min={field.min || new Date().toISOString().split('T')[0]}
            max={field.max}
          />
        );
      
      case 'time':
        return (
          <input
            type="time"
            {...baseProps}
            min={field.min}
            max={field.max}
          />
        );
      
      case 'select':
        return (
          <select {...baseProps}>
            <option value="">Выберите...</option>
            {field.options?.map(option => (
              <option key={option} value={option}>{option}</option>
            ))}
          </select>
        );
      
      case 'textarea':
        return (
          <textarea
            {...baseProps}
            rows={4}
          />
        );
      
      case 'checkbox':
        return (
          <label className="mobile-form__checkbox">
            <input
              type="checkbox"
              checked={value}
              onChange={(e) => handleFieldChange(field.name, e.target.checked)}
            />
            <span className="mobile-form__checkbox-text">{field.label}</span>
          </label>
        );
      
      case 'radio':
        return (
          <div className="mobile-form__radio-group">
            {field.options?.map(option => (
              <label key={option} className="mobile-form__radio">
                <input
                  type="radio"
                  name={field.name}
                  value={option}
                  checked={value === option}
                  onChange={(e) => handleFieldChange(field.name, e.target.value)}
                />
                <span className="mobile-form__radio-text">{option}</span>
              </label>
            ))}
          </div>
        );
      
      default:
        return null;
    }
  };

  const renderTypeSelection = () => (
    <div className="mobile-form__type-selection">
      <div className="mobile-form__header">
        <h2>Создать заявку</h2>
        <p>Выберите тип заявки</p>
        <OfflineIndicator className="mobile-form__offline-indicator" />
        {pendingSync > 0 && (
          <div className="mobile-form__pending-sync">
            📤 {pendingSync} заявок ожидает синхронизации
          </div>
        )}
      </div>
      
      <div className="mobile-form__types">
        {requestTypes.map(type => (
          <div
            key={type.id}
            className="mobile-form__type-card"
            onClick={() => {
              setSelectedType(type);
              setStep('form');
            }}
          >
            <div className="mobile-form__type-icon">
              {type.icon}
            </div>
            <div className="mobile-form__type-content">
              <h3>{type.name}</h3>
              <p>{type.description}</p>
              {type.requires_approval && (
                <div className="mobile-form__type-approval">
                  ✅ Требует согласования
                </div>
              )}
            </div>
            <div className="mobile-form__type-arrow">
              ▶️
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  const renderForm = () => (
    <div className="mobile-form__form">
      <div className="mobile-form__header">
        <button
          className="mobile-form__back-button"
          onClick={() => setStep('type')}
        >
          ◀️
        </button>
        <div>
          <h2>{selectedType?.name}</h2>
          <p>Заполните форму</p>
        </div>
      </div>
      
      <form ref={formRef} className="mobile-form__fields">
        {formFields.map(field => (
          <div key={field.name} className="mobile-form__field">
            {field.type !== 'checkbox' && (
              <label className="mobile-form__label">
                {field.label}
                {field.required && <span className="mobile-form__required">*</span>}
              </label>
            )}
            
            {renderField(field)}
            
            {errors[field.name] && (
              <div className="mobile-form__error">{errors[field.name]}</div>
            )}
          </div>
        ))}
        
        <div className="mobile-form__attachments">
          <label className="mobile-form__label">Прикрепить файлы</label>
          
          <button
            type="button"
            className="mobile-form__attach-button"
            onClick={() => fileInputRef.current?.click()}
          >
            📎 Добавить файл
          </button>
          
          <input
            ref={fileInputRef}
            type="file"
            multiple
            accept="image/*,.pdf,.doc,.docx,.txt"
            onChange={handleFileSelection}
            style={{ display: 'none' }}
          />
          
          {attachments.length > 0 && (
            <div className="mobile-form__attachment-list">
              {attachments.map((attachment, index) => (
                <div key={index} className="mobile-form__attachment">
                  {attachment.preview ? (
                    <img 
                      src={attachment.preview} 
                      alt={attachment.file.name}
                      className="mobile-form__attachment-preview"
                    />
                  ) : (
                    <div className="mobile-form__attachment-icon">
                      📄
                    </div>
                  )}
                  
                  <div className="mobile-form__attachment-info">
                    <div className="mobile-form__attachment-name">
                      {attachment.file.name}
                    </div>
                    <div className="mobile-form__attachment-size">
                      {(attachment.file.size / 1024 / 1024).toFixed(2)} MB
                    </div>
                  </div>
                  
                  <button
                    type="button"
                    className="mobile-form__attachment-remove"
                    onClick={() => removeAttachment(index)}
                  >
                    ❌
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      </form>
      
      <div className="mobile-form__actions">
        <button
          type="button"
          className="mobile-form__button mobile-form__button--secondary"
          onClick={() => setStep('preview')}
          disabled={!validateForm()}
        >
          Предварительный просмотр
        </button>
        
        <button
          type="button"
          className="mobile-form__button mobile-form__button--primary"
          onClick={submitRequest}
          disabled={submitting}
        >
          {submitting 
            ? 'Отправка...' 
            : isOffline 
              ? '💾 Сохранить для синхронизации' 
              : 'Отправить заявку'
          }
        </button>
      </div>
    </div>
  );

  const renderPreview = () => (
    <div className="mobile-form__preview">
      <div className="mobile-form__header">
        <button
          className="mobile-form__back-button"
          onClick={() => setStep('form')}
        >
          ◀️
        </button>
        <div>
          <h2>Предварительный просмотр</h2>
          <p>Проверьте данные перед отправкой</p>
        </div>
      </div>
      
      <div className="mobile-form__preview-content">
        <div className="mobile-form__preview-type">
          <h3>{selectedType?.name}</h3>
          <p>{selectedType?.description}</p>
        </div>
        
        <div className="mobile-form__preview-fields">
          {formFields
            .filter(field => formData[field.name])
            .map(field => (
              <div key={field.name} className="mobile-form__preview-field">
                <label>{field.label}:</label>
                <span>
                  {field.type === 'checkbox' 
                    ? (formData[field.name] ? 'Да' : 'Нет')
                    : formData[field.name]
                  }
                </span>
              </div>
            ))}
        </div>
        
        {attachments.length > 0 && (
          <div className="mobile-form__preview-attachments">
            <h4>Прикрепленные файлы:</h4>
            {attachments.map((attachment, index) => (
              <div key={index}>• {attachment.file.name}</div>
            ))}
          </div>
        )}
      </div>
      
      <div className="mobile-form__actions">
        <button
          type="button"
          className="mobile-form__button mobile-form__button--secondary"
          onClick={() => setStep('form')}
        >
          Редактировать
        </button>
        
        <button
          type="button"
          data-testid="create-request"
          className="mobile-form__button mobile-form__button--primary"
          onClick={submitRequest}
          disabled={submitting}
        >
          {submitting 
            ? 'Отправка...' 
            : isOffline 
              ? '💾 Сохранить для синхронизации' 
              : 'Отправить заявку'
          }
        </button>
      </div>
    </div>
  );

  if (loading) {
    return (
      <div className="mobile-form__loading">
        <div className="mobile-form__spinner"></div>
        <p>Загрузка...</p>
      </div>
    );
  }

  return (
    <div className="mobile-form">
      {step === 'type' && renderTypeSelection()}
      {step === 'form' && renderForm()}
      {step === 'preview' && renderPreview()}
      
      {onCancel && (
        <button
          className="mobile-form__cancel"
          onClick={onCancel}
        >
          Отмена
        </button>
      )}
    </div>
  );
};

export default MobileRequestForm;