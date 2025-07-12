import { useState, useCallback } from 'react';
import { Shift } from '../types';

export const useShiftManagement = (initialShifts: Map<string, Shift>) => {
  const [shifts, setShifts] = useState<Map<string, Shift>>(initialShifts);

  const getShiftForCell = useCallback((employeeId: string, dateIndex: number): Shift | null => {
    const cellKey = `${employeeId}-${dateIndex}`;
    return shifts.get(cellKey) || null;
  }, [shifts]);

  const addShift = useCallback((employeeId: string, dateIndex: number, shift: Shift): boolean => {
    const cellKey = `${employeeId}-${dateIndex}`;
    
    if (shifts.has(cellKey)) {
      return false; // Cell already occupied
    }

    setShifts(prev => {
      const newShifts = new Map(prev);
      newShifts.set(cellKey, shift);
      return newShifts;
    });

    return true;
  }, [shifts]);

  const removeShift = useCallback((employeeId: string, dateIndex: number): boolean => {
    const cellKey = `${employeeId}-${dateIndex}`;
    
    if (!shifts.has(cellKey)) {
      return false; // No shift to remove
    }

    setShifts(prev => {
      const newShifts = new Map(prev);
      newShifts.delete(cellKey);
      return newShifts;
    });

    return true;
  }, [shifts]);

  const moveShift = useCallback((shift: Shift, targetEmployeeId: string, targetDate: string): boolean => {
    // Find source date index
    const sourceDateIndex = shift.date.split('-')[2];
    const targetDateIndex = targetDate.split('-')[2];
    
    const sourceKey = `${shift.employeeId}-${parseInt(sourceDateIndex) - 1}`;
    const targetKey = `${targetEmployeeId}-${parseInt(targetDateIndex) - 1}`;

    // Check if target is occupied
    if (shifts.has(targetKey) && sourceKey !== targetKey) {
      return false;
    }

    setShifts(prev => {
      const newShifts = new Map(prev);
      
      // Remove from source
      newShifts.delete(sourceKey);
      
      // Add to target with updated properties
      const movedShift: Shift = {
        ...shift,
        employeeId: targetEmployeeId,
        date: targetDate,
      };
      newShifts.set(targetKey, movedShift);
      
      return newShifts;
    });

    return true;
  }, [shifts]);

  const updateShift = useCallback((employeeId: string, dateIndex: number, updates: Partial<Shift>): boolean => {
    const cellKey = `${employeeId}-${dateIndex}`;
    const existingShift = shifts.get(cellKey);
    
    if (!existingShift) {
      return false;
    }

    setShifts(prev => {
      const newShifts = new Map(prev);
      newShifts.set(cellKey, { ...existingShift, ...updates });
      return newShifts;
    });

    return true;
  }, [shifts]);

  const bulkAddShifts = useCallback((shiftMap: Map<string, Shift>) => {
    setShifts(prev => {
      const newShifts = new Map(prev);
      shiftMap.forEach((shift, key) => {
        if (!newShifts.has(key)) {
          newShifts.set(key, shift);
        }
      });
      return newShifts;
    });
  }, []);

  const bulkRemoveShifts = useCallback((cellKeys: string[]) => {
    setShifts(prev => {
      const newShifts = new Map(prev);
      cellKeys.forEach(key => {
        newShifts.delete(key);
      });
      return newShifts;
    });
  }, []);

  const getShiftStats = useCallback(() => {
    let totalShifts = shifts.size;
    let dayShifts = 0;
    let nightShifts = 0;
    let overtimeShifts = 0;
    let totalHours = 0;

    shifts.forEach(shift => {
      switch (shift.shiftTypeId) {
        case 'day':
          dayShifts++;
          break;
        case 'night':
          nightShifts++;
          break;
        case 'overtime':
          overtimeShifts++;
          break;
      }
      totalHours += shift.duration / 60;
    });

    return {
      totalShifts,
      dayShifts,
      nightShifts,
      overtimeShifts,
      totalHours
    };
  }, [shifts]);

  return {
    shifts,
    getShiftForCell,
    addShift,
    removeShift,
    moveShift,
    updateShift,
    bulkAddShifts,
    bulkRemoveShifts,
    getShiftStats
  };
};