# LookML Examples for StriimWatcher Dashboards

This guide provides LookML model and view definitions for integrating StriimWatcher queries into Looker.

## Connection Setup

### 1. Create BigQuery Connection

In Looker Admin > Connections, create a connection with:
- **Name**: `striim_watcher_bq`
- **Dialect**: Google BigQuery Standard SQL
- **Project**: Your GCP project ID
- **Dataset**: `striim_watcher_metadata`
- **Service Account**: JSON key with BigQuery Data Viewer permissions

### 2. Create LookML Project

```lookml
# manifest.lkml
project_name: "striim_watcher"

# Use local_dependency for development
# local_dependency: {
#   project: "striim_watcher"
# }
```

## Model Definition

```lookml
# models/striim_watcher.model.lkml

connection: "striim_watcher_bq"

include: "/views/**/*.view.lkml"
include: "/dashboards/**/*.dashboard.lookml"

# Operational Dashboard Explores
explore: cpu_usage_per_app {
  from: looker_cpu_usage_per_app
  label: "CPU Usage Per App"
  description: "Monitor CPU consumption by application"
}

explore: app_failures {
  from: looker_app_failure_list
  label: "App Failures"
  description: "Track application failures over time"
  
  # Enable drill-down to logs
  join: failure_logs {
    from: looker_app_failure_drilldown
    sql_on: ${app_failures.appName} = ${failure_logs.appName}
            AND ${app_failures.batchdate} = ${failure_logs.failure_batchdate} ;;
    relationship: one_to_many
    type: left_outer
  }
}

explore: smart_alerts {
  from: looker_smart_alert_history
  label: "Smart Alert History"
  description: "WARN level alerts for proactive monitoring"
}

explore: files_open {
  from: looker_files_open_list
  label: "Files Open List"
  description: "CDC files currently being processed"
}

# Leadership Dashboard Explores
explore: lag_metrics {
  from: looker_lag_graph
  label: "Lag Metrics"
  description: "End-to-end lag with rolling averages"
}

explore: data_flow {
  from: looker_data_flowing_graph
  label: "Data Flow Metrics"
  description: "Throughput and data flow rates"
}

explore: apps_down {
  from: looker_apps_down_count
  label: "Apps Down"
  description: "Applications in HALTED or TERMINATED state"
}

# New Operational Dashboard Explores
explore: backpressure_status {
  from: looker_backpressure_status
  label: "Backpressure Status"
  description: "Applications currently experiencing backpressure"
}

explore: checkpoint_health {
  from: looker_checkpoint_health
  label: "Checkpoint Health"
  description: "Checkpoint status for recovery-enabled applications"
}

explore: source_freshness {
  from: looker_source_freshness
  label: "Source Freshness"
  description: "Source data freshness and lag metrics"
}

explore: unified_alerts {
  from: looker_unified_alerts
  label: "Unified Alerts"
  description: "All active alerts with priority ranking"
}

explore: node_resources {
  from: looker_node_resources
  label: "Node Resources"
  description: "Cluster node CPU and memory utilization"
}

explore: oracle_open_trx {
  from: looker_oracle_open_trx
  label: "Oracle Open Transactions"
  description: "Open Oracle transactions for CDC sources"
}

# New Leadership Dashboard Explores
explore: data_integrity {
  from: looker_data_integrity
  label: "Data Integrity"
  description: "Source vs target data synchronization status"
}

explore: batch_processing {
  from: looker_batch_processing
  label: "Batch Processing"
  description: "Data warehouse batch processing metrics"
}

explore: downtime_analysis {
  from: looker_downtime_analysis
  label: "Downtime Analysis"
  description: "Application downtime patterns and reliability"
}

explore: throughput_trends {
  from: looker_throughput_trends
  label: "Throughput Trends"
  description: "Source and target throughput over time"
}

explore: alert_trends {
  from: looker_alert_trends
  label: "Alert Trends"
  description: "Alert frequency and patterns over time"
}
```

## View Definitions

### CPU Usage Per App (View)

```lookml
# views/looker_cpu_usage_per_app.view.lkml

view: looker_cpu_usage_per_app {
  sql_table_name: `striim_watcher_metadata.looker_cpu_usage_per_app` ;;

  dimension: cluster_name {
    type: string
    sql: ${TABLE}.clusterName ;;
    label: "Cluster"
  }

  dimension_group: batch {
    type: time
    timeframes: [raw, time, date, week, month]
    sql: ${TABLE}.batchdate ;;
    label: "Snapshot"
  }

  dimension: app_name {
    type: string
    sql: ${TABLE}.appname ;;
    label: "Application"
    link: {
      label: "View App Details"
      url: "/dashboards/app_detail?appName={{ value }}"
    }
  }

  dimension: node_name {
    type: string
    sql: ${TABLE}.nodename ;;
    label: "Node"
  }

  measure: cpu_rate {
    type: average
    sql: ${TABLE}.cpurate ;;
    label: "CPU Rate"
    value_format: "0.00"
    drill_fields: [app_name, cpu_rate, rate, sourcerate]
  }

  measure: processing_rate {
    type: average
    sql: ${TABLE}.rate ;;
    label: "Processing Rate"
    value_format: "#,##0"
  }

  measure: source_rate {
    type: average
    sql: ${TABLE}.sourcerate ;;
    label: "Source Rate"
    value_format: "#,##0"
  }

  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }

  dimension_group: latest_activity {
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.latestActivity ;;
  }
}
```

### App Failure List (Table Function)

```lookml
# views/looker_app_failure_list.view.lkml

view: looker_app_failure_list {
  # Table function with parameter
  derived_table: {
    sql: SELECT * FROM `striim_watcher_metadata.looker_app_failure_list`(
           {% parameter days_back %}
         ) ;;
  }

  parameter: days_back {
    type: number
    default_value: "30"
    allowed_value: {
      label: "Last 24 Hours"
      value: "1"
    }
    allowed_value: {
      label: "Last 7 Days"
      value: "7"
    }
    allowed_value: {
      label: "Last 30 Days"
      value: "30"
    }
  }

  dimension: cluster_name {
    type: string
    sql: ${TABLE}.clusterName ;;
  }

  dimension_group: failure {
    type: time
    timeframes: [raw, time, date, hour]
    sql: ${TABLE}.failure_time ;;
    label: "Failure Time"
  }

  dimension: app_name {
    type: string
    sql: ${TABLE}.appName ;;
    primary_key: yes
  }

  dimension: app_status {
    type: string
    sql: ${TABLE}.appStatus ;;
  }

  measure: duration_down_hours {
    type: average
    sql: ${TABLE}.duration_terminated_minutes / 60.0 ;;
    value_format: "0.00"
    label: "Avg Hours Down"
  }

  measure: failure_count {
    type: count
    label: "Failed Apps"
    drill_fields: [app_name, failure_time, duration_down_hours]
  }
}
```

### Lag Graph (Table Function)

```lookml
# views/looker_lag_graph.view.lkml

view: looker_lag_graph {
  derived_table: {
    sql: SELECT * FROM `striim_watcher_metadata.looker_lag_graph`(
           {% parameter days_back %},
           {% parameter filter_app_name %},
           {% parameter filter_source_type %},
           {% parameter filter_target_type %}
         ) ;;
  }

  parameter: days_back {
    type: number
    default_value: "30"
  }

  parameter: filter_app_name {
    type: string
    default_value: "NULL"
  }

  parameter: filter_source_type {
    type: string
    default_value: "NULL"
  }

  parameter: filter_target_type {
    type: string
    default_value: "NULL"
  }

  dimension_group: batch {
    type: time
    timeframes: [raw, time, date, hour]
    sql: ${TABLE}.batchdate ;;
  }

  dimension: app_name {
    type: string
    sql: ${TABLE}.appName ;;
  }

  dimension: source_type {
    type: string
    sql: ${TABLE}.sourceType ;;
  }

  dimension: target_type {
    type: string
    sql: ${TABLE}.targetType ;;
  }

  measure: current_lag_avg {
    type: average
    sql: ${TABLE}.current_lag ;;
    label: "Current Lag (ms)"
    value_format: "#,##0.00"
  }

  measure: rolling_avg_7day {
    type: average
    sql: ${TABLE}.rolling_avg_7day ;;
    label: "7-Day Rolling Avg (ms)"
    value_format: "#,##0.00"
  }

  measure: max_lag {
    type: max
    sql: ${TABLE}.max_lag ;;
    label: "Max Lag (ms)"
  }
}
```

### Data Flowing Graph (Table Function)

```lookml
# views/looker_data_flowing_graph.view.lkml

view: looker_data_flowing_graph {
  derived_table: {
    sql: SELECT * FROM `striim_watcher_metadata.looker_data_flowing_graph`(
           {% parameter days_back %}
         ) ;;
  }

  parameter: days_back {
    type: number
    default_value: "7"
  }

  dimension_group: batch {
    type: time
    timeframes: [raw, time, date, hour]
    sql: ${TABLE}.batchdate ;;
  }

  measure: total_input_cumulative {
    type: sum
    sql: ${TABLE}.total_input_cumulative ;;
    label: "Total Input (Cumulative)"
    value_format: "#,##0"
  }

  measure: total_output_cumulative {
    type: sum
    sql: ${TABLE}.total_output_cumulative ;;
    label: "Total Output (Cumulative)"
    value_format: "#,##0"
  }

  measure: total_input_rate {
    type: sum
    sql: ${TABLE}.total_input_rate ;;
    label: "Input Rate (Records/Batch)"
    value_format: "#,##0"
  }

  measure: total_output_rate {
    type: sum
    sql: ${TABLE}.total_output_rate ;;
    label: "Output Rate (Records/Batch)"
    value_format: "#,##0"
  }

  measure: running_apps_count {
    type: average
    sql: ${TABLE}.running_apps_count ;;
    label: "Running Apps"
    value_format: "0"
  }
}
```

### Backpressure Status (View)

```lookml
# views/looker_backpressure_status.view.lkml

view: looker_backpressure_status {
  sql_table_name: `striim_watcher_metadata.looker_backpressure_status` ;;

  dimension: cluster_name {
    type: string
    sql: ${TABLE}.clusterName ;;
    label: "Cluster"
  }

  dimension_group: batch {
    type: time
    timeframes: [raw, time, date, hour]
    sql: ${TABLE}.batchdate ;;
  }

  dimension: app_name {
    type: string
    sql: ${TABLE}.appName ;;
    label: "Application"
    primary_key: yes
  }

  dimension: node_name {
    type: string
    sql: ${TABLE}.nodename ;;
    label: "Node"
  }

  dimension: is_backpressured {
    type: yesno
    sql: ${TABLE}.isBackpressured ;;
  }

  dimension_group: backpressure_started {
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.backpressure_started ;;
  }

  measure: duration_backpressured_hours {
    type: average
    sql: ${TABLE}.duration_backpressured_hours ;;
    label: "Avg Hours Backpressured"
    value_format: "0.00"
  }

  measure: backpressured_count {
    type: count
    label: "Backpressured Apps"
  }
}
```

### Source Freshness (View)

```lookml
# views/looker_source_freshness.view.lkml

view: looker_source_freshness {
  sql_table_name: `striim_watcher_metadata.looker_source_freshness` ;;

  dimension: cluster_name {
    type: string
    sql: ${TABLE}.clusterName ;;
  }

  dimension: app_name {
    type: string
    sql: ${TABLE}.appName ;;
  }

  dimension: component_name {
    type: string
    sql: ${TABLE}.componentName ;;
    primary_key: yes
  }

  dimension: source_freshness_minutes {
    type: number
    sql: ${TABLE}.sourceFreshnessMinutes ;;
  }

  dimension: freshness_status {
    type: string
    sql: ${TABLE}.freshness_status ;;
  }

  dimension: freshness_severity {
    type: number
    sql: ${TABLE}.freshness_severity ;;
  }

  measure: avg_freshness_minutes {
    type: average
    sql: ${TABLE}.sourceFreshnessMinutes ;;
    label: "Avg Freshness (min)"
  }

  measure: max_freshness_minutes {
    type: max
    sql: ${TABLE}.sourceFreshnessMinutes ;;
    label: "Max Freshness (min)"
  }

  measure: source_count {
    type: count_distinct
    sql: ${TABLE}.componentName ;;
    label: "Sources"
  }
}
```

### Unified Alerts (View)

```lookml
# views/looker_unified_alerts.view.lkml

view: looker_unified_alerts {
  sql_table_name: `striim_watcher_metadata.looker_unified_alerts` ;;

  dimension: cluster_name {
    type: string
    sql: ${TABLE}.clusterName ;;
  }

  dimension: app_name {
    type: string
    sql: ${TABLE}.appName ;;
  }

  dimension: alert_type {
    type: string
    sql: ${TABLE}.alert_type ;;
  }

  dimension: alert_category {
    type: string
    sql: ${TABLE}.alert_category ;;
  }

  dimension: severity {
    type: string
    sql: ${TABLE}.severity ;;
  }

  dimension: duration_hours {
    type: number
    sql: ${TABLE}.duration_hours ;;
  }

  measure: alert_count {
    type: count
    label: "Total Alerts"
  }

  measure: critical_count {
    type: count
    filters: [severity: "CRITICAL"]
    label: "Critical Alerts"
  }

  measure: high_count {
    type: count
    filters: [severity: "HIGH"]
    label: "High Alerts"
  }
}
```

### Data Integrity (View)

```lookml
# views/looker_data_integrity.view.lkml

view: looker_data_integrity {
  sql_table_name: `striim_watcher_metadata.looker_data_integrity` ;;

  dimension: cluster_name {
    type: string
    sql: ${TABLE}.clusterName ;;
  }

  dimension: app_name {
    type: string
    sql: ${TABLE}.appName ;;
  }

  dimension: source_name {
    type: string
    sql: ${TABLE}.sourceName ;;
  }

  dimension: target_name {
    type: string
    sql: ${TABLE}.targetName ;;
    primary_key: yes
  }

  dimension: sync_status {
    type: string
    sql: ${TABLE}.sync_status ;;
  }

  dimension: sync_severity {
    type: number
    sql: ${TABLE}.sync_severity ;;
  }

  measure: total_difference {
    type: sum
    sql: ${TABLE}.total_difference ;;
    label: "Total Drift"
  }

  measure: tables_in_sync {
    type: count
    filters: [sync_status: "IN_SYNC"]
    label: "Tables In Sync"
  }

  measure: tables_with_drift {
    type: count
    filters: [sync_status: "-IN_SYNC"]
    label: "Tables With Drift"
  }
}
```

### Batch Processing (View)

```lookml
# views/looker_batch_processing.view.lkml

view: looker_batch_processing {
  sql_table_name: `striim_watcher_metadata.looker_batch_processing` ;;

  dimension: cluster_name {
    type: string
    sql: ${TABLE}.clusterName ;;
  }

  dimension: app_name {
    type: string
    sql: ${TABLE}.appName ;;
  }

  dimension: target_name {
    type: string
    sql: ${TABLE}.targetName ;;
    primary_key: yes
  }

  dimension: queue_health_status {
    type: string
    sql: ${TABLE}.queue_health_status ;;
  }

  dimension: integration_speed_status {
    type: string
    sql: ${TABLE}.integration_speed_status ;;
  }

  measure: total_batches_queued {
    type: sum
    sql: ${TABLE}.total_batches_queued ;;
    label: "Batches Queued"
  }

  measure: avg_integration_time {
    type: average
    sql: ${TABLE}.avg_integration_time_ms ;;
    label: "Avg Integration Time (ms)"
  }

  measure: avg_batch_size_mb {
    type: average
    sql: ${TABLE}.avg_batch_size_mb ;;
    label: "Avg Batch Size (MB)"
  }
}
```

### Downtime Analysis (View)

```lookml
# views/looker_downtime_analysis.view.lkml

view: looker_downtime_analysis {
  sql_table_name: `striim_watcher_metadata.looker_downtime_analysis` ;;

  dimension: app_name {
    type: string
    sql: ${TABLE}.appName ;;
    primary_key: yes
  }

  dimension: cluster_name {
    type: string
    sql: ${TABLE}.clusterName ;;
  }

  dimension: reliability_status {
    type: string
    sql: ${TABLE}.reliability_status ;;
  }

  dimension: currently_down {
    type: yesno
    sql: ${TABLE}.currently_down ;;
  }

  dimension: stability_score {
    type: number
    sql: ${TABLE}.stability_score ;;
  }

  measure: avg_stability_score {
    type: average
    sql: ${TABLE}.stability_score ;;
    label: "Avg Stability Score"
  }

  measure: total_downtime_transitions {
    type: sum
    sql: ${TABLE}.total_downtime_transitions ;;
    label: "Total Downtime Events"
  }

  measure: apps_currently_down {
    type: count
    filters: [currently_down: "yes"]
    label: "Apps Currently Down"
  }
}
```

## Dashboard Examples

### Operational Dashboard

```lookml
# dashboards/operational_dashboard.dashboard.lookml

- dashboard: operational_dashboard
  title: "Striim Operational Dashboard"
  layout: newspaper

  elements:
  - name: cpu_usage_chart
    title: "CPU Usage by Application"
    model: striim_watcher
    explore: cpu_usage_per_app
    type: looker_column
    fields: [looker_cpu_usage_per_app.app_name, looker_cpu_usage_per_app.cpu_rate]
    sorts: [looker_cpu_usage_per_app.cpu_rate desc]
    limit: 20

  - name: app_failures_table
    title: "Recent App Failures"
    model: striim_watcher
    explore: app_failures
    type: looker_grid
    fields: [looker_app_failure_list.app_name,
             looker_app_failure_list.failure_time,
             looker_app_failure_list.duration_down_hours]
    sorts: [looker_app_failure_list.failure_time desc]
    limit: 50

  - name: files_open_table
    title: "Files Currently Processing"
    model: striim_watcher
    explore: files_open
    type: looker_grid
    fields: [looker_files_open_list.app_name,
             looker_files_open_list.file_name,
             looker_files_open_list.file_status,
             looker_files_open_list.minutes_since_last_update]
    sorts: [looker_files_open_list.minutes_since_last_update desc]

  # NEW DASHBOARD ELEMENTS
  - name: backpressure_kpi
    title: "Backpressured Apps"
    model: striim_watcher
    explore: backpressure_status
    type: single_value
    fields: [looker_backpressure_status.backpressured_count]

  - name: backpressure_table
    title: "Backpressure Details"
    model: striim_watcher
    explore: backpressure_status
    type: looker_grid
    fields: [looker_backpressure_status.app_name,
             looker_backpressure_status.duration_backpressured_hours,
             looker_backpressure_status.node_name]
    sorts: [looker_backpressure_status.duration_backpressured_hours desc]

  - name: checkpoint_health_chart
    title: "Checkpoint Health"
    model: striim_watcher
    explore: checkpoint_health
    type: looker_pie
    fields: [looker_checkpoint_health.checkpoint_health_status,
             looker_checkpoint_health.count]

  - name: source_freshness_heatmap
    title: "Source Freshness"
    model: striim_watcher
    explore: source_freshness
    type: looker_grid
    fields: [looker_source_freshness.app_name,
             looker_source_freshness.component_name,
             looker_source_freshness.freshness_status,
             looker_source_freshness.source_freshness_minutes]
    sorts: [looker_source_freshness.source_freshness_minutes desc]

  - name: active_alerts_table
    title: "Active Alerts"
    model: striim_watcher
    explore: unified_alerts
    type: looker_grid
    fields: [looker_unified_alerts.severity,
             looker_unified_alerts.alert_type,
             looker_unified_alerts.app_name,
             looker_unified_alerts.duration_hours]
    sorts: [looker_unified_alerts.severity]

  - name: node_resources_chart
    title: "Node CPU Usage"
    model: striim_watcher
    explore: node_resources
    type: looker_column
    fields: [looker_node_resources.node_name,
             looker_node_resources.cpu_rate]
    sorts: [looker_node_resources.cpu_rate desc]
```

### Leadership Dashboard

```lookml
# dashboards/leadership_dashboard.dashboard.lookml

- dashboard: leadership_dashboard
  title: "Striim Leadership Dashboard"
  layout: newspaper

  elements:
  - name: apps_down_kpi
    title: "Apps Down"
    model: striim_watcher
    explore: apps_down
    type: single_value
    fields: [looker_apps_down_count.app_count]

  - name: lag_trend_chart
    title: "Lag Trend with 7-Day Average"
    model: striim_watcher
    explore: lag_metrics
    type: looker_line
    fields: [looker_lag_graph.batch_date,
             looker_lag_graph.current_lag_avg,
             looker_lag_graph.rolling_avg_7day]
    sorts: [looker_lag_graph.batch_date]

  - name: data_flow_chart
    title: "Data Flow (Input vs Output)"
    model: striim_watcher
    explore: data_flow
    type: looker_line
    fields: [looker_data_flowing_graph.batch_date,
             looker_data_flowing_graph.total_input_cumulative,
             looker_data_flowing_graph.total_output_cumulative]
    sorts: [looker_data_flowing_graph.batch_date]

  # NEW DASHBOARD ELEMENTS
  - name: data_integrity_summary
    title: "Data Integrity by Sync Status"
    model: striim_watcher
    explore: data_integrity
    type: looker_pie
    fields: [looker_data_integrity.sync_status,
             looker_data_integrity.count]

  - name: data_integrity_table
    title: "Tables with Drift"
    model: striim_watcher
    explore: data_integrity
    type: looker_grid
    fields: [looker_data_integrity.app_name,
             looker_data_integrity.source_name,
             looker_data_integrity.target_name,
             looker_data_integrity.sync_status,
             looker_data_integrity.total_difference]
    filters:
      looker_data_integrity.sync_status: "-IN_SYNC"
    sorts: [looker_data_integrity.total_difference desc]

  - name: batch_processing_chart
    title: "Batch Queue Depth"
    model: striim_watcher
    explore: batch_processing
    type: looker_column
    fields: [looker_batch_processing.app_name,
             looker_batch_processing.total_batches_queued]
    sorts: [looker_batch_processing.total_batches_queued desc]

  - name: downtime_analysis_chart
    title: "Reliability Status"
    model: striim_watcher
    explore: downtime_analysis
    type: looker_pie
    fields: [looker_downtime_analysis.reliability_status,
             looker_downtime_analysis.count]

  - name: downtime_table
    title: "App Stability Analysis"
    model: striim_watcher
    explore: downtime_analysis
    type: looker_grid
    fields: [looker_downtime_analysis.app_name,
             looker_downtime_analysis.reliability_status,
             looker_downtime_analysis.stability_score,
             looker_downtime_analysis.total_downtime_transitions]
    sorts: [looker_downtime_analysis.stability_score]

  - name: stability_score_kpi
    title: "Avg Stability Score"
    model: striim_watcher
    explore: downtime_analysis
    type: single_value
    fields: [looker_downtime_analysis.avg_stability_score]
```

## Best Practices

### 1. Persistent Derived Tables (PDTs)

For expensive queries, use PDTs:

```lookml
view: lag_metrics_pdt {
  derived_table: {
    sql: SELECT * FROM `striim_watcher_metadata.looker_lag_graph`(30, NULL, NULL, NULL) ;;

    # Rebuild every hour
    sql_trigger_value: SELECT FLOOR(UNIX_SECONDS(CURRENT_TIMESTAMP()) / 3600) ;;

    # Or use datagroup
    datagroup_trigger: striim_watcher_default
  }
}
```

### 2. Datagroups

```lookml
# In model file
datagroup: striim_watcher_default {
  sql_trigger: SELECT MAX(batchdate) FROM `striim_watcher_metadata.striim_mon_table_runhistory` ;;
  max_cache_age: "1 hour"
}
```

### 3. Caching Strategy

- **Real-time views**: Cache for 5-15 minutes
- **Historical analysis**: Cache for 1-4 hours
- **PDTs**: Rebuild on datagroup trigger

## Troubleshooting

### Issue: Table function parameters not working

**Solution**: Ensure parameters are passed as literals:
```lookml
sql: SELECT * FROM function({% parameter days_back %}) ;;
```

### Issue: Slow query performance

**Solutions**:
1. Use PDTs for frequently accessed data
2. Add filters to reduce data scanned
3. Leverage BigQuery partitioning (already configured on batchdate)

### Issue: NULL values in joins

**Solution**: Use LEFT OUTER joins and COALESCE:
```lookml
sql: COALESCE(${TABLE}.nodename, 'Unknown') ;;
```
```


