# Query Examples and Testing

This guide provides SQL query examples for testing and validating the Looker dashboard queries.

## Testing Queries

### 1. CPU Usage Per App

```sql
-- Basic query
SELECT * FROM `striim_watcher_metadata.looker_cpu_usage_per_app`
ORDER BY cpurate DESC
LIMIT 10;

-- Filter by cluster
SELECT * FROM `striim_watcher_metadata.looker_cpu_usage_per_app`
WHERE clusterName = 'production-cluster'
ORDER BY cpurate DESC;

-- High CPU apps (> 200%)
SELECT 
  appname,
  cpurate,
  rate,
  status
FROM `striim_watcher_metadata.looker_cpu_usage_per_app`
WHERE cpurate > 200
ORDER BY cpurate DESC;
```

### 2. App Failure List

```sql
-- Last 30 days
SELECT * FROM `striim_watcher_metadata.looker_app_failure_list`(30)
ORDER BY failure_time DESC;

-- Last 7 days
SELECT * FROM `striim_watcher_metadata.looker_app_failure_list`(7)
ORDER BY failure_time DESC;

-- Last 24 hours
SELECT * FROM `striim_watcher_metadata.looker_app_failure_list`(1)
ORDER BY failure_time DESC;

-- Apps down > 1 hour
SELECT 
  appName,
  failure_time,
  duration_terminated_minutes,
  ROUND(duration_terminated_minutes / 60.0, 2) as hours_down
FROM `striim_watcher_metadata.looker_app_failure_list`(30)
WHERE duration_terminated_minutes > 60
ORDER BY duration_terminated_minutes DESC;

-- Failure summary by cluster
SELECT 
  clusterName,
  COUNT(*) as failure_count,
  AVG(duration_terminated_minutes) as avg_downtime_minutes
FROM `striim_watcher_metadata.looker_app_failure_list`(30)
GROUP BY clusterName
ORDER BY failure_count DESC;
```

### 3. App Failure Drill-Down

```sql
-- Investigate specific app failure
SELECT * FROM `striim_watcher_metadata.looker_app_failure_drilldown`(
  'admin.MyApp',
  TIMESTAMP('2024-01-15 10:30:00'),
  15
)
ORDER BY log_date DESC;

-- Wider time window (30 minutes)
SELECT * FROM `striim_watcher_metadata.looker_app_failure_drilldown`(
  'admin.MyApp',
  TIMESTAMP('2024-01-15 10:30:00'),
  30
)
ORDER BY log_date DESC;

-- Count errors vs warnings
SELECT 
  log_level,
  COUNT(*) as log_count
FROM `striim_watcher_metadata.looker_app_failure_drilldown`(
  'admin.MyApp',
  TIMESTAMP('2024-01-15 10:30:00'),
  15
)
GROUP BY log_level;
```

### 4. Smart Alert History

```sql
-- Last 7 days
SELECT * FROM `striim_watcher_metadata.looker_smart_alert_history`(7)
ORDER BY log_date DESC
LIMIT 100;

-- Alert summary by app
SELECT 
  appName,
  COUNT(*) as alert_count,
  MIN(log_date) as first_alert,
  MAX(log_date) as last_alert
FROM `striim_watcher_metadata.looker_smart_alert_history`(7)
GROUP BY appName
ORDER BY alert_count DESC;

-- Search for specific message pattern
SELECT * FROM `striim_watcher_metadata.looker_smart_alert_history`(7)
WHERE LOWER(message) LIKE '%checkpoint%'
ORDER BY log_date DESC;

-- Alerts by hour of day
SELECT 
  EXTRACT(HOUR FROM log_date) as hour_of_day,
  COUNT(*) as alert_count
FROM `striim_watcher_metadata.looker_smart_alert_history`(30)
GROUP BY hour_of_day
ORDER BY hour_of_day;
```

### 5. Files Open List

```sql
-- All open files
SELECT * FROM `striim_watcher_metadata.looker_files_open_list`
ORDER BY minutes_since_last_update DESC;

-- Files stuck > 30 minutes
SELECT 
  appName,
  fileName,
  file_status,
  minutes_since_last_update,
  numberOfEvents
FROM `striim_watcher_metadata.looker_files_open_list`
WHERE minutes_since_last_update > 30
ORDER BY minutes_since_last_update DESC;

-- Summary by app
SELECT 
  appName,
  COUNT(*) as open_files_count,
  SUM(numberOfEvents) as total_events,
  AVG(minutes_since_last_update) as avg_minutes_since_update
FROM `striim_watcher_metadata.looker_files_open_list`
GROUP BY appName
ORDER BY open_files_count DESC;

-- Files by status
SELECT 
  file_status,
  COUNT(*) as file_count
FROM `striim_watcher_metadata.looker_files_open_list`
GROUP BY file_status;
```

### 6. Lag Graph

```sql
-- All apps, last 30 days
SELECT * FROM `striim_watcher_metadata.looker_lag_graph`(30, NULL, NULL, NULL)
ORDER BY batchdate DESC;

-- Specific app
SELECT * FROM `striim_watcher_metadata.looker_lag_graph`(30, 'admin.MyApp', NULL, NULL)
ORDER BY batchdate DESC;

-- Filter by source type
SELECT * FROM `striim_watcher_metadata.looker_lag_graph`(30, NULL, 'OracleReader', NULL)
ORDER BY batchdate DESC;

-- Detect lag spikes (current > 2x rolling average)
SELECT 
  batchdate,
  appName,
  current_lag,
  rolling_avg_7day,
  ROUND(current_lag / NULLIF(rolling_avg_7day, 0), 2) as spike_ratio
FROM `striim_watcher_metadata.looker_lag_graph`(30, NULL, NULL, NULL)
WHERE current_lag > (rolling_avg_7day * 2)
  AND rolling_avg_7day > 0
ORDER BY spike_ratio DESC;

-- Average lag by source/target type
SELECT
  sourceType,
  targetType,
  AVG(current_lag) as avg_lag,
  MAX(current_lag) as max_lag
FROM `striim_watcher_metadata.looker_lag_graph`(30, NULL, NULL, NULL)
GROUP BY sourceType, targetType
ORDER BY avg_lag DESC;
```

### 7. Data Flowing Graph

```sql
-- Last 7 days
SELECT * FROM `striim_watcher_metadata.looker_data_flowing_graph`(7)
ORDER BY batchdate DESC;

-- Last 24 hours
SELECT * FROM `striim_watcher_metadata.looker_data_flowing_graph`(1)
ORDER BY batchdate DESC;

-- Calculate records per minute
SELECT
  batchdate,
  total_input_cumulative,
  total_output_cumulative,
  total_input_rate,
  total_output_rate,
  CASE
    WHEN minutes_since_last_batch > 0
    THEN ROUND(total_input_rate / minutes_since_last_batch, 2)
    ELSE 0
  END as input_records_per_minute,
  CASE
    WHEN minutes_since_last_batch > 0
    THEN ROUND(total_output_rate / minutes_since_last_batch, 2)
    ELSE 0
  END as output_records_per_minute
FROM `striim_watcher_metadata.looker_data_flowing_graph`(7)
ORDER BY batchdate DESC;

-- Detect stalls (rate = 0)
SELECT
  batchdate,
  total_input_rate,
  total_output_rate,
  running_apps_count
FROM `striim_watcher_metadata.looker_data_flowing_graph`(7)
WHERE total_input_rate = 0 OR total_output_rate = 0
ORDER BY batchdate DESC;

-- Summary statistics
SELECT
  AVG(total_input_rate) as avg_input_rate,
  AVG(total_output_rate) as avg_output_rate,
  MAX(total_input_rate) as max_input_rate,
  MAX(total_output_rate) as max_output_rate,
  AVG(running_apps_count) as avg_running_apps
FROM `striim_watcher_metadata.looker_data_flowing_graph`(7);
```

### 8. Apps Down Count

```sql
-- All down apps
SELECT * FROM `striim_watcher_metadata.looker_apps_down_count`
ORDER BY duration_down_hours DESC;

-- Count by status
SELECT
  appStatus,
  COUNT(*) as down_apps_count,
  AVG(duration_down_hours) as avg_downtime_hours,
  MAX(duration_down_hours) as max_downtime_hours
FROM `striim_watcher_metadata.looker_apps_down_count`
GROUP BY appStatus;

-- Apps down > 1 hour
SELECT
  appName,
  appStatus,
  nodename,
  duration_down_hours,
  down_since
FROM `striim_watcher_metadata.looker_apps_down_count`
WHERE duration_down_hours > 1
ORDER BY duration_down_hours DESC;

-- Summary by cluster
SELECT
  clusterName,
  COUNT(*) as down_apps_count,
  AVG(duration_down_hours) as avg_downtime_hours
FROM `striim_watcher_metadata.looker_apps_down_count`
GROUP BY clusterName;
```

## Combined Queries for Dashboard Views

### Operational Dashboard Summary

```sql
-- Combined operational metrics
WITH cpu_summary AS (
  SELECT
    COUNT(*) as total_apps,
    AVG(cpurate) as avg_cpu,
    MAX(cpurate) as max_cpu
  FROM `striim_watcher_metadata.looker_cpu_usage_per_app`
),
failure_summary AS (
  SELECT COUNT(*) as failed_apps
  FROM `striim_watcher_metadata.looker_app_failure_list`(1)
),
files_summary AS (
  SELECT COUNT(*) as open_files
  FROM `striim_watcher_metadata.looker_files_open_list`
),
alert_summary AS (
  SELECT COUNT(*) as recent_alerts
  FROM `striim_watcher_metadata.looker_smart_alert_history`(1)
)
SELECT
  cpu_summary.*,
  failure_summary.failed_apps,
  files_summary.open_files,
  alert_summary.recent_alerts
FROM cpu_summary
CROSS JOIN failure_summary
CROSS JOIN files_summary
CROSS JOIN alert_summary;
```

### Leadership Dashboard Summary

```sql
-- Combined leadership metrics
WITH apps_down_summary AS (
  SELECT COUNT(*) as apps_down
  FROM `striim_watcher_metadata.looker_apps_down_count`
),
lag_summary AS (
  SELECT
    AVG(current_lag) as avg_current_lag,
    AVG(rolling_avg_7day) as avg_rolling_lag
  FROM `striim_watcher_metadata.looker_lag_graph`(7, NULL, NULL, NULL)
),
flow_summary AS (
  SELECT
    MAX(total_input_cumulative) as latest_input,
    MAX(total_output_cumulative) as latest_output,
    AVG(running_apps_count) as avg_running_apps
  FROM `striim_watcher_metadata.looker_data_flowing_graph`(1)
)
SELECT
  apps_down_summary.*,
  lag_summary.*,
  flow_summary.*
FROM apps_down_summary
CROSS JOIN lag_summary
CROSS JOIN flow_summary;
```

## Validation Queries

### Check Data Freshness

```sql
-- Check latest batchdate for each table
SELECT
  'striim_mon_table_runhistory' as table_name,
  MAX(batchdate) as latest_batchdate,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), MAX(batchdate), MINUTE) as minutes_old
FROM `striim_watcher_metadata.striim_mon_table_runhistory`

UNION ALL

SELECT
  'striim_mon_appdetail' as table_name,
  MAX(batchdate) as latest_batchdate,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), MAX(batchdate), MINUTE) as minutes_old
FROM `striim_watcher_metadata.striim_mon_appdetail`

UNION ALL

SELECT
  'striim_mon_lee' as table_name,
  MAX(batchdate) as latest_batchdate,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), MAX(batchdate), MINUTE) as minutes_old
FROM `striim_watcher_metadata.striim_mon_lee`;
```

### Verify Query Performance

```sql
-- Test query execution time
SELECT
  CURRENT_TIMESTAMP() as query_start,
  COUNT(*) as record_count
FROM `striim_watcher_metadata.looker_lag_graph`(30, NULL, NULL, NULL);
```

### Check for NULL Values

```sql
-- Check for missing clusterName
SELECT COUNT(*) as missing_cluster_count
FROM `striim_watcher_metadata.looker_cpu_usage_per_app`
WHERE clusterName IS NULL;

-- Check for missing nodename
SELECT COUNT(*) as missing_node_count
FROM `striim_watcher_metadata.looker_apps_down_count`
WHERE nodename IS NULL;
```

