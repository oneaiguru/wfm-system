import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import EmployeeSearch from '../EmployeeSearch';

// Mock fetch
const mockFetch = vi.fn();
global.fetch = mockFetch;

const mockEmployees = [
  {
    id: 1,
    agent_code: 'AGT001',
    first_name: 'Анна',
    last_name: 'Петрова',
    email: 'anna@wfm.com',
    is_active: true
  },
  {
    id: 2,
    agent_code: 'AGT002',
    first_name: 'Иван',
    last_name: 'Сидоров',
    email: 'ivan@wfm.com',
    is_active: false
  }
];

describe('EmployeeSearch', () => {
  beforeEach(() => {
    mockFetch.mockClear();
  });

  it('renders search input and initial state', () => {
    render(<EmployeeSearch />);
    
    expect(screen.getByText('Поиск сотрудников')).toBeInTheDocument();
    expect(screen.getByPlaceholderText('Поиск по имени, email или коду агента...')).toBeInTheDocument();
    expect(screen.getByText('Начните поиск')).toBeInTheDocument();
    expect(screen.getByText('Введите минимум 2 символа для поиска сотрудников')).toBeInTheDocument();
  });

  it('shows filters when filter button is clicked', () => {
    render(<EmployeeSearch />);
    
    const filterButton = screen.getByText('Фильтры');
    fireEvent.click(filterButton);
    
    expect(screen.getByText('Статус')).toBeInTheDocument();
    expect(screen.getByText('Результатов на странице')).toBeInTheDocument();
  });

  it('performs search when query has 2+ characters', async () => {
    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: async () => mockEmployees
    });

    render(<EmployeeSearch />);
    
    const searchInput = screen.getByPlaceholderText('Поиск по имени, email или коду агента...');
    fireEvent.change(searchInput, { target: { value: 'Анна' } });

    await waitFor(() => {
      expect(mockFetch).toHaveBeenCalledWith(
        expect.stringContaining('/employees/search/query'),
        expect.objectContaining({
          headers: {
            'Content-Type': 'application/json',
          },
        })
      );
    });
  });

  it('displays search results correctly', async () => {
    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: async () => mockEmployees
    });

    render(<EmployeeSearch />);
    
    const searchInput = screen.getByPlaceholderText('Поиск по имени, email или коду агента...');
    fireEvent.change(searchInput, { target: { value: 'test' } });

    await waitFor(() => {
      expect(screen.getByText('Анна Петрова')).toBeInTheDocument();
      expect(screen.getByText('Иван Сидоров')).toBeInTheDocument();
      expect(screen.getByText('Код: AGT001')).toBeInTheDocument();
      expect(screen.getByText('Код: AGT002')).toBeInTheDocument();
    });
  });

  it('calls onEmployeeSelect when employee is clicked', async () => {
    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: async () => mockEmployees
    });

    const onEmployeeSelect = vi.fn();
    render(<EmployeeSearch onEmployeeSelect={onEmployeeSelect} />);
    
    const searchInput = screen.getByPlaceholderText('Поиск по имени, email или коду агента...');
    fireEvent.change(searchInput, { target: { value: 'test' } });

    await waitFor(() => {
      expect(screen.getByText('Анна Петрова')).toBeInTheDocument();
    });

    fireEvent.click(screen.getByText('Анна Петрова'));
    expect(onEmployeeSelect).toHaveBeenCalledWith(1);
  });

  it('handles search errors gracefully', async () => {
    mockFetch.mockRejectedValueOnce(new Error('Search failed'));

    render(<EmployeeSearch />);
    
    const searchInput = screen.getByPlaceholderText('Поиск по имени, email или коду агента...');
    fireEvent.change(searchInput, { target: { value: 'test' } });

    await waitFor(() => {
      expect(screen.getByText('Ошибка поиска')).toBeInTheDocument();
      expect(screen.getByText('Search failed')).toBeInTheDocument();
    });
  });

  it('shows correct status badges', async () => {
    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: async () => mockEmployees
    });

    render(<EmployeeSearch />);
    
    const searchInput = screen.getByPlaceholderText('Поиск по имени, email или коду агента...');
    fireEvent.change(searchInput, { target: { value: 'test' } });

    await waitFor(() => {
      expect(screen.getByText('Активен')).toBeInTheDocument();
      expect(screen.getByText('Неактивен')).toBeInTheDocument();
    });
  });
});