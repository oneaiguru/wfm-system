"""Generate performance tracking reports"""

import psycopg2
import psycopg2.extras
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
import json


def generate_performance_report(days: int = 7, threshold_ms: int = 2000) -> str:
    """Generate weekly performance summary report"""
    
    conn = psycopg2.connect(
        host='localhost',
        database='wfm_enterprise',
        user='postgres',
        password='password'
    )
    
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    
    # Get report period
    end_date = datetime.now()
    start_date = end_date - timedelta(days=days)
    
    report = []
    report.append("\n📊 PERFORMANCE TRACKING REPORT")
    report.append("=" * 60)
    report.append(f"Period: {start_date.strftime('%Y-%m-%d')} to {end_date.strftime('%Y-%m-%d')}")
    report.append("=" * 60)
    
    # Overall statistics
    cur.execute("""
        SELECT 
            COUNT(DISTINCT query_text) as algorithms_tracked,
            COUNT(*) as total_executions,
            AVG(execution_time_ms) as avg_time_ms,
            MAX(execution_time_ms) as max_time_ms,
            COUNT(CASE WHEN execution_time_ms > %s THEN 1 END) as slow_queries,
            COUNT(CASE WHEN optimization_suggestions LIKE '%%Error:%%' THEN 1 END) as errors
        FROM query_performance_log
        WHERE logged_at > %s
    """, (threshold_ms, start_date))
    
    overall = cur.fetchone()
    
    report.append("\n📈 OVERALL STATISTICS:")
    report.append("-" * 40)
    report.append(f"Algorithms Tracked: {overall['algorithms_tracked']}")
    report.append(f"Total Executions: {overall['total_executions']}")
    report.append(f"Average Time: {overall['avg_time_ms']/1000:.2f}s")
    report.append(f"Maximum Time: {overall['max_time_ms']/1000:.2f}s")
    report.append(f"Slow Queries (>{threshold_ms/1000}s): {overall['slow_queries']}")
    report.append(f"Errors: {overall['errors']}")
    
    # Find slow algorithms
    cur.execute("""
        SELECT 
            query_text as algorithm,
            query_text as function,
            AVG(execution_time_ms) as avg_ms,
            MAX(execution_time_ms) as max_ms,
            MIN(execution_time_ms) as min_ms,
            COUNT(*) as executions,
            COUNT(CASE WHEN optimization_suggestions LIKE '%%Error:%%' THEN 1 END) as errors,
            PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY execution_time_ms) as p95_ms
        FROM query_performance_log
        WHERE logged_at > %s
        GROUP BY query_text
        HAVING AVG(execution_time_ms) > %s
        ORDER BY avg_ms DESC
    """, (start_date, threshold_ms))
    
    slow_queries = cur.fetchall()
    
    if slow_queries:
        report.append(f"\n🚨 ALGORITHMS EXCEEDING {threshold_ms/1000}s THRESHOLD:")
        report.append("-" * 60)
        
        for query in slow_queries:
            report.append(f"\n{query['algorithm']}.{query['function']}:")
            report.append(f"  Average: {query['avg_ms']/1000:.2f}s")
            report.append(f"  Maximum: {query['max_ms']/1000:.2f}s")
            report.append(f"  Minimum: {query['min_ms']/1000:.2f}s")
            report.append(f"  95th percentile: {query['p95_ms']/1000:.2f}s")
            report.append(f"  Executions: {query['executions']}")
            if query['errors'] > 0:
                report.append(f"  ⚠️ Errors: {query['errors']}")
            report.append(f"  Status: TRACKED (optimization postponed)")
    
    # Algorithm breakdown
    cur.execute("""
        SELECT 
            table_name as algorithm,
            COUNT(*) as total_calls,
            AVG(execution_time_ms) as avg_ms,
            MAX(execution_time_ms) as max_ms,
            COUNT(CASE WHEN execution_time_ms > %s THEN 1 END) as slow_calls,
            COUNT(CASE WHEN operation_type = 'error' THEN 1 END) as errors
        FROM query_performance_log
        WHERE timestamp > %s
        GROUP BY table_name
        ORDER BY avg_ms DESC
    """, (threshold_ms, start_date))
    
    algorithms = cur.fetchall()
    
    report.append("\n📊 PERFORMANCE BY ALGORITHM:")
    report.append("-" * 60)
    report.append(f"{'Algorithm':<30} {'Avg Time':>10} {'Max Time':>10} {'Calls':>8} {'Slow':>6} {'Errors':>6}")
    report.append("-" * 60)
    
    for alg in algorithms:
        avg_time = f"{alg['avg_ms']/1000:.2f}s"
        max_time = f"{alg['max_ms']/1000:.2f}s"
        report.append(
            f"{alg['algorithm']:<30} {avg_time:>10} {max_time:>10} "
            f"{alg['total_calls']:>8} {alg['slow_calls']:>6} {alg['errors']:>6}"
        )
    
    # Recent errors
    cur.execute("""
        SELECT 
            table_name as algorithm,
            query_text as function,
            error_message,
            timestamp,
            execution_time_ms
        FROM query_performance_log
        WHERE operation_type = 'error'
        AND timestamp > %s
        ORDER BY timestamp DESC
        LIMIT 10
    """, (start_date,))
    
    errors = cur.fetchall()
    
    if errors:
        report.append("\n❌ RECENT ERRORS:")
        report.append("-" * 60)
        for error in errors:
            report.append(f"\n{error['timestamp'].strftime('%Y-%m-%d %H:%M:%S')} - {error['algorithm']}.{error['function']}")
            report.append(f"  Error: {error['error_message'][:100]}...")
            report.append(f"  Execution time: {error['execution_time_ms']/1000:.2f}s")
    
    # Performance trends
    cur.execute("""
        SELECT 
            DATE(timestamp) as date,
            AVG(execution_time_ms) as avg_ms,
            MAX(execution_time_ms) as max_ms,
            COUNT(*) as executions
        FROM query_performance_log
        WHERE timestamp > %s
        GROUP BY DATE(timestamp)
        ORDER BY date
    """, (start_date,))
    
    trends = cur.fetchall()
    
    report.append("\n📈 DAILY PERFORMANCE TREND:")
    report.append("-" * 60)
    report.append(f"{'Date':<12} {'Avg Time':>10} {'Max Time':>10} {'Executions':>12}")
    report.append("-" * 60)
    
    for trend in trends:
        avg_time = f"{trend['avg_ms']/1000:.2f}s"
        max_time = f"{trend['max_ms']/1000:.2f}s"
        report.append(
            f"{trend['date'].strftime('%Y-%m-%d'):<12} {avg_time:>10} {max_time:>10} {trend['executions']:>12}"
        )
    
    # Recommendations
    report.append("\n💡 RECOMMENDATIONS:")
    report.append("-" * 60)
    report.append("1. TRACKING PHASE (Current):")
    report.append("   - Continue monitoring performance without optimization")
    report.append("   - Focus on data transformation for UI integration")
    report.append("   - Document slow queries for future optimization")
    
    if slow_queries:
        report.append("\n2. IDENTIFIED PERFORMANCE ISSUES:")
        for i, query in enumerate(slow_queries[:5], 1):
            report.append(f"   {i}. {query['algorithm']}.{query['function']} - Avg: {query['avg_ms']/1000:.2f}s")
    
    report.append("\n3. NEXT STEPS:")
    report.append("   - Complete UI transformation layer")
    report.append("   - Add tracking to remaining algorithms")
    report.append("   - Create performance baseline documentation")
    report.append("   - DO NOT OPTIMIZE until functionality is complete")
    
    cur.close()
    conn.close()
    
    return "\n".join(report)


def get_algorithm_performance(algorithm_name: str, days: int = 7) -> Dict[str, Any]:
    """Get detailed performance data for a specific algorithm"""
    
    conn = psycopg2.connect(
        host='localhost',
        database='wfm_enterprise',
        user='postgres',
        password='password'
    )
    
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    
    start_date = datetime.now() - timedelta(days=days)
    
    # Overall statistics
    cur.execute("""
        SELECT 
            COUNT(*) as total_executions,
            AVG(execution_time_ms) as avg_ms,
            MIN(execution_time_ms) as min_ms,
            MAX(execution_time_ms) as max_ms,
            STDDEV(execution_time_ms) as stddev_ms,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY execution_time_ms) as median_ms,
            PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY execution_time_ms) as p95_ms,
            PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY execution_time_ms) as p99_ms,
            COUNT(CASE WHEN operation_type = 'error' THEN 1 END) as error_count,
            AVG(result_size) as avg_result_size
        FROM query_performance_log
        WHERE table_name = %s
        AND timestamp > %s
    """, (algorithm_name, start_date))
    
    overall = cur.fetchone()
    
    # Function breakdown
    cur.execute("""
        SELECT 
            query_text as function,
            COUNT(*) as calls,
            AVG(execution_time_ms) as avg_ms,
            MAX(execution_time_ms) as max_ms,
            MIN(execution_time_ms) as min_ms,
            COUNT(CASE WHEN operation_type = 'error' THEN 1 END) as errors
        FROM query_performance_log
        WHERE table_name = %s
        AND timestamp > %s
        GROUP BY query_text
        ORDER BY calls DESC
    """, (algorithm_name, start_date))
    
    functions = cur.fetchall()
    
    # Time distribution
    cur.execute("""
        SELECT 
            CASE 
                WHEN execution_time_ms < 100 THEN '<100ms'
                WHEN execution_time_ms < 500 THEN '100-500ms'
                WHEN execution_time_ms < 1000 THEN '500ms-1s'
                WHEN execution_time_ms < 2000 THEN '1-2s'
                WHEN execution_time_ms < 5000 THEN '2-5s'
                WHEN execution_time_ms < 10000 THEN '5-10s'
                ELSE '>10s'
            END as time_bucket,
            COUNT(*) as count
        FROM query_performance_log
        WHERE table_name = %s
        AND timestamp > %s
        GROUP BY time_bucket
        ORDER BY 
            CASE time_bucket
                WHEN '<100ms' THEN 1
                WHEN '100-500ms' THEN 2
                WHEN '500ms-1s' THEN 3
                WHEN '1-2s' THEN 4
                WHEN '2-5s' THEN 5
                WHEN '5-10s' THEN 6
                ELSE 7
            END
    """, (algorithm_name, start_date))
    
    distribution = cur.fetchall()
    
    cur.close()
    conn.close()
    
    return {
        'algorithm': algorithm_name,
        'period_days': days,
        'overall': overall,
        'functions': functions,
        'time_distribution': distribution
    }


def export_performance_data(output_file: str = 'performance_data.json', days: int = 30):
    """Export performance data to JSON for further analysis"""
    
    conn = psycopg2.connect(
        host='localhost',
        database='wfm_enterprise',
        user='postgres',
        password='password'
    )
    
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    
    start_date = datetime.now() - timedelta(days=days)
    
    # Get all performance data
    cur.execute("""
        SELECT 
            table_name as algorithm,
            query_text as function,
            execution_time_ms,
            operation_type as status,
            timestamp,
            input_params,
            result_size,
            error_message
        FROM query_performance_log
        WHERE timestamp > %s
        ORDER BY timestamp DESC
    """, (start_date,))
    
    data = cur.fetchall()
    
    # Convert datetime objects to strings
    for row in data:
        row['timestamp'] = row['timestamp'].isoformat()
    
    # Export to JSON
    with open(output_file, 'w') as f:
        json.dump({
            'export_date': datetime.now().isoformat(),
            'period_days': days,
            'total_records': len(data),
            'data': data
        }, f, indent=2)
    
    cur.close()
    conn.close()
    
    print(f"Exported {len(data)} performance records to {output_file}")


if __name__ == "__main__":
    # Generate and print the report
    report = generate_performance_report()
    print(report)