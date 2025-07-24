import React, { useState, useEffect } from 'react';

interface KPIMetric {
  id: string;
  name: string;
  value: number;
  target?: number;
  unit: string;
  status: 'excellent' | 'good' | 'warning' | 'critical';
  trend: 'up' | 'down' | 'stable';
  changePercent: number;
  lastUpdated: Date;
}

interface KPICardProps {
  metric: KPIMetric;
}

const KPICard: React.FC<KPICardProps> = ({ metric }) => {
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'excellent': return '#10b981';
      case 'good': return '#3b82f6';
      case 'warning': return '#f59e0b';
      case 'critical': return '#ef4444';
      default: return '#6b7280';
    }
  };

  const formatValue = (value: number, unit: string) => {
    if (unit === '%') return `${value.toFixed(1)}%`;
    if (unit === 'hours') return `${value.toFixed(1)}h`;
    return value.toFixed(1);
  };

  const getTrendIcon = (trend: string) => {
    switch (trend) {
