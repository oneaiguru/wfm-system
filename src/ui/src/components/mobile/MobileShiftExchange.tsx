import React, { useState, useEffect, useRef } from 'react';
import './MobileShiftExchange.css';

interface Shift {
  id: string;
  date: string;
  start_time: string;
  end_time: string;
  position: string;
  location: string;
  employee_id: string;
  employee_name: string;
  status: 'available' | 'pending' | 'accepted' | 'completed';
  is_mine: boolean;
  can_exchange: boolean;
  exchange_deadline?: string;
  overtime_hours?: number;
  special_requirements?: string[];
}

interface ExchangeRequest {
  id: string;
  from_shift_id: string;
  to_shift_id: string;
  requesting_employee: string;
  target_employee: string;
  status: 'pending' | 'accepted' | 'rejected' | 'expired';
  created_at: string;
  expires_at: string;
  message?: string;
}

interface MobileShiftExchangeProps {
  employeeId: string;
  onExchangeRequest?: (request: ExchangeRequest) => void;
  onExchangeResponse?: (requestId: string, accepted: boolean) => void;
}

const MobileShiftExchange: React.FC<MobileShiftExchangeProps> = ({
  employeeId,
  onExchangeRequest,
  onExchangeResponse
}) => {
  const [myShifts, setMyShifts] = useState<Shift[]>([]);
  const [availableShifts, setAvailableShifts] = useState<Shift[]>([]);
  const [exchangeRequests, setExchangeRequests] = useState<ExchangeRequest[]>([]);
  const [activeTab, setActiveTab] = useState<'available' | 'my-shifts' | 'requests'>('available');
  const [selectedShift, setSelectedShift] = useState<Shift | null>(null);
  const [targetShift, setTargetShift] = useState<Shift | null>(null);
  const [loading, setLoading] = useState(false);
  const [swipeState, setSwipeState] = useState<{
    shiftId: string;
    direction: 'left' | 'right' | null;
    startX: number;
    currentX: number;
  } | null>(null);
  
  const listRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    loadShiftData();
    loadExchangeRequests();
  }, [employeeId]);

  const loadShiftData = async () => {
    setLoading(true);
    try {
      const [myShiftsResponse, availableShiftsResponse] = await Promise.all([
        fetch(`/api/v1/mobile/shifts/my-shifts?employee_id=${employeeId}`, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
            'Content-Type': 'application/json'
          }
        }),
        fetch(`/api/v1/mobile/shifts/available-for-exchange?employee_id=${employeeId}`, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
            'Content-Type': 'application/json'
          }
        })
      ]);

      if (myShiftsResponse.ok) {
        const myShiftsData = await myShiftsResponse.json();
        setMyShifts(myShiftsData.shifts || []);
      }

      if (availableShiftsResponse.ok) {
        const availableShiftsData = await availableShiftsResponse.json();
        setAvailableShifts(availableShiftsData.shifts || []);
      }
    } catch (error) {
      console.error('Ошибка загрузки смен:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadExchangeRequests = async () => {
    try {
      const response = await fetch(`/api/v1/mobile/shifts/exchange-requests?employee_id=${employeeId}`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        setExchangeRequests(data.requests || []);
      }
    } catch (error) {
      console.error('Ошибка загрузки запросов на обмен:', error);
    }
  };

  const handleSwipeStart = (e: React.TouchEvent, shift: Shift) => {
    setSwipeState({
      shiftId: shift.id,
      direction: null,
      startX: e.touches[0].clientX,
      currentX: e.touches[0].clientX
    });
  };

  const handleSwipeMove = (e: React.TouchEvent) => {
    if (!swipeState) return;

    const currentX = e.touches[0].clientX;
    const deltaX = currentX - swipeState.startX;
    const direction = deltaX > 0 ? 'right' : 'left';

    setSwipeState(prev => prev ? {
      ...prev,
      currentX,
      direction: Math.abs(deltaX) > 20 ? direction : null
    } : null);
  };

  const handleSwipeEnd = (shift: Shift) => {
    if (!swipeState) return;

    const deltaX = swipeState.currentX - swipeState.startX;
    const minSwipeDistance = 80;

    if (Math.abs(deltaX) > minSwipeDistance) {
      if (deltaX > 0) {
        // Swipe right - accept/take shift
        handleSwipeAction(shift, 'accept');
      } else {
        // Swipe left - reject/pass shift
        handleSwipeAction(shift, 'reject');
      }
    }

    setSwipeState(null);
  };

  const handleSwipeAction = async (shift: Shift, action: 'accept' | 'reject') => {
    if (activeTab === 'available' && action === 'accept') {
      // Take an available shift
      await takeShift(shift);
    } else if (activeTab === 'requests') {
      // Respond to exchange request
      const request = exchangeRequests.find(r => 
        r.from_shift_id === shift.id || r.to_shift_id === shift.id
      );
      if (request) {
        await respondToExchangeRequest(request.id, action === 'accept');
      }
    }
  };

  const takeShift = async (shift: Shift) => {
    try {
      const response = await fetch('/api/v1/mobile/shifts/take', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          shift_id: shift.id,
          employee_id: employeeId
        })
      });

      if (response.ok) {
        // Refresh data
        await loadShiftData();
        alert('Смена успешно взята!');
      } else {
        const error = await response.json();
        throw new Error(error.message || 'Ошибка при взятии смены');
      }
    } catch (error) {
      console.error('Ошибка взятия смены:', error);
      alert('Не удалось взять смену');
    }
  };

  const requestShiftExchange = async (myShift: Shift, targetShift: Shift, message?: string) => {
    try {
      const response = await fetch('/api/v1/mobile/shifts/exchange', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          from_shift_id: myShift.id,
          to_shift_id: targetShift.id,
          requesting_employee: employeeId,
          message
        })
      });

      if (response.ok) {
        const newRequest = await response.json();
        
        if (onExchangeRequest) {
          onExchangeRequest(newRequest);
        }
        
        // Refresh requests
        await loadExchangeRequests();
        alert('Запрос на обмен отправлен!');
      } else {
        const error = await response.json();
        throw new Error(error.message || 'Ошибка отправки запроса');
      }
    } catch (error) {
      console.error('Ошибка запроса обмена:', error);
      alert('Не удалось отправить запрос на обмен');
    }
  };

  const respondToExchangeRequest = async (requestId: string, accepted: boolean) => {
    try {
      const response = await fetch(`/api/v1/mobile/shifts/exchange/${requestId}/respond`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('mobile_auth_token')}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ accepted })
      });

      if (response.ok) {
        if (onExchangeResponse) {
          onExchangeResponse(requestId, accepted);
        }
        
        // Refresh all data
        await Promise.all([loadShiftData(), loadExchangeRequests()]);
        
        alert(accepted ? 'Обмен принят!' : 'Обмен отклонен');
      } else {
        const error = await response.json();
        throw new Error(error.message || 'Ошибка ответа на запрос');
      }
    } catch (error) {
      console.error('Ошибка ответа на запрос обмена:', error);
      alert('Не удалось ответить на запрос');
    }
  };

  const formatDate = (dateString: string): string => {
    const date = new Date(dateString);
    const today = new Date();
    const tomorrow = new Date(today);
    tomorrow.setDate(today.getDate() + 1);

    if (date.toDateString() === today.toDateString()) {
      return 'Сегодня';
    } else if (date.toDateString() === tomorrow.toDateString()) {
      return 'Завтра';
    } else {
      return date.toLocaleDateString('ru-RU', {
        weekday: 'short',
        day: '2-digit',
        month: '2-digit'
      });
    }
  };

  const formatTime = (time: string): string => {
    return new Date(`2000-01-01T${time}`).toLocaleTimeString('ru-RU', {
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const getSwipeTransform = (shiftId: string): string => {
    if (!swipeState || swipeState.shiftId !== shiftId) return 'translateX(0)';
    
    const deltaX = swipeState.currentX - swipeState.startX;
    const maxTranslate = 100;
    const translate = Math.max(-maxTranslate, Math.min(maxTranslate, deltaX));
    
    return `translateX(${translate}px)`;
  };

  const getSwipeBackground = (shiftId: string): string => {
    if (!swipeState || swipeState.shiftId !== shiftId || !swipeState.direction) {
      return 'transparent';
    }
    
    return swipeState.direction === 'right' ? '#48bb78' : '#e53e3e';
  };

  const getSwipeIcon = (shiftId: string): string => {
    if (!swipeState || swipeState.shiftId !== shiftId || !swipeState.direction) {
      return '';
    }
    
    return swipeState.direction === 'right' ? '✅' : '❌';
  };

  const renderShiftCard = (shift: Shift, showActions = true) => (
    <div
      key={shift.id}
      className="shift-exchange__card"
      style={{
        transform: getSwipeTransform(shift.id),
        backgroundColor: getSwipeBackground(shift.id)
      }}
      onTouchStart={(e) => handleSwipeStart(e, shift)}
      onTouchMove={handleSwipeMove}
      onTouchEnd={() => handleSwipeEnd(shift)}
    >
      <div className="shift-exchange__swipe-indicator">
        {getSwipeIcon(shift.id)}
      </div>
      
      <div className="shift-exchange__card-content">
        <div className="shift-exchange__card-header">
          <div className="shift-exchange__date-time">
            <div className="shift-exchange__date">{formatDate(shift.date)}</div>
            <div className="shift-exchange__time">
              {formatTime(shift.start_time)} - {formatTime(shift.end_time)}
            </div>
          </div>
          
          <div className="shift-exchange__status">
            <span className={`shift-exchange__status-badge shift-exchange__status--${shift.status}`}>
              {shift.status === 'available' && '🔓 Доступна'}
              {shift.status === 'pending' && '⏳ Ожидание'}
              {shift.status === 'accepted' && '✅ Принята'}
              {shift.status === 'completed' && '✔️ Завершена'}
            </span>
          </div>
        </div>
        
        <div className="shift-exchange__card-details">
          <div className="shift-exchange__position">
            📍 {shift.location} • 👤 {shift.position}
          </div>
          
          {!shift.is_mine && (
            <div className="shift-exchange__employee">
              Сотрудник: {shift.employee_name}
            </div>
          )}
          
          {shift.overtime_hours && shift.overtime_hours > 0 && (
            <div className="shift-exchange__overtime">
              ⏰ Сверхурочно: {shift.overtime_hours}ч
            </div>
          )}
          
          {shift.special_requirements && shift.special_requirements.length > 0 && (
            <div className="shift-exchange__requirements">
              📋 Требования: {shift.special_requirements.join(', ')}
            </div>
          )}
          
          {shift.exchange_deadline && (
            <div className="shift-exchange__deadline">
              ⏰ Обмен до: {new Date(shift.exchange_deadline).toLocaleDateString('ru-RU')}
            </div>
          )}
        </div>
        
        {showActions && (
          <div className="shift-exchange__card-actions">
            {activeTab === 'available' && shift.can_exchange && (
              <button
                className="shift-exchange__action-button shift-exchange__action-button--take"
                onClick={() => takeShift(shift)}
              >
                Взять смену
              </button>
            )}
            
            {activeTab === 'my-shifts' && shift.can_exchange && (
              <button
                className="shift-exchange__action-button shift-exchange__action-button--exchange"
                onClick={() => setSelectedShift(shift)}
              >
                Обменять
              </button>
            )}
          </div>
        )}
      </div>
    </div>
  );

  const renderExchangeRequestCard = (request: ExchangeRequest) => {
    const fromShift = myShifts.find(s => s.id === request.from_shift_id) ||
                     availableShifts.find(s => s.id === request.from_shift_id);
    const toShift = myShifts.find(s => s.id === request.to_shift_id) ||
                   availableShifts.find(s => s.id === request.to_shift_id);

    return (
      <div key={request.id} className="shift-exchange__request-card">
        <div className="shift-exchange__request-header">
          <div className="shift-exchange__request-status">
            <span className={`shift-exchange__status-badge shift-exchange__status--${request.status}`}>
              {request.status === 'pending' && '⏳ Ожидание ответа'}
              {request.status === 'accepted' && '✅ Принят'}
              {request.status === 'rejected' && '❌ Отклонен'}
              {request.status === 'expired' && '⏰ Истек'}
            </span>
          </div>
          
          <div className="shift-exchange__request-time">
            {new Date(request.created_at).toLocaleDateString('ru-RU')}
          </div>
        </div>
        
        <div className="shift-exchange__request-content">
          <div className="shift-exchange__request-employee">
            {request.requesting_employee === employeeId 
              ? `Запрос к: ${request.target_employee}`
              : `От: ${request.requesting_employee}`
            }
          </div>
          
          {request.message && (
            <div className="shift-exchange__request-message">
              💬 {request.message}
            </div>
          )}
          
          <div className="shift-exchange__request-shifts">
            <div className="shift-exchange__request-shift">
              <div className="shift-exchange__request-shift-label">Отдает:</div>
              {fromShift && renderShiftCard(fromShift, false)}
            </div>
            
            <div className="shift-exchange__exchange-arrow">⇅</div>
            
            <div className="shift-exchange__request-shift">
              <div className="shift-exchange__request-shift-label">Получает:</div>
              {toShift && renderShiftCard(toShift, false)}
            </div>
          </div>
        </div>
        
        {request.status === 'pending' && request.target_employee === employeeId && (
          <div className="shift-exchange__request-actions">
            <button
              className="shift-exchange__action-button shift-exchange__action-button--accept"
              onClick={() => respondToExchangeRequest(request.id, true)}
            >
              ✅ Принять
            </button>
            <button
              className="shift-exchange__action-button shift-exchange__action-button--reject"
              onClick={() => respondToExchangeRequest(request.id, false)}
            >
              ❌ Отклонить
            </button>
          </div>
        )}
      </div>
    );
  };

  const renderContent = () => {
    if (loading) {
      return (
        <div className="shift-exchange__loading">
          <div className="shift-exchange__spinner"></div>
          <p>Загрузка смен...</p>
        </div>
      );
    }

    switch (activeTab) {
      case 'available':
        return (
          <div className="shift-exchange__content">
            <div className="shift-exchange__swipe-hint">
              💡 Проведите вправо, чтобы взять смену
            </div>
            {availableShifts.length === 0 ? (
              <div className="shift-exchange__empty">
                <div className="shift-exchange__empty-icon">📅</div>
                <h3>Нет доступных смен</h3>
                <p>В данный момент нет смен для обмена</p>
              </div>
            ) : (
              <div ref={listRef} className="shift-exchange__list">
                {availableShifts.map(shift => renderShiftCard(shift))}
              </div>
            )}
          </div>
        );

      case 'my-shifts':
        return (
          <div className="shift-exchange__content">
            {myShifts.length === 0 ? (
              <div className="shift-exchange__empty">
                <div className="shift-exchange__empty-icon">🗓️</div>
                <h3>Нет смен для обмена</h3>
                <p>У вас нет смен, доступных для обмена</p>
              </div>
            ) : (
              <div ref={listRef} className="shift-exchange__list">
                {myShifts.filter(shift => shift.can_exchange).map(shift => renderShiftCard(shift))}
              </div>
            )}
          </div>
        );

      case 'requests':
        return (
          <div className="shift-exchange__content">
            <div className="shift-exchange__swipe-hint">
              💡 Проведите вправо для принятия, влево для отклонения
            </div>
            {exchangeRequests.length === 0 ? (
              <div className="shift-exchange__empty">
                <div className="shift-exchange__empty-icon">📋</div>
                <h3>Нет запросов на обмен</h3>
                <p>У вас нет активных запросов на обмен смен</p>
              </div>
            ) : (
              <div ref={listRef} className="shift-exchange__list">
                {exchangeRequests.map(request => renderExchangeRequestCard(request))}
              </div>
            )}
          </div>
        );

      default:
        return null;
    }
  };

  return (
    <div className="shift-exchange">
      <div className="shift-exchange__header">
        <h2>Обмен сменами</h2>
        <p>Найдите и обменяйтесь сменами с коллегами</p>
      </div>

      <div className="shift-exchange__tabs">
        <button
          className={`shift-exchange__tab ${activeTab === 'available' ? 'active' : ''}`}
          onClick={() => setActiveTab('available')}
        >
          🔓 Доступные ({availableShifts.length})
        </button>
        <button
          className={`shift-exchange__tab ${activeTab === 'my-shifts' ? 'active' : ''}`}
          onClick={() => setActiveTab('my-shifts')}
        >
          📅 Мои смены ({myShifts.filter(s => s.can_exchange).length})
        </button>
        <button
          className={`shift-exchange__tab ${activeTab === 'requests' ? 'active' : ''}`}
          onClick={() => setActiveTab('requests')}
        >
          📋 Запросы ({exchangeRequests.filter(r => r.status === 'pending').length})
        </button>
      </div>

      {renderContent()}

      {/* Exchange Modal */}
      {selectedShift && (
        <div className="shift-exchange__modal">
          <div className="shift-exchange__modal-content">
            <div className="shift-exchange__modal-header">
              <h3>Обмен смены</h3>
              <button
                className="shift-exchange__modal-close"
                onClick={() => setSelectedShift(null)}
              >
                ❌
              </button>
            </div>
            
            <div className="shift-exchange__modal-body">
              <div className="shift-exchange__selected-shift">
                <h4>Ваша смена:</h4>
                {renderShiftCard(selectedShift, false)}
              </div>
              
              <div className="shift-exchange__available-targets">
                <h4>Выберите смену для обмена:</h4>
                <div className="shift-exchange__target-list">
                  {availableShifts.map(shift => (
                    <div
                      key={shift.id}
                      className={`shift-exchange__target-shift ${
                        targetShift?.id === shift.id ? 'selected' : ''
                      }`}
                      onClick={() => setTargetShift(shift)}
                    >
                      {renderShiftCard(shift, false)}
                    </div>
                  ))}
                </div>
              </div>
            </div>
            
            <div className="shift-exchange__modal-actions">
              <button
                className="shift-exchange__action-button shift-exchange__action-button--cancel"
                onClick={() => {
                  setSelectedShift(null);
                  setTargetShift(null);
                }}
              >
                Отмена
              </button>
              <button
                className="shift-exchange__action-button shift-exchange__action-button--confirm"
                onClick={() => {
                  if (selectedShift && targetShift) {
                    requestShiftExchange(selectedShift, targetShift);
                    setSelectedShift(null);
                    setTargetShift(null);
                  }
                }}
                disabled={!targetShift}
              >
                Отправить запрос
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default MobileShiftExchange;