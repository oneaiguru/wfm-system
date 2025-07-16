import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import EmployeeProfile from '../EmployeeProfile';

// Mock fetch for testing
global.fetch = jest.fn();

const mockEmployee = {
  id: 1,
  agent_code: "AGT001",
  first_name: "Анна",
  last_name: "Кузнецова",
  email: "anna.updated@wfm.com",
  employee_id: null,
  is_active: true,
  primary_group_id: null,
  primary_group_name: null,
  hire_date: null,
  time_zone: "Europe/Moscow",
  default_shift_start: null,
  default_shift_end: null
};

describe('EmployeeProfile Component', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders loading state initially', () => {
    (fetch as jest.Mock).mockImplementation(() => new Promise(() => {})); // Never resolves
    
    render(<EmployeeProfile employeeId="1" />);
    
    expect(screen.getByText(/Загрузка/i)).toBeInTheDocument();
  });

  it('renders employee data correctly', async () => {
    (fetch as jest.Mock).mockResolvedValueOnce({
      ok: true,
      json: async () => mockEmployee,
    });

    render(<EmployeeProfile employeeId="1" />);

    await waitFor(() => {
      expect(screen.getByText('Анна Кузнецова')).toBeInTheDocument();
      expect(screen.getByText('AGT001')).toBeInTheDocument();
      expect(screen.getByText('anna.updated@wfm.com')).toBeInTheDocument();
      expect(screen.getByText('Europe/Moscow')).toBeInTheDocument();
      expect(screen.getByText('Активен')).toBeInTheDocument();
    });
  });

  it('renders error state when employee not found', async () => {
    (fetch as jest.Mock).mockResolvedValueOnce({
      ok: false,
      status: 404,
      statusText: 'Not Found',
    });

    render(<EmployeeProfile employeeId="999" />);

    await waitFor(() => {
      expect(screen.getByText(/Ошибка загрузки/i)).toBeInTheDocument();
      expect(screen.getByText(/Employee not found/i)).toBeInTheDocument();
    });
  });

  it('calls onEdit when edit button is clicked', async () => {
    const mockOnEdit = jest.fn();
    
    (fetch as jest.Mock).mockResolvedValueOnce({
      ok: true,
      json: async () => mockEmployee,
    });

    render(<EmployeeProfile employeeId="1" onEdit={mockOnEdit} />);

    await waitFor(() => {
      expect(screen.getByText('Анна Кузнецова')).toBeInTheDocument();
    });

    const editButton = screen.getByText('Редактировать');
    editButton.click();

    expect(mockOnEdit).toHaveBeenCalledTimes(1);
  });

  it('formats dates in Russian locale', async () => {
    const employeeWithDate = {
      ...mockEmployee,
      hire_date: "2023-01-15T00:00:00Z"
    };

    (fetch as jest.Mock).mockResolvedValueOnce({
      ok: true,
      json: async () => employeeWithDate,
    });

    render(<EmployeeProfile employeeId="1" />);

    await waitFor(() => {
      expect(screen.getByText(/15 января 2023/i)).toBeInTheDocument();
    });
  });

  it('handles network errors gracefully', async () => {
    (fetch as jest.Mock).mockRejectedValueOnce(new Error('Network error'));

    render(<EmployeeProfile employeeId="1" />);

    await waitFor(() => {
      expect(screen.getByText(/Ошибка загрузки/i)).toBeInTheDocument();
      expect(screen.getByText(/Network error/i)).toBeInTheDocument();
    });
  });
});