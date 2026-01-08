- dashboard: operational_dashboard
  title: "StriimWatcher Operational Dashboard"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Real-time operational monitoring for Striim CDC pipelines"
  
  filters:
  - name: cluster_filter
    title: "Cluster"
    type: field_filter
    default_value: ""
    allow_multiple_values: true
    required: false
    ui_config:
      type: tag_list
      display: popover
    explore: cpu_usage_per_app
    field: looker_cpu_usage_per_app.cluster_name

  - name: date_filter
    title: "Date Range"
    type: date_filter
    default_value: "24 hours"
    allow_multiple_values: true
    required: false

  elements:
  # Row 1: KPI Tiles
  - title: "Critical Alerts"
    name: critical_alerts_tile
    model: striim_watcher
    explore: unified_alerts
    type: single_value
    fields: [looker_unified_alerts.critical_count]
    listen:
      cluster_filter: looker_unified_alerts.cluster_name
    row: 0
    col: 0
    width: 4
    height: 3

  - title: "Apps Down"
    name: apps_down_tile
    model: striim_watcher
    explore: apps_down
    type: single_value
    fields: [looker_apps_down_count.app_count]
    listen:
      cluster_filter: looker_apps_down_count.cluster_name
    row: 0
    col: 4
    width: 4
    height: 3

  - title: "Backpressure Active"
    name: backpressure_tile
    model: striim_watcher
    explore: backpressure_status
    type: single_value
    fields: [looker_backpressure_status.apps_with_backpressure]
    listen:
      cluster_filter: looker_backpressure_status.cluster_name
    row: 0
    col: 8
    width: 4
    height: 3

  - title: "Stale Checkpoints"
    name: stale_checkpoints_tile
    model: striim_watcher
    explore: checkpoint_health
    type: single_value
    fields: [looker_checkpoint_health.stale_checkpoints]
    listen:
      cluster_filter: looker_checkpoint_health.cluster_name
    row: 0
    col: 12
    width: 4
    height: 3

  - title: "Stale Sources"
    name: stale_sources_tile
    model: striim_watcher
    explore: source_freshness
    type: single_value
    fields: [looker_source_freshness.stale_sources]
    listen:
      cluster_filter: looker_source_freshness.cluster_name
    row: 0
    col: 16
    width: 4
    height: 3

  - title: "Open Oracle Transactions"
    name: oracle_trx_tile
    model: striim_watcher
    explore: oracle_open_trx
    type: single_value
    fields: [looker_oracle_open_trx.total_open_transactions]
    listen:
      cluster_filter: looker_oracle_open_trx.cluster_name
    row: 0
    col: 20
    width: 4
    height: 3

  # Row 2: Unified Alerts Table
  - title: "Active Alerts (Priority Ranked)"
    name: unified_alerts_table
    model: striim_watcher
    explore: unified_alerts
    type: looker_grid
    fields: [looker_unified_alerts.severity, looker_unified_alerts.alert_type, 
             looker_unified_alerts.app_name, looker_unified_alerts.alert_category,
             looker_unified_alerts.duration_hours, looker_unified_alerts.alert_trigger_time]
    sorts: [looker_unified_alerts.alert_priority asc]
    limit: 25
    listen:
      cluster_filter: looker_unified_alerts.cluster_name
    row: 3
    col: 0
    width: 24
    height: 8

  # Row 3: CPU Usage and Node Resources
  - title: "CPU Usage by Application"
    name: cpu_usage_chart
    model: striim_watcher
    explore: cpu_usage_per_app
    type: looker_line
    fields: [looker_cpu_usage_per_app.batch_time, looker_cpu_usage_per_app.app_name,
             looker_cpu_usage_per_app.cpu_rate]
    pivots: [looker_cpu_usage_per_app.app_name]
    sorts: [looker_cpu_usage_per_app.batch_time desc]
    limit: 500
    listen:
      cluster_filter: looker_cpu_usage_per_app.cluster_name
      date_filter: looker_cpu_usage_per_app.batch_time
    row: 11
    col: 0
    width: 12
    height: 8

  - title: "Node Resource Utilization"
    name: node_resources_chart
    model: striim_watcher
    explore: node_resources
    type: looker_column
    fields: [looker_node_resources.node_name, looker_node_resources.avg_cpu_percent,
             looker_node_resources.avg_memory_percent]
    sorts: [looker_node_resources.avg_cpu_percent desc]
    limit: 20
    listen:
      cluster_filter: looker_node_resources.cluster_name
    row: 11
    col: 12
    width: 12
    height: 8

  # Row 4: Failures and Smart Alerts
  - title: "Recent Application Failures"
    name: app_failures_table
    model: striim_watcher
    explore: app_failures
    type: looker_grid
    fields: [looker_app_failure_list.failure_time, looker_app_failure_list.app_name,
             looker_app_failure_list.node_name, looker_app_failure_list.failure_reason]
    sorts: [looker_app_failure_list.failure_time desc]
    limit: 15
    listen:
      cluster_filter: looker_app_failure_list.cluster_name
    row: 19
    col: 0
    width: 12
    height: 6

  - title: "Smart Alert History (WARN)"
    name: smart_alerts_table
    model: striim_watcher
    explore: smart_alerts
    type: looker_grid
    fields: [looker_smart_alert_history.alert_time, looker_smart_alert_history.app_name,
             looker_smart_alert_history.alert_type, looker_smart_alert_history.alert_message]
    sorts: [looker_smart_alert_history.alert_time desc]
    limit: 15
    listen:
      cluster_filter: looker_smart_alert_history.cluster_name
    row: 19
    col: 12
    width: 12
    height: 6

  # Row 5: Files Open and Backpressure Details
  - title: "CDC Files Currently Open"
    name: files_open_table
    model: striim_watcher
    explore: files_open
    type: looker_grid
    fields: [looker_files_open_list.app_name, looker_files_open_list.source_name,
             looker_files_open_list.file_name, looker_files_open_list.file_age_hours]
    sorts: [looker_files_open_list.file_age_hours desc]
    limit: 20
    listen:
      cluster_filter: looker_files_open_list.cluster_name
    row: 25
    col: 0
    width: 12
    height: 6

  - title: "Backpressure Details"
    name: backpressure_table
    model: striim_watcher
    explore: backpressure_status
    type: looker_grid
    fields: [looker_backpressure_status.app_name, looker_backpressure_status.component_name,
             looker_backpressure_status.backpressure_duration_minutes]
    filters:
      looker_backpressure_status.backpressure_active: "yes"
    sorts: [looker_backpressure_status.backpressure_duration_minutes desc]
    limit: 20
    listen:
      cluster_filter: looker_backpressure_status.cluster_name
    row: 25
    col: 12
    width: 12
    height: 6
