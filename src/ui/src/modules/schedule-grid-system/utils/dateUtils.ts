export interface DateInfo {
  day: number;
  dayName: string;
  isWeekend: boolean;
  isToday: boolean;
  fullDate: Date;
  dateString: string;
}

export const generateDateRange = (startDate: Date, endDate: Date): DateInfo[] => {
  const dates: DateInfo[] = [];
  const dayNames = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
  const today = new Date();
  
  const current = new Date(startDate);
  while (current <= endDate) {
    const dayOfWeek = current.getDay();
    
    dates.push({
      day: current.getDate(),
      dayName: dayNames[dayOfWeek],
      isWeekend: dayOfWeek === 0 || dayOfWeek === 6,
      isToday: current.toDateString() === today.toDateString(),
      fullDate: new Date(current),
      dateString: current.toISOString().split('T')[0]
    });
    
    current.setDate(current.getDate() + 1);
  }
  
  return dates;
};

export const formatTime = (time: string): string => {
  return time;
};

export const calculateShiftDuration = (startTime: string, endTime: string): number => {
  const start = new Date(`1970-01-01T${startTime}:00`);
  const end = new Date(`1970-01-01T${endTime}:00`);
  
  let diff = end.getTime() - start.getTime();
  
  // Handle overnight shifts
  if (diff < 0) {
    diff += 24 * 60 * 60 * 1000;
  }
  
  return Math.floor(diff / (1000 * 60)); // Return minutes
};

export const isValidTimeRange = (startTime: string, endTime: string): boolean => {
  const timeRegex = /^([01]?[0-9]|2[0-3]):[0-5][0-9]$/;
  return timeRegex.test(startTime) && timeRegex.test(endTime);
};
