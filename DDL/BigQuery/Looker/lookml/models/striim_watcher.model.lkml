connection: "striim_watcher_bq"

include: "/views/**/*.view.lkml"
include: "/dashboards/**/*.dashboard.lookml"

# Caching configuration - refresh when new data arrives
datagroup: striim_watcher_default {
  sql_trigger: SELECT MAX(batchdate) FROM `striim_watcher_metadata.striim_mon_table_runhistory` ;;
  max_cache_age: "1 hour"
}

persist_with: striim_watcher_default

# ============================================
# OPERATIONAL DASHBOARD EXPLORES
# ============================================

explore: cpu_usage_per_app {
  from: looker_cpu_usage_per_app
  label: "CPU Usage Per App"
  description: "Monitor CPU consumption by application"
}

explore: app_failures {
  from: looker_app_failure_list
  label: "App Failures"
  description: "Track application failures over time"
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

# ============================================
# LEADERSHIP DASHBOARD EXPLORES
# ============================================

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
