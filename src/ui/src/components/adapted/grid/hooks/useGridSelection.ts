import { useState, useCallback, useEffect } from 'react';

export const useGridSelection = (onSelectionChange?: (selectedCells: Set<string>) => void) => {
  const [selectedCells, setSelectedCells] = useState<Set<string>>(new Set());
  const [isSelecting, setIsSelecting] = useState(false);
  const [selectionStart, setSelectionStart] = useState<string | null>(null);

  const handleCellClick = useCallback((employeeId: string, dateIndex: number, isShiftKey: boolean = false) => {
    const cellId = `${employeeId}-${dateIndex}`;
    
    setSelectedCells(prev => {
      const newSelected = new Set(prev);
      
      if (isShiftKey && selectionStart) {
        // Multi-select with shift key
        const [startEmpId, startDateStr] = selectionStart.split('-');
        const startDate = parseInt(startDateStr);
        const endDate = dateIndex;
        
        // Select range
        const minDate = Math.min(startDate, endDate);
        const maxDate = Math.max(startDate, endDate);
        
        for (let d = minDate; d <= maxDate; d++) {
          newSelected.add(`${employeeId}-${d}`);
        }
      } else {
        // Single select/deselect
        if (newSelected.has(cellId)) {
          newSelected.delete(cellId);
        } else {
          newSelected.add(cellId);
        }
        setSelectionStart(cellId);
      }
      
      return newSelected;
    });
  }, [selectionStart]);

  const clearSelection = useCallback(() => {
    setSelectedCells(new Set());
    setSelectionStart(null);
  }, []);

  const selectAll = useCallback((employeeIds: string[], dateCount: number) => {
    const allCells = new Set<string>();
    employeeIds.forEach(empId => {
      for (let i = 0; i < dateCount; i++) {
        allCells.add(`${empId}-${i}`);
      }
    });
    setSelectedCells(allCells);
  }, []);

  const selectRow = useCallback((employeeId: string, dateCount: number) => {
    const rowCells = new Set<string>();
    for (let i = 0; i < dateCount; i++) {
      rowCells.add(`${employeeId}-${i}`);
    }
    setSelectedCells(rowCells);
  }, []);

  const selectColumn = useCallback((dateIndex: number, employeeIds: string[]) => {
    const columnCells = new Set<string>();
    employeeIds.forEach(empId => {
      columnCells.add(`${empId}-${dateIndex}`);
    });
    setSelectedCells(columnCells);
  }, []);

  // Notify parent of selection changes
  useEffect(() => {
    onSelectionChange?.(selectedCells);
  }, [selectedCells, onSelectionChange]);

  return {
    selectedCells,
    isSelecting,
    handleCellClick,
    clearSelection,
    selectAll,
    selectRow,
    selectColumn
  };
};