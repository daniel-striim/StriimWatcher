# Dashboard Expansion Recommendations

This document outlines potential improvements and expansions to the Looker dashboards based on a comprehensive analysis of all available BigQuery tables, existing alert functions, and Java data collection code.

## Executive Summary

After reviewing **17 tables**, **11 existing alert functions**, and the Java StriimWatcher code, I've identified significant opportunities to enhance both the Operational and Leadership dashboards with additional metrics that are already being collected but not yet exposed.

---

## Available Data Not Currently Used in Dashboards

### 1. Source/Target Performance Metrics (HIGH VALUE)

**Tables**: `striim_mon_source_information`, `striim_mon_target_information`

| Metric | Description | Dashboard Fit |
|--------|-------------|---------------|
| `sourceFreshnessMinutes` | How stale the source data is | Operational |
| `readLag` | How far behind the source is from DB | Operational & Leadership |
| `inputRate` / `sourceRate` | Source throughput rate | Leadership |
| `cpuRate` (per source/target) | CPU usage by component | Operational |
| `lastEventReadAge` | Staleness indicator | Operational |
| `accepted` (target) | Events accepted by target | Leadership |
| `lag` (target) | Target-side lag measurement | Leadership |

**Recommendation**: Create source/target health dashboards showing freshness, lag, and throughput at the component level (more granular than app-level).

---

### 2. Data Warehouse Target Metrics (HIGH VALUE)

**Table**: `striim_mon_datawarehouse_detail`

| Metric | Description | Dashboard Fit |
|--------|-------------|---------------|
| `total_batches_queued` | Batches waiting to be processed | Operational (already in alerts) |
| `avg_batch_size_bytes` | Average batch size | Leadership |
| `avg_integration_time_ms` | Average time to integrate batches | Leadership |
| `avg_waiting_time_in_queue_ms` | Queue wait time | Operational |
| `last_batch_total_integration_time_ms` | Most recent batch timing | Operational |
| `total_batches_created` vs `total_batches_uploaded` | Processing pipeline health | Leadership |
| `optimizedMerge` / `streamingUpload` | Configuration flags | Operational |

**Recommendation**: Create a BigQuery Target Performance dashboard showing batch processing health, queue depth trends, and integration times.

---

### 3. Table Comparison / Data Integrity (HIGH VALUE)

**Tables**: `striim_mon_table_comparison`, `striim_mon_table_comparison_sli`

| Metric | Description | Dashboard Fit |
|--------|-------------|---------------|
| `diffNumOfInserts` | Insert count difference (source vs target) | Leadership |
| `diffNumOfUpdates` | Update count difference | Leadership |
| `diffNumOfDeletes` | Delete count difference | Leadership |
| `diffNumOfDdls` | DDL difference | Operational |
| `diffNumOfPkupdates` | PK update difference | Operational |
| `*_sli` variants | Incremental changes since last batch | Operational |

**Recommendation**: Create a Data Integrity dashboard showing source-target synchronization status and drift detection.

---

### 4. Checkpoint History (MEDIUM VALUE)

**Table**: `striim_mon_checkpoint_history`

| Metric | Description | Dashboard Fit |
|--------|-------------|---------------|
| `checkpointRecordedTime` | When checkpoints were taken | Operational |
| `sourcePositionSummary` | Source position at checkpoint | Operational |
| `targetPositionSummary` | Target position at checkpoint | Operational |
| Checkpoint frequency | Derived: checkpoints per hour | Leadership |

**Recommendation**: Add checkpoint health visualization showing checkpoint progression and frequency.

---

### 5. Oracle-Specific Metrics (MEDIUM VALUE)

**Table**: `striim_mon_oracle_open_trx`

| Metric | Description | Dashboard Fit |
|--------|-------------|---------------|
| `numOfOps` | Operations in open transaction | Operational |
| `montimestamp` | How old the transaction is | Operational |
| Open transaction count | Count of open transactions | Leadership |

**Recommendation**: For Oracle CDC sources, show open transaction monitoring to detect long-running transactions that could cause issues.

---

### 6. System Resource Metrics (MEDIUM VALUE)

**Tables**: `striim_mon_node_cluster`, `striim_mon_system_configuration`

| Metric | Description | Dashboard Fit |
|--------|-------------|---------------|
| `freemem` | Free memory on nodes | Operational |
| `cpurate` (node level) | Node CPU usage | Operational |
| `uptime` | Node uptime | Operational |
| Memory metrics | JVM and physical memory | Operational |
| Disk space metrics | Filesystem usage | Operational |

**Recommendation**: Create a Cluster Health dashboard showing node-level resource utilization.

---

### 7. File Lineage Enhanced (MEDIUM VALUE)

**Table**: `striim_mon_file_lineage` (already used, but can be enhanced)

| Metric | Description | Dashboard Fit |
|--------|-------------|---------------|
| File processing rate | Files completed per hour | Leadership |
| `numberOfEvents` per file | Events per file trending | Leadership |
| File age (`fileCreationTime`) | How old files are being processed | Operational |

---

### 8. Elasticsearch Metrics (LOW VALUE unless ES is used)

**Table**: `striim_mon_node_elasticsearch`

| Metric | Description | Dashboard Fit |
|--------|-------------|---------------|
| `elasticsearchReceiveThroughput` | ES receive rate | Operational |
| `elasticsearchTransmitThroughput` | ES transmit rate | Operational |
| `elasticsearchClusterStorageFree` | ES storage | Operational |

---

## Existing Alert Functions to Leverage

The following alert functions already exist and can be integrated into Looker:

| Function | Description | Dashboard Fit |
|----------|-------------|---------------|
| `get_backpressure_alerts()` | Apps with sustained backpressure | Operational |
| `get_checkpoint_alerts()` | Checkpoint not progressing | Operational |
| `get_high_lee_alerts()` | High end-to-end latency | Leadership |
| `get_sourceidle_alerts()` | Source inactivity | Operational |
| `get_queuedbatches_alerts()` | Excessive batch queuing | Operational |
| `get_largebatches_alerts()` | Oversized batches | Operational |
| `get_striimwatcher_silence_alerts()` | StriimWatcher not running | Operational |
| `get_app_downtime_analysis()` | Downtime patterns | Leadership |
| `generate_unified_alerts()` | Combined alert view | Both |

**Recommendation**: Create an Alert Summary dashboard that shows all active alerts from `generate_unified_alerts()` with drill-down capability.

---

## Proposed Dashboard Enhancements

### Dashboard 1: Operational Dashboard (Enhanced)

**Add these components:**

1. **Backpressure Status Panel** ✨
   - Current backpressured apps
   - Duration of backpressure
   - Source: `striim_mon_appdetail.isBackpressured`

2. **Checkpoint Health Panel** ✨
   - Apps with checkpoint issues
   - Last checkpoint time per app
   - Source: `striim_mon_appdetail.checkpointStatus`, `striim_mon_checkpoint_history`

3. **Source Freshness Heatmap** ✨
   - Color-coded freshness by source
   - Alert when stale > threshold
   - Source: `striim_mon_source_information.sourceFreshnessMinutes`

4. **Active Alerts Panel** ✨
   - Unified view of all current alerts
   - Source: `generate_unified_alerts()`

5. **Node Resource Usage** ✨
   - Memory and CPU per node
   - Source: `striim_mon_node_cluster`

6. **Oracle Open Transactions** ✨ (for Oracle CDC users)
   - Count and age of open transactions
   - Source: `striim_mon_oracle_open_trx`

---

### Dashboard 2: Leadership Dashboard (Enhanced)

**Add these components:**

1. **Data Integrity Summary** ✨
   - Source vs Target row count comparison
   - Drift detection (inserts/updates/deletes mismatch)
   - Source: `striim_mon_table_comparison`

2. **Batch Processing Efficiency** ✨
   - Average batch size trends
   - Integration time trends
   - Queue depth trends
   - Source: `striim_mon_datawarehouse_detail`

3. **Downtime Analysis** ✨
   - Total downtime transitions per app
   - Longest outage duration
   - Time since last downtime
   - Source: `get_app_downtime_analysis()`

4. **Throughput Trends** ✨
   - Source input rate over time
   - Target output rate over time
   - Source: `striim_mon_source_information`, `striim_mon_target_information`

5. **Alert Trend Analysis** ✨
   - Alert frequency over time
   - Most common alert types
   - Source: Historical alert data

---

## Implementation Priority

### Phase 1: Quick Wins (1-2 days)
- [ ] Add backpressure status to Operational dashboard
- [ ] Add unified alerts panel using `generate_unified_alerts()`
- [ ] Add checkpoint health indicators

### Phase 2: High Value Additions (3-5 days)
- [ ] Create Data Integrity dashboard with source/target comparison
- [ ] Add batch processing metrics from `striim_mon_datawarehouse_detail`
- [ ] Add source freshness heatmap

### Phase 3: Advanced Analytics (1-2 weeks)
- [ ] Implement downtime analysis dashboard
- [ ] Add throughput trending with forecasting
- [ ] Create cluster health monitoring
- [ ] Add Oracle-specific monitoring (if applicable)

---

## LookML Views to Create

Based on the analysis, these new LookML views would be valuable:

```
1. source_information.view.lkml
   - Based on: striim_mon_source_information
   - Key measures: avg_freshness, max_read_lag, total_input_rate

2. target_information.view.lkml
   - Based on: striim_mon_target_information
   - Key measures: avg_lag, total_accepted, avg_cpu_rate

3. datawarehouse_detail.view.lkml
   - Based on: striim_mon_datawarehouse_detail
   - Key measures: avg_batch_size, avg_integration_time, queue_depth

4. table_comparison.view.lkml
   - Based on: striim_mon_table_comparison
   - Key measures: total_diff_inserts, total_diff_updates, sync_status

5. unified_alerts.view.lkml
   - Based on: generate_unified_alerts() function
   - Key measures: alert_count, avg_duration, alerts_by_type

6. checkpoint_history.view.lkml
   - Based on: striim_mon_checkpoint_history
   - Key measures: checkpoint_frequency, last_checkpoint_age

7. node_cluster.view.lkml
   - Based on: striim_mon_node_cluster
   - Key measures: avg_cpu, avg_memory_free, node_count
```

---

## Sample Queries for New Metrics

### Source Freshness Query
```sql
SELECT
  appName,
  componentName,
  sourceFreshnessMinutes,
  readLag,
  inputRate,
  batchdate
FROM `mon.striim_mon_source_information`
WHERE batchdate = (SELECT MAX(batchdate) FROM `mon.striim_mon_table_runhistory`)
ORDER BY sourceFreshnessMinutes DESC
```

### Batch Processing Health Query
```sql
SELECT
  appName,
  total_batches_queued,
  avg_batch_size_bytes / 1048576 as avg_batch_size_mb,
  avg_integration_time_ms,
  avg_waiting_time_in_queue_ms,
  batchdate
FROM `mon.striim_mon_datawarehouse_detail`
WHERE batchdate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
ORDER BY batchdate DESC
```

### Data Integrity Check Query
```sql
SELECT
  appName,
  SUM(diffNumOfInserts) as total_insert_diff,
  SUM(diffNumOfUpdates) as total_update_diff,
  SUM(diffNumOfDeletes) as total_delete_diff,
  CASE
    WHEN SUM(ABS(diffNumOfInserts) + ABS(diffNumOfUpdates) + ABS(diffNumOfDeletes)) = 0
    THEN 'IN_SYNC'
    ELSE 'DRIFT_DETECTED'
  END as sync_status
FROM `mon.striim_mon_table_comparison`
WHERE batchdate = (SELECT MAX(batchdate) FROM `mon.striim_mon_table_runhistory`)
GROUP BY appName
```

---

## Conclusion

The StriimWatcher data collection is comprehensive, but the current Looker dashboards only expose a fraction of the available metrics. By implementing the recommendations above, you can:

1. **Improve operational visibility** with source freshness, backpressure, and checkpoint monitoring
2. **Enhance leadership reporting** with data integrity, throughput trends, and downtime analysis
3. **Enable proactive alerting** by surfacing the existing alert functions in Looker
4. **Provide deeper insights** into batch processing, queue health, and system resources

The data is already being collected - it just needs to be exposed through Looker views and dashboards.

