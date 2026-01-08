# Operational Dashboard - Query Guide

This dashboard provides real-time operational monitoring for Striim applications, focusing on performance, failures, alerts, and file processing.

## Dashboard Components

### 1. CPU Usage Per App

**Query**: `looker_cpu_usage_per_app` (View)

**Purpose**: Monitor CPU consumption by application to identify resource-intensive apps.

**Columns**:
- `clusterName` - Striim cluster identifier
- `batchdate` - Timestamp of monitoring snapshot
- `appname` - Application name
- `nodename` - Node where app is deployed (from deploymentOn)
- `cpurate` - CPU usage rate (can exceed 100% on multi-core systems)
- `rate` - Overall processing rate
- `sourcerate` - Source data rate
- `status` - Application status
- `latestActivity` - Last activity timestamp

**Usage in Looker**:
```sql
SELECT * FROM `striim_watcher_metadata.looker_cpu_usage_per_app`
```

**Visualization Recommendations**:
- **Bar Chart**: CPU rate by app (sorted descending)
- **Table**: Detailed view with all columns
- **Filters**: clusterName, status

**Key Metrics**:
- Apps with cpurate > 100% (high CPU usage)
- Apps with no recent activity (latestActivity)

---

### 2. App Failure List

**Query**: `looker_app_failure_list(days_back)` (Table Function)

**Purpose**: Track application failures (TERMINATED status) over configurable time windows.

**Parameters**:
- `days_back` - Number of days to look back (e.g., 30, 7, 1)

**Columns**:
- `clusterName` - Cluster identifier
- `batchdate` - Latest monitoring snapshot
- `nodename` - Node where app is deployed
- `appName` - Application name
- `appStatus` - Current status (TERMINATED)
- `failure_time` - When app first became TERMINATED
- `duration_terminated_minutes` - How long app has been down
- `totalInput` - Total input count
- `totalOutput` - Total output count
- `isBackpressured` - Backpressure indicator
- `checkpointStatus` - Checkpoint status
- `latestActivity` - Last activity timestamp

**Usage in Looker**:
```sql
-- Last 30 days
SELECT * FROM `striim_watcher_metadata.looker_app_failure_list`(30)

-- Last 7 days
SELECT * FROM `striim_watcher_metadata.looker_app_failure_list`(7)

-- Last 24 hours
SELECT * FROM `striim_watcher_metadata.looker_app_failure_list`(1)
```

**Visualization Recommendations**:
- **Table**: Failure list with drill-down capability
- **Timeline**: Failures over time
- **Filters**: clusterName, nodename, time window (via parameter)

**Drill-Down**: Click on an app to see logs via `looker_app_failure_drilldown`

---

### 3. App Failure Drill-Down

**Query**: `looker_app_failure_drilldown(app_name, failure_batchdate, minutes_window)` (Table Function)

**Purpose**: Investigate root cause by viewing logs near the failure time.

**Parameters**:
- `app_name` - Application name to investigate
- `failure_batchdate` - Timestamp when failure was detected
- `minutes_window` - Minutes before/after to search (default 15)

**Columns**:
- `clusterName` - Cluster identifier
- `log_date` - When log entry was created
- `batchdate` - Monitoring snapshot timestamp
- `server` - Server that generated the log
- `appName` - Application name
- `log_level` - Log level (ERROR, WARN)
- `message` - Log message
- `contextbuffertext` - Additional context
- `minutes_from_failure` - Time offset from failure

**Usage in Looker**:
```sql
-- Investigate specific failure
SELECT * FROM `striim_watcher_metadata.looker_app_failure_drilldown`(
  'admin.MyApp',
  TIMESTAMP('2024-01-15 10:30:00'),
  15
)
ORDER BY log_date DESC
```

**Visualization Recommendations**:
- **Table**: Chronological log entries
- **Filters**: log_level
- **Sorting**: log_date DESC (most recent first)

---

### 4. Smart Alert History

**Query**: `looker_smart_alert_history(days_back)` (Table Function)

**Purpose**: Monitor WARN level alerts for proactive issue detection.

**Parameters**:
- `days_back` - Number of days to look back (default 7)

**Columns**:
- `clusterName` - Cluster identifier
- `log_date` - When alert was generated
- `batchdate` - Monitoring snapshot timestamp
- `server` - Server that generated the alert
- `appName` - Application name
- `log_level` - Log level (WARN)
- `message` - Alert message
- `contextbuffertext` - Additional context

**Usage in Looker**:
```sql
-- Last 7 days of warnings
SELECT * FROM `striim_watcher_metadata.looker_smart_alert_history`(7)
ORDER BY log_date DESC
```

**Visualization Recommendations**:
- **Table**: Alert list with search capability
- **Timeline**: Alerts over time
- **Filters**: clusterName, appName, server

---

### 5. Files Open List

**Query**: `looker_files_open_list` (View)

**Purpose**: Monitor CDC file processing status to detect stuck or slow files.

**Columns**:
- `clusterName` - Cluster identifier
- `batchdate` - Monitoring snapshot timestamp
- `nodename` - Node where app is deployed
- `appName` - Application name
- `componentName` - CDC source component
- `fileName` - File being processed
- `file_status` - Current status (PROCESSING, etc.)
- `directoryName` - File location
- `fileCreationTime` - When file was created
- `numberOfEvents` - Events in file
- `firstEventTimestamp` - First event timestamp
- `lastEventTimestamp` - Last event timestamp
- `wrapNumber` - GoldenGate wrap number
- `sequenceNumber` - File sequence number
- `minutes_since_last_update` - Time since last status update

**Usage in Looker**:
```sql
SELECT * FROM `striim_watcher_metadata.looker_files_open_list`
ORDER BY minutes_since_last_update DESC
```

**Visualization Recommendations**:
- **Table**: File list with status
- **Alert**: Files with minutes_since_last_update > threshold
- **Filters**: clusterName, appName, file_status

**Key Metrics**:
- Files stuck in PROCESSING for extended periods
- Files with high event counts

---

### 6. Backpressure Status Panel

**Query**: `looker_backpressure_status` (View)

**Purpose**: Monitor applications currently experiencing backpressure, which indicates the target cannot keep up with the source.

**Columns**:
- `clusterName` - Cluster identifier
- `batchdate` - Monitoring snapshot timestamp
- `nodename` - Node where app is deployed
- `appName` - Application name
- `appStatus` - Current application status
- `isBackpressured` - Backpressure indicator (always TRUE in this view)
- `backpressure_started` - When backpressure began
- `duration_backpressured_minutes` - Minutes in backpressure state
- `duration_backpressured_hours` - Hours in backpressure state
- `totalInput` - Total input count
- `totalOutput` - Total output count
- `checkpointStatus` - Checkpoint status
- `latestActivity` - Last activity timestamp

**Usage in Looker**:
```sql
SELECT * FROM `striim_watcher_metadata.looker_backpressure_status`
ORDER BY duration_backpressured_minutes DESC
```

**Visualization Recommendations**:
- **KPI Tile**: Count of backpressured apps
- **Table**: Detailed list with duration
- **Alert**: Apps backpressured > 10 minutes
- **Filters**: clusterName, nodename

**Key Metrics**:
- Total apps currently backpressured
- Average/max backpressure duration
- Apps newly entering backpressure state

---

### 7. Checkpoint Health Panel

**Query**: `looker_checkpoint_health` (View)

**Purpose**: Monitor checkpoint status for applications with recovery enabled to ensure data recovery is possible.

**Columns**:
- `clusterName` - Cluster identifier
- `batchdate` - Monitoring snapshot timestamp
- `nodename` - Node where app is deployed
- `appName` - Application name
- `appStatus` - Current application status
- `isRecoveryEnabled` - Recovery enabled flag
- `recoverySetting` - Recovery interval setting
- `checkpointStatus` - Checkpoint status string
- `last_checkpoint_time` - Timestamp of last checkpoint
- `minutes_since_last_checkpoint` - Time since last checkpoint
- `checkpoints_last_24h` - Checkpoint count in last 24 hours
- `checkpoints_last_hour` - Checkpoint count in last hour
- `checkpoint_health_status` - Status: HEALTHY, STALE, LAGGING, NO_CHECKPOINTS, RECOVERY_DISABLED
- `latestActivity` - Last activity timestamp

**Usage in Looker**:
```sql
SELECT * FROM `striim_watcher_metadata.looker_checkpoint_health`
WHERE checkpoint_health_status != 'HEALTHY'
ORDER BY minutes_since_last_checkpoint DESC
```

**Visualization Recommendations**:
- **Pie Chart**: Apps by checkpoint_health_status
- **Table**: Apps with STALE or LAGGING status
- **Time Series**: Checkpoint frequency over time
- **Filters**: clusterName, checkpoint_health_status

**Key Metrics**:
- Apps with stale checkpoints (> 60 minutes)
- Apps with no checkpoints recorded
- Checkpoint frequency trends

---

### 8. Source Freshness Heatmap

**Query**: `looker_source_freshness` (View)

**Purpose**: Monitor source data freshness to detect stale data ingestion at the component level.

**Columns**:
- `clusterName` - Cluster identifier
- `batchdate` - Monitoring snapshot timestamp
- `nodename` - Node where app is deployed
- `appName` - Application name
- `componentName` - Source component name
- `sourceFreshness` - Freshness string (e.g., "08H:02M:32S")
- `sourceFreshnessMinutes` - Freshness in minutes
- `readLag` - Read lag value
- `inputRate` - Source input rate
- `sourceRate` - Source event rate
- `cpuRate` - Source CPU rate
- `lastEventReadAge` - Age of last read event
- `readTimestamp` - Last read timestamp
- `latestActivity` - Last activity timestamp
- `freshness_status` - Status: FRESH, MODERATE, STALE, CRITICAL
- `freshness_severity` - Numeric severity (1-4)

**Usage in Looker**:
```sql
-- All sources by freshness
SELECT * FROM `striim_watcher_metadata.looker_source_freshness`
ORDER BY sourceFreshnessMinutes DESC

-- Only stale sources
SELECT * FROM `striim_watcher_metadata.looker_source_freshness`
WHERE freshness_status IN ('STALE', 'CRITICAL')
```

**Visualization Recommendations**:
- **Heatmap**: Sources colored by freshness_severity
- **Bar Chart**: sourceFreshnessMinutes by component
- **Table**: Detailed source metrics
- **Filters**: clusterName, appName, freshness_status

**Key Metrics**:
- Sources with freshness > 30 minutes
- Sources with high read lag
- Correlation between freshness and input rate

---

### 9. Active Alerts Panel

**Query**: `looker_unified_alerts` (View)

**Purpose**: Display all active alerts from the unified alert system with priority ranking.

**Columns**:
- `clusterName` - Cluster identifier
- `appName` - Application name (entity_name)
- `nodename` - Node where app is deployed
- `alert_type` - Type of alert (TERMINATED, BACKPRESSURE, etc.)
- `alert_trigger_time` - When alert was triggered
- `duration_of_problem_state_minutes` - Duration in minutes
- `duration_hours` - Duration in hours
- `configured_threshold_minutes` - Threshold that triggered alert
- `alert_priority` - Priority ranking (1=highest)
- `alert_category` - Category: System, Availability, Recovery, Performance, Latency
- `severity` - Severity: CRITICAL, HIGH, MEDIUM, LOW

**Usage in Looker**:
```sql
-- All current alerts
SELECT * FROM `striim_watcher_metadata.looker_unified_alerts`
ORDER BY alert_priority, duration_of_problem_state_minutes DESC

-- Critical alerts only
SELECT * FROM `striim_watcher_metadata.looker_unified_alerts`
WHERE severity = 'CRITICAL'
```

**Visualization Recommendations**:
- **KPI Tiles**: Count by severity (CRITICAL, HIGH, MEDIUM, LOW)
- **Table**: Alert list with drill-down
- **Pie Chart**: Alerts by category
- **Timeline**: Alert duration visualization
- **Filters**: clusterName, alert_type, severity

**Key Metrics**:
- Total active alerts by severity
- Average alert duration
- Most common alert types

---

### 10. Node Resource Usage Panel

**Query**: `looker_node_resources` (View)

**Purpose**: Monitor cluster node resource utilization including CPU and memory.

**Columns**:
- `clusterName` - Cluster identifier
- `batchdate` - Monitoring snapshot timestamp
- `nodename` - Node name
- `striimversion` - Striim version
- `freemem` - Free memory string
- `cpurate` - CPU usage rate
- `uptime` - Node uptime
- `freemem_gb` - Free memory in GB (parsed)
- `cpu_health_status` - Status: HEALTHY, MODERATE, HIGH, CRITICAL
- `memory_health_status` - Status: HEALTHY, MODERATE, LOW

**Usage in Looker**:
```sql
SELECT * FROM `striim_watcher_metadata.looker_node_resources`
ORDER BY cpurate DESC

-- Nodes with resource concerns
SELECT * FROM `striim_watcher_metadata.looker_node_resources`
WHERE cpu_health_status IN ('HIGH', 'CRITICAL')
   OR memory_health_status = 'LOW'
```

**Visualization Recommendations**:
- **Gauge Charts**: CPU and memory per node
- **Bar Chart**: CPU rate by node
- **Table**: All node metrics
- **Filters**: clusterName, cpu_health_status

**Key Metrics**:
- Nodes with CPU > 80%
- Nodes with low free memory
- Node uptime for stability analysis

---

### 11. Oracle Open Transactions Panel

**Query**: `looker_oracle_open_trx` (View)

**Purpose**: Monitor open Oracle transactions for CDC sources (Oracle-specific). Long-running transactions can cause memory issues and lag.

**Columns**:
- `clusterName` - Cluster identifier
- `batchdate` - Monitoring snapshot timestamp
- `nodename` - Node where app is deployed
- `appName` - Application name
- `componentName` - Source component name
- `transactionId` - Oracle transaction ID
- `numOfOps` - Operations in transaction
- `sequenceNum` - Transaction sequence number
- `startscn` - Start SCN
- `rbaBlock` - RBA block
- `threadNum` - Oracle thread number
- `transaction_start_time` - When transaction started
- `transaction_age_minutes` - Age in minutes
- `transaction_age_hours` - Age in hours
- `transaction_status` - Status: NORMAL, AGED, LONG_RUNNING

**Usage in Looker**:
```sql
-- All open transactions
SELECT * FROM `striim_watcher_metadata.looker_oracle_open_trx`
ORDER BY transaction_age_minutes DESC

-- Long-running transactions only
SELECT * FROM `striim_watcher_metadata.looker_oracle_open_trx`
WHERE transaction_status = 'LONG_RUNNING'
```

**Visualization Recommendations**:
- **KPI Tile**: Count of open transactions
- **Table**: Transaction details with age
- **Alert**: Transactions > 2 hours old
- **Filters**: clusterName, appName, transaction_status

**Key Metrics**:
- Count of long-running transactions (> 2 hours)
- Oldest transaction age
- Transaction count per application

