"""
Database Integration Utilities
Created: 2025-07-11

Comprehensive utilities for database integration including:
- Connection management and pooling
- Query optimization and caching
- Data transformation and validation
- Performance monitoring
- Error handling and recovery
"""

import asyncio
import json
import logging
from typing import Dict, Any, List, Optional, Union, Callable
from datetime import datetime, timedelta
from contextlib import asynccontextmanager
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy import text, MetaData, Table, inspect
from sqlalchemy.pool import NullPool
from decimal import Decimal
import hashlib
import time

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class DatabaseIntegrationManager:
    """
    Comprehensive database integration manager for optimized database operations.
    """
    
    def __init__(self, database_url: str, pool_size: int = 20, max_overflow: int = 40):
        self.database_url = database_url
        self.pool_size = pool_size
        self.max_overflow = max_overflow
        self.engine = None
        self.metadata = MetaData()
        self.query_cache = {}
        self.cache_ttl = 300  # 5 minutes default
        
    async def initialize(self):
        """Initialize database engine and connection pool."""
        self.engine = create_async_engine(
            self.database_url,
            echo=False,
            pool_size=self.pool_size,
            max_overflow=self.max_overflow,
            pool_pre_ping=True,
            pool_recycle=3600,
            poolclass=NullPool  # Use NullPool for better async performance
        )
        
        # Load metadata
        async with self.engine.begin() as conn:
            await conn.run_sync(self.metadata.reflect)
            
        logger.info(f"Database integration initialized with {len(self.metadata.tables)} tables")
    
    @asynccontextmanager
    async def get_session(self):
        """Get database session with automatic cleanup."""
        from sqlalchemy.ext.asyncio import async_sessionmaker
        
        async_session = async_sessionmaker(
            self.engine,
            class_=AsyncSession,
            expire_on_commit=False
        )
        
        async with async_session() as session:
            try:
                yield session
            except Exception as e:
                await session.rollback()
                raise e
            finally:
                await session.close()
    
    async def execute_query(
        self,
        query: str,
        parameters: Optional[Dict[str, Any]] = None,
        use_cache: bool = True,
        cache_key: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Execute query with caching and optimization.
        """
        # Generate cache key if not provided
        if use_cache and cache_key is None:
            cache_key = self._generate_cache_key(query, parameters)
        
        # Check cache first
        if use_cache and cache_key in self.query_cache:
            cache_entry = self.query_cache[cache_key]
            if datetime.now() - cache_entry['timestamp'] < timedelta(seconds=self.cache_ttl):
                logger.debug(f"Cache hit for query: {cache_key}")
                return cache_entry['data']
        
        # Execute query
        start_time = time.time()
        
        async with self.get_session() as session:
            result = await session.execute(text(query), parameters or {})
            rows = result.fetchall()
            
            # Convert to dictionaries
            data = []
            if rows:
                columns = result.keys()
                data = [dict(zip(columns, row)) for row in rows]
        
        execution_time = time.time() - start_time
        logger.info(f"Query executed in {execution_time:.3f}s, returned {len(data)} rows")
        
        # Cache results
        if use_cache:
            self.query_cache[cache_key] = {
                'data': data,
                'timestamp': datetime.now(),
                'execution_time': execution_time
            }
        
        return data
    
    async def execute_bulk_operation(
        self,
        operation_type: str,
        table_name: str,
        data: List[Dict[str, Any]],
        chunk_size: int = 1000
    ) -> Dict[str, Any]:
        """
        Execute bulk operations with batching and error handling.
        """
        if not data:
            return {"status": "success", "processed": 0, "errors": []}
        
        start_time = time.time()
        processed_count = 0
        errors = []
        
        async with self.get_session() as session:
            try:
                # Process in chunks
                for i in range(0, len(data), chunk_size):
                    chunk = data[i:i + chunk_size]
                    
                    try:
                        if operation_type == "insert":
                            await self._bulk_insert(session, table_name, chunk)
                        elif operation_type == "update":
                            await self._bulk_update(session, table_name, chunk)
                        elif operation_type == "upsert":
                            await self._bulk_upsert(session, table_name, chunk)
                        else:
                            raise ValueError(f"Unsupported operation type: {operation_type}")
                        
                        processed_count += len(chunk)
                        
                    except Exception as e:
                        logger.error(f"Error processing chunk {i//chunk_size + 1}: {str(e)}")
                        errors.append({
                            "chunk": i//chunk_size + 1,
                            "error": str(e),
                            "records": len(chunk)
                        })
                
                await session.commit()
                
            except Exception as e:
                await session.rollback()
                logger.error(f"Bulk operation failed: {str(e)}")
                raise e
        
        execution_time = time.time() - start_time
        
        return {
            "status": "completed" if not errors else "partial",
            "processed": processed_count,
            "errors": errors,
            "execution_time": execution_time,
            "total_records": len(data)
        }
    
    async def get_table_schema(self, table_name: str) -> Dict[str, Any]:
        """Get detailed table schema information."""
        if table_name not in self.metadata.tables:
            raise ValueError(f"Table {table_name} not found")
        
        table = self.metadata.tables[table_name]
        
        columns = []
        for column in table.columns:
            columns.append({
                "name": column.name,
                "type": str(column.type),
                "nullable": column.nullable,
                "default": str(column.default) if column.default else None,
                "primary_key": column.primary_key,
                "foreign_keys": [str(fk.column) for fk in column.foreign_keys]
            })
        
        indexes = []
        for index in table.indexes:
            indexes.append({
                "name": index.name,
                "columns": [col.name for col in index.columns],
                "unique": index.unique
            })
        
        return {
            "table_name": table_name,
            "columns": columns,
            "indexes": indexes,
            "primary_key": [col.name for col in table.primary_key.columns],
            "foreign_keys": [
                {
                    "constraint_name": fk.name,
                    "columns": [col.name for col in fk.columns],
                    "referred_table": fk.referred_table.name,
                    "referred_columns": [col.name for col in fk.referred_table.columns]
                }
                for fk in table.foreign_keys
            ]
        }
    
    async def validate_data_integrity(
        self,
        table_name: str,
        data: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Validate data integrity against table schema.
        """
        if table_name not in self.metadata.tables:
            raise ValueError(f"Table {table_name} not found")
        
        table = self.metadata.tables[table_name]
        validation_results = {
            "valid_records": [],
            "invalid_records": [],
            "validation_errors": [],
            "summary": {
                "total_records": len(data),
                "valid_count": 0,
                "invalid_count": 0,
                "error_types": {}
            }
        }
        
        for idx, record in enumerate(data):
            record_errors = []
            
            # Check required fields
            for column in table.columns:
                if not column.nullable and column.default is None:
                    if column.name not in record or record[column.name] is None:
                        record_errors.append(f"Missing required field: {column.name}")
            
            # Check data types
            for field_name, field_value in record.items():
                if field_name in [col.name for col in table.columns]:
                    column = next(col for col in table.columns if col.name == field_name)
                    if not self._validate_data_type(field_value, column.type):
                        record_errors.append(f"Invalid data type for {field_name}: {type(field_value)}")
            
            # Check foreign key constraints
            for fk in table.foreign_keys:
                fk_column = next(col for col in fk.columns)
                if fk_column.name in record:
                    # This would require additional validation against referenced table
                    pass
            
            if record_errors:
                validation_results["invalid_records"].append({
                    "index": idx,
                    "record": record,
                    "errors": record_errors
                })
                validation_results["summary"]["invalid_count"] += 1
                
                # Count error types
                for error in record_errors:
                    error_type = error.split(":")[0]
                    validation_results["summary"]["error_types"][error_type] = \
                        validation_results["summary"]["error_types"].get(error_type, 0) + 1
            else:
                validation_results["valid_records"].append(record)
                validation_results["summary"]["valid_count"] += 1
        
        return validation_results
    
    async def optimize_query_performance(self, query: str) -> Dict[str, Any]:
        """
        Analyze and optimize query performance.
        """
        async with self.get_session() as session:
            # Get query execution plan
            explain_query = f"EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) {query}"
            result = await session.execute(text(explain_query))
            plan = result.fetchone()[0]
            
            # Analyze execution plan
            analysis = self._analyze_execution_plan(plan[0])
            
            # Generate optimization suggestions
            suggestions = self._generate_optimization_suggestions(analysis)
            
            return {
                "query": query,
                "execution_plan": plan[0],
                "analysis": analysis,
                "suggestions": suggestions,
                "timestamp": datetime.now().isoformat()
            }
    
    async def monitor_database_health(self) -> Dict[str, Any]:
        """
        Monitor database health and performance metrics.
        """
        health_metrics = {}
        
        async with self.get_session() as session:
            # Connection pool status
            pool_status = {
                "size": self.engine.pool.size(),
                "checked_in": self.engine.pool.checkedin(),
                "checked_out": self.engine.pool.checkedout(),
                "overflow": self.engine.pool.overflow(),
                "invalidated": self.engine.pool.invalidated()
            }
            
            # Database statistics
            db_stats_query = """
            SELECT 
                pg_database_size(current_database()) as db_size,
                pg_stat_get_db_numbackends(oid) as connections,
                pg_stat_get_db_xact_commit(oid) as commits,
                pg_stat_get_db_xact_rollback(oid) as rollbacks,
                pg_stat_get_db_blocks_fetched(oid) as blocks_fetched,
                pg_stat_get_db_blocks_hit(oid) as blocks_hit
            FROM pg_database WHERE datname = current_database()
            """
            
            result = await session.execute(text(db_stats_query))
            db_stats = result.fetchone()
            
            # Table statistics
            table_stats_query = """
            SELECT 
                schemaname,
                tablename,
                n_tup_ins,
                n_tup_upd,
                n_tup_del,
                n_live_tup,
                n_dead_tup,
                last_vacuum,
                last_autovacuum,
                last_analyze,
                last_autoanalyze
            FROM pg_stat_user_tables
            WHERE schemaname = 'public'
            ORDER BY n_live_tup DESC
            LIMIT 10
            """
            
            table_result = await session.execute(text(table_stats_query))
            table_stats = table_result.fetchall()
            
            # Long running queries
            long_queries_query = """
            SELECT 
                pid,
                now() - pg_stat_activity.query_start AS duration,
                query,
                state
            FROM pg_stat_activity
            WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes'
            AND state = 'active'
            ORDER BY duration DESC
            """
            
            long_result = await session.execute(text(long_queries_query))
            long_queries = long_result.fetchall()
            
            health_metrics = {
                "pool_status": pool_status,
                "database_stats": {
                    "database_size": db_stats.db_size,
                    "connections": db_stats.connections,
                    "commits": db_stats.commits,
                    "rollbacks": db_stats.rollbacks,
                    "blocks_fetched": db_stats.blocks_fetched,
                    "blocks_hit": db_stats.blocks_hit,
                    "cache_hit_ratio": (db_stats.blocks_hit / (db_stats.blocks_hit + db_stats.blocks_fetched)) * 100
                    if (db_stats.blocks_hit + db_stats.blocks_fetched) > 0 else 0
                },
                "table_statistics": [
                    {
                        "schema": row.schemaname,
                        "table": row.tablename,
                        "inserts": row.n_tup_ins,
                        "updates": row.n_tup_upd,
                        "deletes": row.n_tup_del,
                        "live_rows": row.n_live_tup,
                        "dead_rows": row.n_dead_tup,
                        "last_vacuum": row.last_vacuum.isoformat() if row.last_vacuum else None,
                        "last_analyze": row.last_analyze.isoformat() if row.last_analyze else None
                    }
                    for row in table_stats
                ],
                "long_running_queries": [
                    {
                        "pid": row.pid,
                        "duration": str(row.duration),
                        "query": row.query[:100] + "..." if len(row.query) > 100 else row.query,
                        "state": row.state
                    }
                    for row in long_queries
                ],
                "health_score": self._calculate_health_score(db_stats, table_stats, long_queries),
                "timestamp": datetime.now().isoformat()
            }
        
        return health_metrics
    
    def clear_cache(self, pattern: Optional[str] = None):
        """Clear query cache."""
        if pattern:
            # Clear specific cache entries matching pattern
            keys_to_remove = [key for key in self.query_cache.keys() if pattern in key]
            for key in keys_to_remove:
                del self.query_cache[key]
        else:
            # Clear all cache
            self.query_cache.clear()
        
        logger.info(f"Cache cleared: {len(self.query_cache)} entries remaining")
    
    # Private helper methods
    
    def _generate_cache_key(self, query: str, parameters: Optional[Dict[str, Any]]) -> str:
        """Generate cache key for query and parameters."""
        key_data = {
            "query": query,
            "parameters": parameters or {}
        }
        key_string = json.dumps(key_data, sort_keys=True, default=str)
        return hashlib.md5(key_string.encode()).hexdigest()
    
    async def _bulk_insert(self, session: AsyncSession, table_name: str, data: List[Dict[str, Any]]):
        """Perform bulk insert operation."""
        table = self.metadata.tables[table_name]
        
        # Convert data to format suitable for bulk insert
        insert_data = []
        for record in data:
            # Convert Decimal and other types to JSON-serializable format
            converted_record = {}
            for key, value in record.items():
                if isinstance(value, Decimal):
                    converted_record[key] = float(value)
                elif isinstance(value, datetime):
                    converted_record[key] = value.isoformat()
                else:
                    converted_record[key] = value
            insert_data.append(converted_record)
        
        # Execute bulk insert
        await session.execute(table.insert(), insert_data)
    
    async def _bulk_update(self, session: AsyncSession, table_name: str, data: List[Dict[str, Any]]):
        """Perform bulk update operation."""
        table = self.metadata.tables[table_name]
        
        # This would require identifying primary key columns and building update statements
        # For now, we'll use a simple approach
        for record in data:
            # Identify primary key
            pk_columns = [col.name for col in table.primary_key.columns]
            if not pk_columns:
                raise ValueError(f"Table {table_name} has no primary key for update operation")
            
            # Build where clause
            where_clause = {col: record[col] for col in pk_columns if col in record}
            update_data = {k: v for k, v in record.items() if k not in pk_columns}
            
            await session.execute(
                table.update().where(
                    *[table.c[col] == val for col, val in where_clause.items()]
                ).values(**update_data)
            )
    
    async def _bulk_upsert(self, session: AsyncSession, table_name: str, data: List[Dict[str, Any]]):
        """Perform bulk upsert (insert or update) operation."""
        # This would implement PostgreSQL's ON CONFLICT DO UPDATE
        # For now, we'll use a simple insert with conflict resolution
        table = self.metadata.tables[table_name]
        
        for record in data:
            # Try insert, if conflict then update
            try:
                await session.execute(table.insert(), record)
            except Exception:
                # If insert fails, try update
                pk_columns = [col.name for col in table.primary_key.columns]
                if pk_columns:
                    where_clause = {col: record[col] for col in pk_columns if col in record}
                    update_data = {k: v for k, v in record.items() if k not in pk_columns}
                    
                    await session.execute(
                        table.update().where(
                            *[table.c[col] == val for col, val in where_clause.items()]
                        ).values(**update_data)
                    )
    
    def _validate_data_type(self, value: Any, column_type) -> bool:
        """Validate data type against column type."""
        if value is None:
            return True  # NULL is valid for any type
        
        # This is a simplified validation
        # In practice, you'd need more sophisticated type checking
        return True
    
    def _analyze_execution_plan(self, plan: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze query execution plan for performance insights."""
        analysis = {
            "total_cost": plan.get("Total Cost", 0),
            "execution_time": plan.get("Actual Total Time", 0),
            "rows_returned": plan.get("Actual Rows", 0),
            "scan_types": [],
            "joins": [],
            "indexes_used": [],
            "performance_issues": []
        }
        
        # Recursive analysis of plan nodes
        def analyze_node(node):
            node_type = node.get("Node Type", "")
            
            if "Scan" in node_type:
                analysis["scan_types"].append(node_type)
                if "Seq Scan" in node_type:
                    analysis["performance_issues"].append("Sequential scan detected")
                elif "Index Scan" in node_type:
                    analysis["indexes_used"].append(node.get("Index Name", ""))
            
            if "Join" in node_type:
                analysis["joins"].append(node_type)
            
            # Analyze child nodes
            for child in node.get("Plans", []):
                analyze_node(child)
        
        analyze_node(plan)
        return analysis
    
    def _generate_optimization_suggestions(self, analysis: Dict[str, Any]) -> List[str]:
        """Generate query optimization suggestions based on analysis."""
        suggestions = []
        
        if "Sequential scan detected" in analysis["performance_issues"]:
            suggestions.append("Consider adding indexes to avoid sequential scans")
        
        if analysis["execution_time"] > 1000:  # > 1 second
            suggestions.append("Query execution time is high, consider optimization")
        
        if "Nested Loop" in analysis["joins"]:
            suggestions.append("Nested loop joins can be expensive, consider join order optimization")
        
        if not analysis["indexes_used"]:
            suggestions.append("No indexes used, consider adding appropriate indexes")
        
        return suggestions
    
    def _calculate_health_score(self, db_stats, table_stats, long_queries) -> int:
        """Calculate overall database health score (0-100)."""
        score = 100
        
        # Penalize for low cache hit ratio
        cache_hit_ratio = (db_stats.blocks_hit / (db_stats.blocks_hit + db_stats.blocks_fetched)) * 100 \
                         if (db_stats.blocks_hit + db_stats.blocks_fetched) > 0 else 0
        if cache_hit_ratio < 90:
            score -= 20
        elif cache_hit_ratio < 95:
            score -= 10
        
        # Penalize for high rollback ratio
        total_transactions = db_stats.commits + db_stats.rollbacks
        if total_transactions > 0:
            rollback_ratio = (db_stats.rollbacks / total_transactions) * 100
            if rollback_ratio > 5:
                score -= 15
            elif rollback_ratio > 2:
                score -= 5
        
        # Penalize for long running queries
        if long_queries:
            score -= len(long_queries) * 5
        
        # Penalize for high dead tuple ratio
        for table in table_stats:
            if table.n_live_tup > 0:
                dead_ratio = (table.n_dead_tup / table.n_live_tup) * 100
                if dead_ratio > 20:
                    score -= 5
        
        return max(0, min(100, score))


# Utility functions for common database operations

class DatabaseQueryBuilder:
    """Helper class for building complex database queries."""
    
    def __init__(self, table_name: str):
        self.table_name = table_name
        self.select_fields = []
        self.join_clauses = []
        self.where_conditions = []
        self.group_by_fields = []
        self.having_conditions = []
        self.order_by_fields = []
        self.limit_value = None
        self.offset_value = None
    
    def select(self, *fields):
        """Add SELECT fields."""
        self.select_fields.extend(fields)
        return self
    
    def join(self, table: str, condition: str, join_type: str = "INNER"):
        """Add JOIN clause."""
        self.join_clauses.append(f"{join_type} JOIN {table} ON {condition}")
        return self
    
    def where(self, condition: str):
        """Add WHERE condition."""
        self.where_conditions.append(condition)
        return self
    
    def group_by(self, *fields):
        """Add GROUP BY fields."""
        self.group_by_fields.extend(fields)
        return self
    
    def having(self, condition: str):
        """Add HAVING condition."""
        self.having_conditions.append(condition)
        return self
    
    def order_by(self, field: str, direction: str = "ASC"):
        """Add ORDER BY field."""
        self.order_by_fields.append(f"{field} {direction}")
        return self
    
    def limit(self, count: int):
        """Add LIMIT."""
        self.limit_value = count
        return self
    
    def offset(self, count: int):
        """Add OFFSET."""
        self.offset_value = count
        return self
    
    def build(self) -> str:
        """Build the final query string."""
        # SELECT clause
        if self.select_fields:
            select_clause = f"SELECT {', '.join(self.select_fields)}"
        else:
            select_clause = "SELECT *"
        
        # FROM clause
        from_clause = f"FROM {self.table_name}"
        
        # Build complete query
        query_parts = [select_clause, from_clause]
        
        if self.join_clauses:
            query_parts.extend(self.join_clauses)
        
        if self.where_conditions:
            query_parts.append(f"WHERE {' AND '.join(self.where_conditions)}")
        
        if self.group_by_fields:
            query_parts.append(f"GROUP BY {', '.join(self.group_by_fields)}")
        
        if self.having_conditions:
            query_parts.append(f"HAVING {' AND '.join(self.having_conditions)}")
        
        if self.order_by_fields:
            query_parts.append(f"ORDER BY {', '.join(self.order_by_fields)}")
        
        if self.limit_value:
            query_parts.append(f"LIMIT {self.limit_value}")
        
        if self.offset_value:
            query_parts.append(f"OFFSET {self.offset_value}")
        
        return " ".join(query_parts)


# Data transformation utilities

class DataTransformer:
    """Utility class for data transformation operations."""
    
    @staticmethod
    def convert_to_json_serializable(data: Any) -> Any:
        """Convert data to JSON-serializable format."""
        if isinstance(data, dict):
            return {key: DataTransformer.convert_to_json_serializable(value) for key, value in data.items()}
        elif isinstance(data, list):
            return [DataTransformer.convert_to_json_serializable(item) for item in data]
        elif isinstance(data, Decimal):
            return float(data)
        elif isinstance(data, datetime):
            return data.isoformat()
        elif isinstance(data, date):
            return data.isoformat()
        else:
            return data
    
    @staticmethod
    def normalize_field_names(data: Dict[str, Any], case_style: str = "snake_case") -> Dict[str, Any]:
        """Normalize field names to specific case style."""
        normalized = {}
        
        for key, value in data.items():
            if case_style == "snake_case":
                normalized_key = key.lower().replace(" ", "_").replace("-", "_")
            elif case_style == "camelCase":
                words = key.replace("_", " ").replace("-", " ").split()
                normalized_key = words[0].lower() + "".join(word.capitalize() for word in words[1:])
            else:
                normalized_key = key
            
            normalized[normalized_key] = value
        
        return normalized
    
    @staticmethod
    def flatten_nested_data(data: Dict[str, Any], separator: str = "_") -> Dict[str, Any]:
        """Flatten nested dictionary data."""
        flattened = {}
        
        def flatten_recursive(obj, prefix=""):
            if isinstance(obj, dict):
                for key, value in obj.items():
                    new_key = f"{prefix}{separator}{key}" if prefix else key
                    flatten_recursive(value, new_key)
            else:
                flattened[prefix] = obj
        
        flatten_recursive(data)
        return flattened


# Export the main integration manager
__all__ = [
    "DatabaseIntegrationManager",
    "DatabaseQueryBuilder", 
    "DataTransformer"
]