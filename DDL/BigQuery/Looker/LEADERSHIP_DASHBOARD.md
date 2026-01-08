# Leadership Dashboard - Query Guide

This dashboard provides high-level metrics and trends for leadership visibility into Striim operations, focusing on lag, throughput, and availability.

## Dashboard Components

### 1. Lag Graph (7-Day Rolling Average + Current Lag)

**Query**: `looker_lag_graph(days_back, filter_app_name, filter_source_type, filter_target_type)` (Table Function)

**Purpose**: Visualize end-to-end lag trends with rolling averages to detect performance degradation.

**Parameters**:
- `days_back` - Number of days of history (default 30)
- `filter_app_name` - Filter by specific app (NULL for all)
- `filter_source_type` - Filter by source type (NULL for all)
- `filter_target_type` - Filter by target type (NULL for all)

**Columns**:
- `clusterName` - Cluster identifier
- `batchdate` - Monitoring snapshot timestamp
- `appName` - Application name (sourceApp or targetApp)
- `sourceApp` - Source application
- `sourceName` - Source name
- `sourceType` - Source type (e.g., OracleReader, MySQLReader)
- `targetApp` - Target application
- `targetName` - Target name
- `targetType` - Target type (e.g., BigQueryWriter, KafkaWriter)
- `current_lag` - Current avgLEE value (milliseconds)
- `rolling_avg_7day` - 7-day rolling average of lag
- `min_lag` - Minimum lag in sample
- `max_lag` - Maximum lag in sample

**Usage in Looker**:

```sql
-- All apps, last 30 days
SELECT * FROM `striim_watcher_metadata.looker_lag_graph`(30, NULL, NULL, NULL)

-- Specific app, last 7 days
SELECT * FROM `striim_watcher_metadata.looker_lag_graph`(7, 'admin.MyApp', NULL, NULL)

-- Filter by source type (Oracle), last 14 days
SELECT * FROM `striim_watcher_metadata.looker_lag_graph`(14, NULL, 'OracleReader', NULL)

-- Filter by target type (BigQuery), last 30 days
SELECT * FROM `striim_watcher_metadata.looker_lag_graph`(30, NULL, NULL, 'BigQueryWriter')
```

**Visualization Recommendations**:

**Primary Chart**: Combo chart with:
- **Line**: `rolling_avg_7day` (smooth trend line)
- **Bars**: `current_lag` (vertical bars showing current values)
- **X-axis**: `batchdate`
- **Y-axis**: Lag in milliseconds

**Filters**:
- `clusterName` (dropdown)
- `appName` (multi-select)
- `sourceType` (multi-select with "All" option)
- `targetType` (multi-select with "All" option)
- Date range (via `days_back` parameter)

**Key Metrics**:
- Spike detection: When `current_lag` significantly exceeds `rolling_avg_7day`
- Trend analysis: Is `rolling_avg_7day` increasing over time?
- Comparison: Lag across different source/target types

**Aggregation for Multiple Apps**:
When multiple apps are selected, use AVG aggregation:
```sql
SELECT
  batchdate,
  AVG(current_lag) as avg_current_lag,
  AVG(rolling_avg_7day) as avg_rolling_avg
FROM `striim_watcher_metadata.looker_lag_graph`(30, NULL, NULL, NULL)
WHERE appName IN ('admin.App1', 'admin.App2')
GROUP BY batchdate
ORDER BY batchdate
```

---

### 2. Data Flowing Graph

**Query**: `looker_data_flowing_graph(days_back)` (Table Function)

**Purpose**: Monitor data throughput across all RUNNING applications to ensure healthy data flow.

**Parameters**:
- `days_back` - Number of days of history (default 7)

**Columns**:
- `clusterName` - Cluster identifier
- `batchdate` - Monitoring snapshot timestamp
- `total_input_cumulative` - Cumulative input count across all RUNNING apps
- `total_output_cumulative` - Cumulative output count across all RUNNING apps
- `total_input_rate` - Records processed since last batchdate (input)
- `total_output_rate` - Records processed since last batchdate (output)
- `running_apps_count` - Number of RUNNING apps
- `minutes_since_last_batch` - Time between monitoring snapshots

**Usage in Looker**:

```sql
-- Last 7 days
SELECT * FROM `striim_watcher_metadata.looker_data_flowing_graph`(7)

-- Last 24 hours
SELECT * FROM `striim_watcher_metadata.looker_data_flowing_graph`(1)
```

**Visualization Recommendations**:

**Chart 1 - Cumulative Data Flow**:
- **Type**: Line chart with dual Y-axes
- **Line 1**: `total_input_cumulative` (left Y-axis)
- **Line 2**: `total_output_cumulative` (left Y-axis)
- **X-axis**: `batchdate`

**Chart 2 - Data Flow Rate**:
- **Type**: Line chart
- **Line 1**: `total_input_rate` (records/batch)
- **Line 2**: `total_output_rate` (records/batch)
- **X-axis**: `batchdate`

**Chart 3 - Running Apps Count**:
- **Type**: Area chart
- **Area**: `running_apps_count`
- **X-axis**: `batchdate`

**Combined Dashboard View**:
```sql
SELECT
  batchdate,
  total_input_cumulative,
  total_output_cumulative,
  total_input_rate,
  total_output_rate,
  running_apps_count,
  -- Calculate records per minute
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
ORDER BY batchdate DESC
```

**Key Metrics**:
- **Throughput**: Records per minute (rate / minutes_since_last_batch)
- **Lag Detection**: Input rate significantly higher than output rate
- **Stall Detection**: Rate drops to zero or near-zero
- **Capacity**: Correlation between running_apps_count and throughput

---

### 3. Apps Down Count & Drill-In List

**Query**: `looker_apps_down_count` (View)

**Purpose**: Monitor application availability and identify down applications.

**Columns**:
- `clusterName` - Cluster identifier
- `batchdate` - Latest monitoring snapshot
- `nodename` - Node where app is deployed
- `appName` - Application name
- `appStatus` - Current status (HALTED or TERMINATED)
- `down_since` - When app first went down
- `duration_down_minutes` - Minutes app has been down
- `duration_down_hours` - Hours app has been down
- `totalInput` - Total input count
- `totalOutput` - Total output count
- `isBackpressured` - Backpressure indicator
- `checkpointStatus` - Checkpoint status
- `latestActivity` - Last activity timestamp

**Usage in Looker**:

```sql
-- All down apps
SELECT * FROM `striim_watcher_metadata.looker_apps_down_count`

-- Count by status
SELECT
  appStatus,
  COUNT(*) as down_apps_count,
  AVG(duration_down_hours) as avg_downtime_hours
FROM `striim_watcher_metadata.looker_apps_down_count`
GROUP BY appStatus

-- Apps down > 1 hour
SELECT *
FROM `striim_watcher_metadata.looker_apps_down_count`
WHERE duration_down_hours > 1
ORDER BY duration_down_hours DESC
```

**Visualization Recommendations**:

**KPI Tile - Apps Down Count**:
```sql
SELECT COUNT(*) as apps_down
FROM `striim_watcher_metadata.looker_apps_down_count`
```
- **Type**: Single value
- **Alert**: Red if > 0, Green if = 0

**Drill-In Table**:
- **Columns**: appName, appStatus, nodename, duration_down_hours, down_since
- **Sorting**: duration_down_hours DESC
- **Filters**: clusterName, appStatus

**Timeline Chart**:
- **Type**: Gantt chart
- **X-axis**: Time
- **Y-axis**: appName
- **Bar**: From down_since to current time
- **Color**: By appStatus (HALTED vs TERMINATED)

**Key Metrics**:
- Total apps down
- Average downtime
- Apps down > SLA threshold (e.g., 1 hour)
- Repeat offenders (apps that go down frequently)

---

### 4. Data Integrity Summary

**Query**: `looker_data_integrity` (View)

**Purpose**: Monitor data synchronization between source and target to detect drift and ensure data integrity.

**Columns**:
- `clusterName` - Cluster identifier
- `batchdate` - Monitoring snapshot timestamp
- `nodename` - Node where app is deployed
- `appName` - Application name
- `sourceName` - Source table name
- `targetName` - Target table name
- `sourceComponentName` - Source component name
- `targetComponentName` - Target component name
- `srcNumOfInserts` / `tgtNumOfInserts` / `diffNumOfInserts` - Insert counts and difference
- `srcNumOfUpdates` / `tgtNumOfUpdates` / `diffNumOfUpdates` - Update counts and difference
- `srcNumOfDeletes` / `tgtNumOfDeletes` / `diffNumOfDeletes` - Delete counts and difference
- `srcNumOfDdls` / `tgtNumOfDdls` / `diffNumOfDdls` - DDL counts and difference
- `srcNumOfPkupdates` / `tgtNumOfPkupdates` / `diffNumOfPkupdates` - PK update counts and difference
- `total_difference` - Sum of all absolute differences
- `sync_status` - Status: IN_SYNC, MINOR_DRIFT, MODERATE_DRIFT, SIGNIFICANT_DRIFT
- `sync_severity` - Numeric severity (1-4)

**Usage in Looker**:
```sql
-- All tables by sync status
SELECT * FROM `striim_watcher_metadata.looker_data_integrity`
ORDER BY sync_severity DESC, total_difference DESC

-- Only tables with drift
SELECT * FROM `striim_watcher_metadata.looker_data_integrity`
WHERE sync_status != 'IN_SYNC'

-- Summary by application
SELECT
  appName,
  COUNT(*) as table_count,
  SUM(CASE WHEN sync_status = 'IN_SYNC' THEN 1 ELSE 0 END) as in_sync_count,
  SUM(total_difference) as total_drift
FROM `striim_watcher_metadata.looker_data_integrity`
GROUP BY appName
ORDER BY total_drift DESC
```

**Visualization Recommendations**:
- **Pie Chart**: Tables by sync_status
- **Stacked Bar**: Drift breakdown by app (inserts, updates, deletes)
- **Table**: Detailed comparison with drill-down
- **KPI Tiles**: Tables in sync / total tables
- **Filters**: clusterName, appName, sync_status

**Key Metrics**:
- Percentage of tables in sync
- Total drift across all tables
- Apps with highest drift

---

### 5. Batch Processing Efficiency

**Query**: `looker_batch_processing` (View)

**Purpose**: Monitor BigQuery and data warehouse target batch processing health including queue depth, batch sizes, and integration times.

**Columns**:
- `clusterName` - Cluster identifier
- `batchdate` - Monitoring snapshot timestamp
- `nodename` - Node where app is deployed
- `appName` - Application name
- `sourceName` / `targetName` - Source and target names
- `targetComponentName` - Target component name
- `target_adaptername` - Target adapter (e.g., BQ)
- `projectId` - GCP project ID (for BigQuery)
- `Mode` - APPENDONLY or MERGE
- `streamingUpload` / `optimizedMerge` - Configuration flags
- `batch_event_count` / `batch_interval` - Batch configuration
- `total_batches_queued` - Current queue depth
- `total_batches_created` / `total_batches_uploaded` - Processing counts
- `avg_batch_size_bytes` / `avg_batch_size_mb` - Batch sizes
- `avg_integration_time_ms` - Average integration time
- `avg_waiting_time_in_queue_ms` - Average queue wait time
- `upload_success_rate_pct` - Upload success percentage
- `queue_health_status` - Status: HEALTHY, MODERATE, HIGH, CRITICAL
- `integration_speed_status` - Status: FAST, NORMAL, SLOW, VERY_SLOW

**Usage in Looker**:
```sql
-- Current batch processing status
SELECT * FROM `striim_watcher_metadata.looker_batch_processing`
ORDER BY total_batches_queued DESC

-- Targets with high queue depth
SELECT * FROM `striim_watcher_metadata.looker_batch_processing`
WHERE queue_health_status IN ('HIGH', 'CRITICAL')

-- Summary statistics
SELECT
  appName,
  SUM(total_batches_queued) as total_queue_depth,
  AVG(avg_integration_time_ms) as avg_integration_ms,
  AVG(avg_batch_size_mb) as avg_batch_mb
FROM `striim_watcher_metadata.looker_batch_processing`
GROUP BY appName
```

**Visualization Recommendations**:
- **Bar Chart**: Queue depth by target
- **Line Chart**: Integration time trends
- **Gauge**: Upload success rate
- **Table**: Detailed batch metrics
- **Filters**: clusterName, appName, queue_health_status

**Key Metrics**:
- Total batches queued across all targets
- Average integration time
- Upload success rate

---

### 6. Downtime Analysis

**Query**: `looker_downtime_analysis` (View)

**Purpose**: Analyze application downtime patterns for reliability and SLA reporting.

**Columns**:
- `appName` - Application name
- `nodename` - Node where app is deployed
- `clusterName` - Cluster identifier
- `total_downtime_transitions` - Number of up/down transitions
- `longest_downtime_minutes` / `longest_downtime_hours` - Longest outage duration
- `longest_downtime_start` / `longest_downtime_end` - Longest outage timestamps
- `most_recent_downtime_start` / `most_recent_downtime_end` - Most recent outage timestamps
- `most_recent_downtime_minutes` / `most_recent_downtime_hours` - Most recent outage duration
- `minutes_since_last_downtime` / `hours_since_last_downtime` / `days_since_last_downtime` - Time since recovery
- `currently_down` - Whether app is currently down
- `stability_score` - Score 0-100 (higher is more stable)
- `reliability_status` - Status: STABLE, MOSTLY_STABLE, OCCASIONAL_ISSUES, UNSTABLE, CURRENTLY_DOWN

**Usage in Looker**:
```sql
-- All apps by stability
SELECT * FROM `striim_watcher_metadata.looker_downtime_analysis`
ORDER BY stability_score, total_downtime_transitions DESC

-- Currently down apps
SELECT * FROM `striim_watcher_metadata.looker_downtime_analysis`
WHERE currently_down = TRUE

-- Unstable apps requiring attention
SELECT * FROM `striim_watcher_metadata.looker_downtime_analysis`
WHERE reliability_status IN ('UNSTABLE', 'OCCASIONAL_ISSUES')
```

**Visualization Recommendations**:
- **Pie Chart**: Apps by reliability_status
- **Bar Chart**: Downtime transitions by app
- **Table**: Detailed downtime metrics
- **KPI Tiles**: Average stability score, apps currently down
- **Filters**: clusterName, reliability_status

**Key Metrics**:
- Average stability score across all apps
- Apps with > 5 downtime transitions
- Longest single outage

---

### 7. Throughput Trends

**Query**: `looker_throughput_trends(days_back)` (Table Function)

**Purpose**: Visualize source and target throughput over time for capacity planning and performance analysis.

**Parameters**:
- `days_back` - Number of days of history (default 7)

**Columns**:
- `clusterName` - Cluster identifier
- `batchdate` - Monitoring snapshot timestamp
- `batch_hour` - Hour-level timestamp for aggregation
- `total_source_input_rate` - Combined input rate from all sources
- `total_target_output_rate` - Combined output rate to all targets
- `avg_source_cpu_rate` - Average CPU across sources
- `avg_target_cpu_rate` - Average CPU across targets
- `source_count` - Number of active sources
- `target_count` - Number of active targets
- `avg_source_freshness_minutes` - Average source freshness

**Usage in Looker**:
```sql
-- Last 7 days of throughput
SELECT * FROM `striim_watcher_metadata.looker_throughput_trends`(7)
ORDER BY batchdate

-- Hourly aggregation for smoother trends
SELECT
  batch_hour,
  AVG(total_source_input_rate) as avg_source_rate,
  AVG(total_target_output_rate) as avg_target_rate,
  AVG(avg_source_freshness_minutes) as avg_freshness
FROM `striim_watcher_metadata.looker_throughput_trends`(14)
GROUP BY batch_hour
ORDER BY batch_hour

-- Peak throughput analysis
SELECT
  DATE(batchdate) as report_date,
  MAX(total_source_input_rate) as peak_source_rate,
  MAX(total_target_output_rate) as peak_target_rate
FROM `striim_watcher_metadata.looker_throughput_trends`(30)
GROUP BY report_date
ORDER BY report_date
```

**Visualization Recommendations**:
- **Dual-Axis Line Chart**: Source input vs target output over time
- **Area Chart**: Stacked throughput by cluster
- **KPI Tiles**: Current throughput, peak throughput
- **Filters**: clusterName, date range

**Key Metrics**:
- Current throughput rate
- Peak throughput in period
- Input/output ratio (indicates backlog)
- Throughput trends (increasing/decreasing)

---

### 8. Alert Trend Analysis

**Query**: `looker_alert_trends(days_back)` (Table Function)

**Purpose**: Analyze alert patterns over time for trend detection and root cause analysis.

**Parameters**:
- `days_back` - Number of days of history (default 30)

**Columns**:
- `alert_date` - Date of alerts
- `alert_type` - Type of alert (TERMINATED, BACKPRESSURE, etc.)
- `alert_count` - Number of alerts of this type
- `avg_duration_minutes` - Average duration of alerts
- `max_duration_minutes` - Maximum duration of alerts
- `unique_apps_affected` - Number of unique apps with this alert type

**Usage in Looker**:
```sql
-- Last 30 days of alert trends
SELECT * FROM `striim_watcher_metadata.looker_alert_trends`(30)
ORDER BY alert_date DESC, alert_count DESC

-- Daily alert summary
SELECT
  alert_date,
  SUM(alert_count) as total_alerts,
  COUNT(DISTINCT alert_type) as alert_types,
  SUM(unique_apps_affected) as apps_affected
FROM `striim_watcher_metadata.looker_alert_trends`(30)
GROUP BY alert_date
ORDER BY alert_date

-- Most common alert types
SELECT
  alert_type,
  SUM(alert_count) as total_occurrences,
  AVG(avg_duration_minutes) as avg_duration,
  SUM(unique_apps_affected) as total_apps_affected
FROM `striim_watcher_metadata.looker_alert_trends`(30)
GROUP BY alert_type
ORDER BY total_occurrences DESC
```

**Visualization Recommendations**:
- **Stacked Area Chart**: Alert counts by type over time
- **Bar Chart**: Most common alert types
- **Line Chart**: Alert trend (7-day rolling average)
- **Table**: Detailed daily breakdown
- **Filters**: alert_type, date range

**Key Metrics**:
- Total alerts per day/week
- Most common alert types
- Alert frequency trend (increasing/decreasing)
- Apps with most alerts

