/**
 * Real Site Management Service
 * Integrates with INTEGRATION-OPUS verified endpoint GET /api/v1/sites/hierarchy
 * For Spec22MultiSiteManagement component
 */

import { apiClient } from './apiClient';

// API Response Types (from INTEGRATION-OPUS endpoint)
interface APISiteHierarchy {
  site_id: string;
  site_code: string;
  site_name: string;
  parent_site_id?: string;
  timezone: string;
  address: string;
  geographic_coordinates: {
    latitude: number;
    longitude: number;
  };
  configuration_inheritance: any;
  status: string;
}

interface APISiteHierarchyResponse {
  sites: APISiteHierarchy[];
  total_sites: number;
  hierarchy_levels: number;
  timezone_coverage: string[];
  geographic_span: {
    min_latitude: number;
    max_latitude: number;
    min_longitude: number;
    max_longitude: number;
    span_km: number;
  };
}

// Component Interface Types (from Spec22MultiSiteManagement.tsx)
export interface Spec22SiteInfo {
  id: string;
  siteCode: string;
  siteName: string;
  siteNameRu?: string;
  siteNameEn?: string;
  parentId?: string;
  level: 'corporate' | 'regional' | 'site' | 'department';
  timezone: string;
  address: string;
  coordinates?: {
    latitude: number;
    longitude: number;
  };
  status: 'active' | 'inactive' | 'maintenance';
  capacity: {
    current: number;
    maximum: number;
  };
  workingHours: {
    start: string;
    end: string;
  };
  contactInfo: {
    phone?: string;
    email?: string;
    manager?: string;
  };
  settings: {
    language: 'ru' | 'en';
    currency: 'RUB' | 'USD' | 'EUR';
    vacationDays: number;
    overtimePolicy: string;
  };
  performance: {
    serviceLevel: number;
    productivity: number;
    costPerHour: number;
    employeeCount: number;
  };
  distanceToParent?: number;
  lastUpdated: string;
}

export interface Spec22EmployeeAssignment {
  id: string;
  employeeId: string;
  employeeName: string;
  primarySiteId: string;
  primarySiteName: string;
  secondarySites: Array<{
    siteId: string;
    siteName: string;
    assignmentType: 'backup' | 'specialist' | 'temporary' | 'remote';
    schedule: string;
  }>;
  status: 'active' | 'transferred' | 'pending';
  effectiveDates: {
    start: string;
    end?: string;
  };
  travelAllowance?: number;
  skillsRequired: string[];
}

export interface Spec22SitePerformance {
  siteId: string;
  siteName: string;
  metrics: {
    serviceLevel: number;
    productivity: number;
    customerSatisfaction: number;
    operationalCost: number;
    employeeCount: number;
    utilizationRate: number;
  };
  trends: {
    serviceLevel: 'up' | 'down' | 'stable';
    productivity: 'up' | 'down' | 'stable';
    cost: 'up' | 'down' | 'stable';
  };
  alerts: Array<{
    type: 'warning' | 'critical' | 'info';
    message: string;
    recommendation?: string;
  }>;
  lastUpdated: string;
}

// Service Class
class RealSiteService {
  private readonly baseURL = '/api/v1';

  /**
   * Get site hierarchy from real endpoint
   */
  async getSiteHierarchy(): Promise<{
    sites: Spec22SiteInfo[];
    totalSites: number;
    hierarchyLevels: number;
    timezoneCoverage: string[];
    geographicSpan: any;
  }> {
    try {
      console.log('🔄 RealSiteService: Fetching site hierarchy...');
      
      const response = await apiClient.get<APISiteHierarchyResponse>(
        `${this.baseURL}/sites/hierarchy`
      );

      console.log('✅ RealSiteService: Site hierarchy received:', {
        sitesCount: response.data.sites.length,
        totalSites: response.data.total_sites,
        timezones: response.data.timezone_coverage?.length || 0
      });

      // Map API response to component interface
      const mappedSites = response.data.sites.map(this.mapAPIToComponentSite);

      return {
        sites: mappedSites,
        totalSites: response.data.total_sites,
        hierarchyLevels: response.data.hierarchy_levels,
        timezoneCoverage: response.data.timezone_coverage || [],
        geographicSpan: response.data.geographic_span
      };

    } catch (error) {
      console.error('❌ RealSiteService: Error fetching site hierarchy:', error);
      
      // Return fallback structure for development
      return {
        sites: [],
        totalSites: 0,
        hierarchyLevels: 0,
        timezoneCoverage: [],
        geographicSpan: null
      };
    }
  }

  /**
   * Get cross-site employee assignments
   */
  async getEmployeeAssignments(siteId?: string): Promise<Spec22EmployeeAssignment[]> {
    try {
      console.log('🔄 RealSiteService: Fetching employee assignments...');
      
      const params = siteId ? `?site_id=${siteId}` : '';
      const response = await apiClient.get(
        `${this.baseURL}/employees/cross-site-assignments${params}`
      );

      console.log('✅ RealSiteService: Employee assignments received:', {
        assignmentsCount: response.data.assignments?.length || 0
      });

      // Map API response to component format
      return response.data.assignments?.map(this.mapAPIToEmployeeAssignment) || [];

    } catch (error) {
      console.error('❌ RealSiteService: Error fetching employee assignments:', error);
      return [];
    }
  }

  /**
   * Get site performance comparison
   */
  async getSitePerformance(dateFrom: string, dateTo: string): Promise<Spec22SitePerformance[]> {
    try {
      console.log('🔄 RealSiteService: Fetching site performance...');
      
      const response = await apiClient.get(
        `${this.baseURL}/sites/performance/comparison?date_from=${dateFrom}&date_to=${dateTo}`
      );

      console.log('✅ RealSiteService: Site performance received:', {
        sitesCount: response.data.site_performance?.length || 0
      });

      // Map API response to component format
      return response.data.site_performance?.map(this.mapAPIToSitePerformance) || [];

    } catch (error) {
      console.error('❌ RealSiteService: Error fetching site performance:', error);
      return [];
    }
  }

  /**
   * Create new site
   */
  async createSite(siteData: Partial<Spec22SiteInfo>): Promise<{ success: boolean; siteId?: string; message?: string }> {
    try {
      console.log('🔄 RealSiteService: Creating new site...');
      
      const apiSiteData = this.mapComponentToAPISite(siteData);
      const response = await apiClient.post(
        `${this.baseURL}/sites/create`,
        apiSiteData
      );

      console.log('✅ RealSiteService: Site created successfully:', response.data.site_id);

      return {
        success: response.data.success,
        siteId: response.data.site_id,
        message: response.data.message
      };

    } catch (error) {
      console.error('❌ RealSiteService: Error creating site:', error);
      return {
        success: false,
        message: 'Failed to create site'
      };
    }
  }

  /**
   * Map API site data to component interface
   */
  private mapAPIToComponentSite = (apiSite: APISiteHierarchy): Spec22SiteInfo => {
    // Determine site level based on hierarchy and naming conventions
    const level = this.determineSiteLevel(apiSite);
    
    // Extract configuration data
    const config = apiSite.configuration_inheritance || {};
    
    return {
      id: apiSite.site_id,
      siteCode: apiSite.site_code,
      siteName: apiSite.site_name,
      siteNameRu: apiSite.site_name, // Default to site_name, could be enhanced
      siteNameEn: apiSite.site_name,
      parentId: apiSite.parent_site_id || undefined,
      level,
      timezone: apiSite.timezone,
      address: apiSite.address,
      coordinates: {
        latitude: apiSite.geographic_coordinates.latitude,
        longitude: apiSite.geographic_coordinates.longitude
      },
      status: this.mapAPIStatus(apiSite.status),
      capacity: {
        current: config.occupancy || 0,
        maximum: config.capacity || 100
      },
      workingHours: {
        start: config.business_hours?.start || '09:00',
        end: config.business_hours?.end || '18:00'
      },
      contactInfo: {
        phone: config.contact_phone,
        email: config.contact_email,
        manager: config.manager_name
      },
      settings: {
        language: 'ru', // Default to Russian
        currency: 'RUB',
        vacationDays: config.vacation_days || 28,
        overtimePolicy: config.overtime_policy || 'Standard'
      },
      performance: {
        serviceLevel: config.service_level || 90,
        productivity: config.productivity || 85,
        costPerHour: config.cost_per_hour || 2000,
        employeeCount: config.employee_count || 25
      },
      distanceToParent: config.distance_to_parent,
      lastUpdated: new Date().toISOString()
    };
  };

  /**
   * Map API employee assignment to component interface
   */
  private mapAPIToEmployeeAssignment = (apiAssignment: any): Spec22EmployeeAssignment => {
    return {
      id: `assign-${apiAssignment.employee_id}`,
      employeeId: apiAssignment.employee_id.toString(),
      employeeName: apiAssignment.employee_name,
      primarySiteId: apiAssignment.primary_site,
      primarySiteName: apiAssignment.primary_site, // Would need site lookup
      secondarySites: apiAssignment.secondary_sites?.map((site: string) => ({
        siteId: site,
        siteName: site, // Would need site lookup
        assignmentType: 'specialist' as const,
        schedule: apiAssignment.effective_dates?.pattern || 'Full-time'
      })) || [],
      status: 'active',
      effectiveDates: {
        start: apiAssignment.effective_dates?.start_date || new Date().toISOString(),
        end: apiAssignment.effective_dates?.end_date
      },
      travelAllowance: apiAssignment.travel_allowance,
      skillsRequired: ['General'] // Would need to be expanded
    };
  };

  /**
   * Map API site performance to component interface
   */
  private mapAPIToSitePerformance = (apiPerf: any): Spec22SitePerformance => {
    return {
      siteId: apiPerf.site_id,
      siteName: apiPerf.site_name,
      metrics: {
        serviceLevel: apiPerf.service_level,
        productivity: apiPerf.productivity_score,
        customerSatisfaction: apiPerf.customer_satisfaction,
        operationalCost: apiPerf.operational_cost,
        employeeCount: apiPerf.agent_count,
        utilizationRate: 85 // Default value
      },
      trends: {
        serviceLevel: apiPerf.performance_gap ? 'down' : 'stable',
        productivity: 'stable',
        cost: 'stable'
      },
      alerts: apiPerf.recommendations?.map((rec: string) => ({
        type: 'info' as const,
        message: rec,
        recommendation: rec
      })) || [],
      lastUpdated: new Date().toISOString()
    };
  };

  /**
   * Map component site data to API format
   */
  private mapComponentToAPISite = (componentSite: Partial<Spec22SiteInfo>): Partial<APISiteHierarchy> => {
    return {
      site_id: componentSite.id || '',
      site_code: componentSite.siteCode || '',
      site_name: componentSite.siteName || '',
      parent_site_id: componentSite.parentId,
      timezone: componentSite.timezone || 'Europe/Moscow',
      address: componentSite.address || '',
      geographic_coordinates: {
        latitude: componentSite.coordinates?.latitude || 0,
        longitude: componentSite.coordinates?.longitude || 0
      },
      configuration_inheritance: {
        business_hours: componentSite.workingHours,
        capacity: componentSite.capacity?.maximum,
        occupancy: componentSite.capacity?.current,
        vacation_days: componentSite.settings?.vacationDays,
        overtime_policy: componentSite.settings?.overtimePolicy
      },
      status: componentSite.status || 'active'
    };
  };

  /**
   * Determine site level from API data
   */
  private determineSiteLevel(apiSite: APISiteHierarchy): 'corporate' | 'regional' | 'site' | 'department' {
    const config = apiSite.configuration_inheritance || {};
    
    // Use site_type from configuration if available
    if (config.site_type) {
      switch (config.site_type.toLowerCase()) {
        case 'headquarters':
        case 'corporate':
          return 'corporate';
        case 'regional':
        case 'region':
          return 'regional';
        case 'department':
        case 'dept':
          return 'department';
        default:
          return 'site';
      }
    }
    
    // Fallback: determine by parent relationship
    if (!apiSite.parent_site_id) {
      return 'corporate';
    }
    
    // Check site naming patterns
    const name = apiSite.site_name.toLowerCase();
    if (name.includes('headquarters') || name.includes('head office')) {
      return 'corporate';
    }
    if (name.includes('region') || name.includes('regional')) {
      return 'regional';
    }
    if (name.includes('department') || name.includes('dept')) {
      return 'department';
    }
    
    return 'site';
  }

  /**
   * Map API status to component status
   */
  private mapAPIStatus(apiStatus: string): 'active' | 'inactive' | 'maintenance' {
    switch (apiStatus.toLowerCase()) {
      case 'active':
        return 'active';
      case 'inactive':
      case 'disabled':
        return 'inactive';
      case 'maintenance':
      case 'under_maintenance':
        return 'maintenance';
      default:
        return 'active';
    }
  }

  /**
   * Health check for site service
   */
  async healthCheck(): Promise<{ status: string; endpoint: string }> {
    try {
      const response = await apiClient.get('/api/v1/health');
      return {
        status: 'healthy',
        endpoint: `${this.baseURL}/sites/hierarchy`
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        endpoint: `${this.baseURL}/sites/hierarchy`
      };
    }
  }
}

// Export singleton instance
export const realSiteService = new RealSiteService();
export default realSiteService;