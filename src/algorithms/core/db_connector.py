#!/usr/bin/env python3
"""
Database connector for real-time workforce monitoring
Connects to wfm_enterprise database for live queue and agent data
"""

import asyncio
import asyncpg
import logging
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass
import os

logger = logging.getLogger(__name__)

@dataclass
class DatabaseConfig:
    """Database connection configuration"""
    host: str = "localhost"
    port: int = 5432
    database: str = "wfm_enterprise"
    user: str = "postgres"
    password: str = ""

class WFMDatabaseConnector:
    """
    High-performance database connector for real-time workforce monitoring
    Optimized for Mobile Workforce Scheduler pattern implementation
    """
    
    def __init__(self, config: DatabaseConfig = None):
        self.config = config or DatabaseConfig()
        self.pool = None
        self.connected = False
        
    async def connect(self):
        """Establish connection pool to database"""
        try:
            self.pool = await asyncpg.create_pool(
                host=self.config.host,
                port=self.config.port,
                database=self.config.database,
                user=self.config.user,
                password=self.config.password,
                min_size=5,
                max_size=20,
                command_timeout=10
            )
            self.connected = True
            logger.info("Connected to WFM Enterprise database")
        except Exception as e:
            logger.error(f"Failed to connect to database: {e}")
            raise
    
    async def disconnect(self):
        """Close connection pool"""
        if self.pool:
            await self.pool.close()
            self.connected = False
            logger.info("Disconnected from database")
    
    async def get_real_time_queue_metrics(self, service_id: int = None) -> List[Dict]:
        """
        Get real-time queue metrics for active services
        Returns live data from queue_current_metrics table
        """
        if not self.connected:
            await self.connect()
            
        query = """
        SELECT 
            service_id,
            calls_waiting,
            longest_wait_time,
            agents_available,
            agents_busy,
            agents_not_ready,
            current_service_level,
            calls_handled_last_15min,
            avg_wait_time_last_15min,
            last_updated
        FROM queue_current_metrics
        """
        
        params = []
        if service_id:
            query += " WHERE service_id = $1"
            params = [service_id]
        
        query += " ORDER BY service_id"
        
        async with self.pool.acquire() as conn:
            rows = await conn.fetch(query, *params)
            return [dict(row) for row in rows]
    
    async def get_service_level_data(self, service_name: str = None, 
                                   hours_back: int = 1) -> List[Dict]:
        """
        Get service level monitoring data
        Returns historical and current service level performance
        """
        if not self.connected:
            await self.connect()
            
        # Use timedelta for proper interval handling
        from datetime import timedelta
        
        time_threshold = datetime.now() - timedelta(hours=hours_back)
        
        if service_name:
            query = """
            SELECT 
                service_name,
                current_service_level,
                target_service_level,
                calls_offered,
                calls_answered,
                calls_abandoned,
                average_wait_time,
                calculation_time
            FROM service_level_monitoring
            WHERE calculation_time >= $1
            AND service_name = $2
            ORDER BY calculation_time DESC
            """
            params = [time_threshold, service_name]
        else:
            query = """
            SELECT 
                service_name,
                current_service_level,
                target_service_level,
                calls_offered,
                calls_answered,
                calls_abandoned,
                average_wait_time,
                calculation_time
            FROM service_level_monitoring
            WHERE calculation_time >= $1
            ORDER BY calculation_time DESC
            """
            params = [time_threshold]
        
        async with self.pool.acquire() as conn:
            rows = await conn.fetch(query, *params)
            return [dict(row) for row in rows]
    
    async def get_agent_availability(self) -> Dict[str, int]:
        """
        Get current agent availability across all statuses
        Returns real-time agent status counts
        """
        if not self.connected:
            await self.connect()
            
        query = """
        SELECT 
            status,
            COUNT(*) as agent_count,
            SUM(CASE WHEN contact_availability = true THEN 1 ELSE 0 END) as available_for_contact
        FROM agent_real_time_monitoring
        WHERE last_updated >= NOW() - INTERVAL '5 minutes'
        GROUP BY status
        """
        
        async with self.pool.acquire() as conn:
            rows = await conn.fetch(query)
            
            result = {
                'total_agents': 0,
                'available': 0,
                'busy': 0,
                'break': 0,
                'unavailable': 0,
                'by_status': {}
            }
            
            for row in rows:
                status = row['status']
                count = row['agent_count']
                available_contact = row['available_for_contact']
                
                result['total_agents'] += count
                result['by_status'][status] = {
                    'count': count,
                    'available_for_contact': available_contact
                }
                
                # Categorize statuses
                if status in ['On schedule']:
                    result['available'] += available_contact
                elif status in ['In break', 'Lunch']:
                    result['break'] += count
                elif status in ['Late login', 'Absent', 'Wrong status']:
                    result['unavailable'] += count
                else:
                    result['busy'] += count
                    
            return result
    
    async def get_real_time_calls(self, queue_id: str = None, 
                                status: str = None) -> List[Dict]:
        """
        Get real-time call data
        Returns current call states and wait times
        """
        if not self.connected:
            await self.connect()
            
        query = """
        SELECT 
            call_id,
            call_type,
            queue_id,
            agent_id,
            status,
            priority,
            start_time,
            answer_time,
            wait_time,
            talk_time,
            EXTRACT(EPOCH FROM (NOW() - start_time)) as current_wait_seconds
        FROM realtime_calls
        WHERE last_updated >= NOW() - INTERVAL '1 hour'
        """
        
        params = []
        param_count = 0
        
        if queue_id:
            param_count += 1
            query += f" AND queue_id = ${param_count}"
            params.append(queue_id)
            
        if status:
            param_count += 1
            query += f" AND status = ${param_count}"
            params.append(status)
        
        query += " ORDER BY start_time ASC"
        
        async with self.pool.acquire() as conn:
            rows = await conn.fetch(query, *params)
            return [dict(row) for row in rows]
    
    async def get_staffing_gaps(self) -> List[Dict]:
        """
        Get current staffing gaps and urgency levels
        Returns staffing deficit information
        """
        if not self.connected:
            await self.connect()
            
        query = """
        SELECT 
            department_name,
            position_name,
            gap_count,
            urgency,
            days_open,
            service_level_impact,
            capacity_impact,
            budget_impact,
            monitored_at
        FROM staffing_gap_monitoring
        WHERE monitored_at >= NOW() - INTERVAL '24 hours'
        ORDER BY 
            CASE urgency 
                WHEN 'critical' THEN 1
                WHEN 'high' THEN 2
                WHEN 'medium' THEN 3
                ELSE 4
            END,
            gap_count DESC
        """
        
        async with self.pool.acquire() as conn:
            rows = await conn.fetch(query)
            return [dict(row) for row in rows]
    
    async def calculate_abandonment_rate(self, service_name: str = None, 
                                       minutes_back: int = 15) -> float:
        """
        Calculate real-time abandonment rate
        Uses service level monitoring data
        """
        if not self.connected:
            await self.connect()
            
        from datetime import timedelta
        time_threshold = datetime.now() - timedelta(minutes=minutes_back)
        
        if service_name:
            query = """
            SELECT 
                SUM(calls_offered) as total_offered,
                SUM(calls_abandoned) as total_abandoned
            FROM service_level_monitoring
            WHERE calculation_time >= $1
            AND service_name = $2
            """
            params = [time_threshold, service_name]
        else:
            query = """
            SELECT 
                SUM(calls_offered) as total_offered,
                SUM(calls_abandoned) as total_abandoned
            FROM service_level_monitoring
            WHERE calculation_time >= $1
            """
            params = [time_threshold]
        
        async with self.pool.acquire() as conn:
            row = await conn.fetchrow(query, *params)
            
            if row and row['total_offered'] and row['total_offered'] > 0:
                return float(row['total_abandoned']) / float(row['total_offered'])
            return 0.0
    
    async def get_average_handle_time(self, queue_id: str = None, 
                                    minutes_back: int = 60) -> float:
        """
        Calculate average handle time from completed calls
        Returns AHT in seconds
        """
        if not self.connected:
            await self.connect()
            
        from datetime import timedelta
        time_threshold = datetime.now() - timedelta(minutes=minutes_back)
        
        if queue_id:
            query = """
            SELECT AVG(talk_time) as avg_handle_time
            FROM realtime_calls
            WHERE status = 'completed'
            AND start_time >= $1
            AND talk_time > 0
            AND queue_id = $2
            """
            params = [time_threshold, queue_id]
        else:
            query = """
            SELECT AVG(talk_time) as avg_handle_time
            FROM realtime_calls
            WHERE status = 'completed'
            AND start_time >= $1
            AND talk_time > 0
            """
            params = [time_threshold]
        
        async with self.pool.acquire() as conn:
            row = await conn.fetchrow(query, *params)
            
            if row and row['avg_handle_time']:
                return float(row['avg_handle_time'])
            return 300.0  # Default 5 minutes if no data
    
    async def monitor_real_time_changes(self, callback, interval: int = 30):
        """
        Monitor database for real-time changes
        Calls callback function when significant changes detected
        """
        if not self.connected:
            await self.connect()
            
        last_update = {}
        
        while True:
            try:
                # Check for queue metrics changes
                current_metrics = await self.get_real_time_queue_metrics()
                
                for metric in current_metrics:
                    service_id = metric['service_id']
                    key = f"queue_{service_id}"
                    
                    if key not in last_update:
                        last_update[key] = metric
                        continue
                    
                    # Check for significant changes
                    prev = last_update[key]
                    changes = {}
                    
                    # Track meaningful changes
                    if abs(metric['calls_waiting'] - prev['calls_waiting']) > 2:
                        changes['calls_waiting'] = {
                            'old': prev['calls_waiting'],
                            'new': metric['calls_waiting']
                        }
                    
                    if abs(metric['agents_available'] - prev['agents_available']) > 0:
                        changes['agents_available'] = {
                            'old': prev['agents_available'],
                            'new': metric['agents_available']
                        }
                    
                    if metric['current_service_level'] and prev['current_service_level']:
                        sl_change = abs(float(metric['current_service_level']) - 
                                      float(prev['current_service_level']))
                        if sl_change > 5.0:  # 5% change
                            changes['service_level'] = {
                                'old': float(prev['current_service_level']),
                                'new': float(metric['current_service_level'])
                            }
                    
                    if changes:
                        await callback(service_id, metric, changes)
                    
                    last_update[key] = metric
                
                await asyncio.sleep(interval)
                
            except Exception as e:
                logger.error(f"Error in real-time monitoring: {e}")
                await asyncio.sleep(interval)
    
    async def health_check(self) -> Dict:
        """Check database connection and data freshness"""
        try:
            if not self.connected:
                return {'status': 'disconnected', 'error': 'No database connection'}
                
            async with self.pool.acquire() as conn:
                # Test basic connectivity
                result = await conn.fetchval("SELECT 1")
                
                # Check data freshness
                queue_check = await conn.fetchrow("""
                    SELECT 
                        COUNT(*) as total_services,
                        MAX(last_updated) as latest_update
                    FROM queue_current_metrics
                """)
                
                agent_check = await conn.fetchrow("""
                    SELECT 
                        COUNT(*) as total_agents,
                        MAX(last_updated) as latest_update
                    FROM agent_real_time_monitoring
                """)
                
                return {
                    'status': 'connected',
                    'database': self.config.database,
                    'queue_services': queue_check['total_services'],
                    'queue_last_update': queue_check['latest_update'],
                    'total_agents': agent_check['total_agents'],
                    'agent_last_update': agent_check['latest_update'],
                    'connection_pool_size': self.pool.get_size() if self.pool else 0
                }
                
        except Exception as e:
            return {'status': 'error', 'error': str(e)}

# Global connector instance
_connector = None

async def get_connector() -> WFMDatabaseConnector:
    """Get global database connector instance"""
    global _connector
    if _connector is None:
        _connector = WFMDatabaseConnector()
    if not _connector.connected:
        await _connector.connect()
    return _connector

async def close_connector():
    """Close global database connector"""
    global _connector
    if _connector:
        await _connector.disconnect()
        _connector = None