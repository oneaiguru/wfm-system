/**
 * Test file for Spec22MultiSiteManagement with real API integration
 * Tests the component's integration with realSiteService
 */

import React from 'react';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import Spec22MultiSiteManagement from './Spec22MultiSiteManagement';
import { realSiteService } from '../../../services/realSiteService';

// Mock the real site service
jest.mock('../../../services/realSiteService', () => ({
  realSiteService: {
    getSiteHierarchy: jest.fn(),
    getEmployeeAssignments: jest.fn(),
    getSitePerformance: jest.fn(),
    healthCheck: jest.fn(),
  }
}));

const mockRealSiteService = realSiteService as jest.Mocked<typeof realSiteService>;

describe('Spec22MultiSiteManagement Real API Integration', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    
    // Setup default successful responses
    mockRealSiteService.getSiteHierarchy.mockResolvedValue({
      sites: [
        {
          id: 'HQ',
          siteCode: 'HQ',
          siteName: 'Corporate Headquarters',
          siteNameRu: 'Корпоративная штаб-квартира',
          level: 'corporate',
          timezone: 'Europe/Moscow',
          address: 'Moscow, Russia',
          coordinates: { latitude: 55.7558, longitude: 37.6176 },
          status: 'active',
          capacity: { current: 250, maximum: 300 },
          workingHours: { start: '09:00', end: '18:00' },
          contactInfo: { phone: '+7 495 123-45-67', email: 'hq@company.ru' },
          settings: { language: 'ru', currency: 'RUB', vacationDays: 28, overtimePolicy: 'Standard' },
          performance: { serviceLevel: 94.5, productivity: 87.3, costPerHour: 2850, employeeCount: 250 },
          lastUpdated: '2025-07-23T14:30:00Z'
        },
        {
          id: 'RGN-001',
          siteCode: 'RGN-001',
          siteName: 'Regional Office',
          siteNameRu: 'Региональный офис',
          parentId: 'HQ',
          level: 'regional',
          timezone: 'Europe/Moscow',
          address: 'St. Petersburg, Russia',
          coordinates: { latitude: 59.9311, longitude: 30.3609 },
          status: 'active',
          capacity: { current: 120, maximum: 150 },
          workingHours: { start: '08:30', end: '17:30' },
          contactInfo: { phone: '+7 812 123-45-67', email: 'spb@company.ru' },
          settings: { language: 'ru', currency: 'RUB', vacationDays: 30, overtimePolicy: 'Regional+' },
          performance: { serviceLevel: 91.5, productivity: 89.1, costPerHour: 1640, employeeCount: 120 },
          distanceToParent: 635,
          lastUpdated: '2025-07-23T14:25:00Z'
        }
      ],
      totalSites: 2,
      hierarchyLevels: 2,
      timezoneCoverage: ['Europe/Moscow'],
      geographicSpan: {
        min_latitude: 55.7558,
        max_latitude: 59.9311,
        min_longitude: 30.3609,
        max_longitude: 37.6176,
        span_km: 635
      }
    });

    mockRealSiteService.getEmployeeAssignments.mockResolvedValue([]);
    mockRealSiteService.getSitePerformance.mockResolvedValue([]);
  });

  test('renders loading state initially', () => {
    render(<Spec22MultiSiteManagement />);
    expect(screen.getByText('Загрузка данных о площадках...')).toBeInTheDocument();
  });

  test('loads and displays site hierarchy from real API', async () => {
    render(<Spec22MultiSiteManagement />);
    
    // Wait for loading to complete
    await waitFor(() => {
      expect(screen.queryByText('Загрузка данных о площадках...')).not.toBeInTheDocument();
    });

    // Verify API was called
    expect(mockRealSiteService.getSiteHierarchy).toHaveBeenCalledTimes(1);
    expect(mockRealSiteService.getEmployeeAssignments).toHaveBeenCalledTimes(1);
    expect(mockRealSiteService.getSitePerformance).toHaveBeenCalledTimes(1);

    // Verify site data is displayed
    expect(screen.getByText('Corporate Headquarters')).toBeInTheDocument();
    expect(screen.getByText('Regional Office')).toBeInTheDocument();
    expect(screen.getByText('(HQ)')).toBeInTheDocument();
    expect(screen.getByText('(RGN-001)')).toBeInTheDocument();
  });

  test('displays error state when API call fails', async () => {
    mockRealSiteService.getSiteHierarchy.mockRejectedValue(new Error('API Error'));

    render(<Spec22MultiSiteManagement />);
    
    // Wait for error state
    await waitFor(() => {
      expect(screen.getByText('Ошибка загрузки данных')).toBeInTheDocument();
    });

    expect(screen.getByText('Failed to load site data. Please check your connection and try again.')).toBeInTheDocument();
    expect(screen.getByText('Попробовать снова')).toBeInTheDocument();
  });

  test('refresh button calls API again', async () => {
    render(<Spec22MultiSiteManagement />);
    
    // Wait for initial load
    await waitFor(() => {
      expect(screen.queryByText('Загрузка данных о площадках...')).not.toBeInTheDocument();
    });

    // Click refresh button
    const refreshButton = screen.getByText('Обновить данные');
    fireEvent.click(refreshButton);

    // Verify API called again
    await waitFor(() => {
      expect(mockRealSiteService.getSiteHierarchy).toHaveBeenCalledTimes(2);
    });
  });

  test('handles site hierarchy with different levels', async () => {
    // Add a site-level location
    const hierarchyWithSite = await mockRealSiteService.getSiteHierarchy();
    hierarchyWithSite.sites.push({
      id: 'SITE-001',
      siteCode: 'SITE-001',
      siteName: 'Service Center',
      siteNameRu: 'Сервисный центр',
      parentId: 'RGN-001',
      level: 'site',
      timezone: 'Europe/Moscow',
      address: 'Moscow, Tverskaya 15',
      coordinates: { latitude: 55.7617, longitude: 37.6090 },
      status: 'active',
      capacity: { current: 45, maximum: 50 },
      workingHours: { start: '08:30', end: '17:30' },
      contactInfo: { phone: '+7 495 987-65-43', email: 'moscow@company.ru' },
      settings: { language: 'ru', currency: 'RUB', vacationDays: 30, overtimePolicy: 'Site Custom' },
      performance: { serviceLevel: 89.2, productivity: 85.7, costPerHour: 2350, employeeCount: 45 },
      distanceToParent: 635,
      lastUpdated: '2025-07-23T14:20:00Z'
    });

    mockRealSiteService.getSiteHierarchy.mockResolvedValue(hierarchyWithSite);

    render(<Spec22MultiSiteManagement />);
    
    await waitFor(() => {
      expect(screen.queryByText('Загрузка данных о площадках...')).not.toBeInTheDocument();
    });

    // Verify all sites are displayed
    expect(screen.getByText('Corporate Headquarters')).toBeInTheDocument();
    expect(screen.getByText('Regional Office')).toBeInTheDocument();
    expect(screen.getByText('Service Center')).toBeInTheDocument();
  });

  test('site selection works with real data', async () => {
    render(<Spec22MultiSiteManagement />);
    
    await waitFor(() => {
      expect(screen.queryByText('Загрузка данных о площадках...')).not.toBeInTheDocument();
    });

    // Click on a site to select it
    const siteElement = screen.getByText('Corporate Headquarters');
    fireEvent.click(siteElement.closest('div')!);

    // Verify site details are displayed
    await waitFor(() => {
      expect(screen.getByText('Основная информация')).toBeInTheDocument();
      expect(screen.getByText('Производительность')).toBeInTheDocument();
      expect(screen.getByText('Контакты')).toBeInTheDocument();
    });
  });

  test('tab switching works with real data', async () => {
    render(<Spec22MultiSiteManagement />);
    
    await waitFor(() => {
      expect(screen.queryByText('Загрузка данных о площадках...')).not.toBeInTheDocument();
    });

    // Click on Employee Assignments tab
    const assignmentsTab = screen.getByText('Назначения сотрудников');
    fireEvent.click(assignmentsTab);

    // Verify tab switched (assignments tab should be active)
    expect(assignmentsTab.closest('button')).toHaveClass('text-blue-600');

    // Click on Performance tab
    const performanceTab = screen.getByText('Производительность площадок');
    fireEvent.click(performanceTab);

    // Verify tab switched
    expect(performanceTab.closest('button')).toHaveClass('text-blue-600');
  });

  test('filtering works with real site data', async () => {
    render(<Spec22MultiSiteManagement />);
    
    await waitFor(() => {
      expect(screen.queryByText('Загрузка данных о площадках...')).not.toBeInTheDocument();
    });

    // Test search filter
    const searchInput = screen.getByPlaceholderText('Поиск площадок...');
    fireEvent.change(searchInput, { target: { value: 'Corporate' } });

    // Should show only Corporate Headquarters
    expect(screen.getByText('Corporate Headquarters')).toBeInTheDocument();
    expect(screen.queryByText('Regional Office')).not.toBeInTheDocument();

    // Clear search
    fireEvent.change(searchInput, { target: { value: '' } });

    // Both should be visible again
    expect(screen.getByText('Corporate Headquarters')).toBeInTheDocument();
    expect(screen.getByText('Regional Office')).toBeInTheDocument();
  });

  test('handles API timeout gracefully', async () => {
    // Mock timeout error
    mockRealSiteService.getSiteHierarchy.mockRejectedValue(new Error('Request timeout'));

    render(<Spec22MultiSiteManagement />);
    
    await waitFor(() => {
      expect(screen.getByText('Ошибка загрузки данных')).toBeInTheDocument();
    });

    // Should show error message
    expect(screen.getByText('Failed to load site data. Please check your connection and try again.')).toBeInTheDocument();
    
    // Should have retry button
    const retryButton = screen.getByText('Попробовать снова');
    expect(retryButton).toBeInTheDocument();
    
    // Test retry functionality
    mockRealSiteService.getSiteHierarchy.mockClear();
    mockRealSiteService.getSiteHierarchy.mockResolvedValue({
      sites: [],
      totalSites: 0,
      hierarchyLevels: 0,
      timezoneCoverage: [],
      geographicSpan: null
    });

    fireEvent.click(retryButton);
    
    await waitFor(() => {
      expect(mockRealSiteService.getSiteHierarchy).toHaveBeenCalledTimes(1);
    });
  });
});