- dashboard: leadership_dashboard
  title: "StriimWatcher Leadership Dashboard"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Executive-level visibility into CDC pipeline health and performance"
  
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
    explore: lag_metrics
    field: looker_lag_graph.cluster_name

  - name: date_filter
    title: "Date Range"
    type: date_filter
    default_value: "7 days"
    allow_multiple_values: true
    required: false

  elements:
  # Row 1: Executive KPI Tiles
  - title: "Apps Down"
    name: apps_down_kpi
    model: striim_watcher
    explore: apps_down
    type: single_value
    fields: [looker_apps_down_count.app_count]
    listen:
      cluster_filter: looker_apps_down_count.cluster_name
    row: 0
    col: 0
    width: 6
    height: 4

  - title: "Avg Lag (Seconds)"
    name: avg_lag_kpi
    model: striim_watcher
    explore: lag_metrics
    type: single_value
    fields: [looker_lag_graph.avg_lag_seconds]
    listen:
      cluster_filter: looker_lag_graph.cluster_name
      date_filter: looker_lag_graph.batch_time
    row: 0
    col: 6
    width: 6
    height: 4

  - title: "Tables With Drift"
    name: drift_kpi
    model: striim_watcher
    explore: data_integrity
    type: single_value
    fields: [looker_data_integrity.tables_with_drift]
    listen:
      cluster_filter: looker_data_integrity.cluster_name
    row: 0
    col: 12
    width: 6
    height: 4

  - title: "Avg Stability Score"
    name: stability_kpi
    model: striim_watcher
    explore: downtime_analysis
    type: single_value
    fields: [looker_downtime_analysis.avg_stability_score]
    listen:
      cluster_filter: looker_downtime_analysis.cluster_name
    row: 0
    col: 18
    width: 6
    height: 4

  # Row 2: Lag Trend Chart
  - title: "End-to-End Lag Trend"
    name: lag_trend_chart
    model: striim_watcher
    explore: lag_metrics
    type: looker_line
    fields: [looker_lag_graph.batch_time, looker_lag_graph.app_name, 
             looker_lag_graph.avg_lag_seconds]
    pivots: [looker_lag_graph.app_name]
    sorts: [looker_lag_graph.batch_time desc]
    limit: 500
    listen:
      cluster_filter: looker_lag_graph.cluster_name
      date_filter: looker_lag_graph.batch_time
    row: 4
    col: 0
    width: 12
    height: 8

  - title: "Data Flow Rate"
    name: data_flow_chart
    model: striim_watcher
    explore: data_flow
    type: looker_area
    fields: [looker_data_flowing_graph.batch_time, looker_data_flowing_graph.avg_source_rate,
             looker_data_flowing_graph.avg_target_rate]
    sorts: [looker_data_flowing_graph.batch_time desc]
    limit: 500
    listen:
      cluster_filter: looker_data_flowing_graph.cluster_name
      date_filter: looker_data_flowing_graph.batch_time
    row: 4
    col: 12
    width: 12
    height: 8

  # Row 3: Downtime and Reliability
  - title: "Application Reliability Status"
    name: reliability_table
    model: striim_watcher
    explore: downtime_analysis
    type: looker_grid
    fields: [looker_downtime_analysis.app_name, looker_downtime_analysis.reliability_status,
             looker_downtime_analysis.stability_score, looker_downtime_analysis.total_downtime_transitions,
             looker_downtime_analysis.longest_downtime_hours, looker_downtime_analysis.days_since_last_downtime]
    sorts: [looker_downtime_analysis.stability_score asc]
    limit: 25
    listen:
      cluster_filter: looker_downtime_analysis.cluster_name
    row: 12
    col: 0
    width: 12
    height: 8

  - title: "Data Integrity Status"
    name: integrity_table
    model: striim_watcher
    explore: data_integrity
    type: looker_grid
    fields: [looker_data_integrity.app_name, looker_data_integrity.source_name,
             looker_data_integrity.target_name, looker_data_integrity.sync_status,
             looker_data_integrity.total_difference]
    sorts: [looker_data_integrity.sync_severity desc]
    limit: 25
    listen:
      cluster_filter: looker_data_integrity.cluster_name
    row: 12
    col: 12
    width: 12
    height: 8

  # Row 4: Throughput and Batch Processing
  - title: "Throughput by Hour of Day"
    name: throughput_heatmap
    model: striim_watcher
    explore: throughput_trends
    type: looker_grid
    fields: [looker_throughput_trends.hour_of_day, looker_throughput_trends.batch_day_of_week,
             looker_throughput_trends.avg_source_rate]
    pivots: [looker_throughput_trends.batch_day_of_week]
    sorts: [looker_throughput_trends.hour_of_day asc]
    limit: 24
    listen:
      cluster_filter: looker_throughput_trends.cluster_name
      date_filter: looker_throughput_trends.batch_time
    row: 20
    col: 0
    width: 12
    height: 8

  - title: "Batch Processing Summary"
    name: batch_summary
    model: striim_watcher
    explore: batch_processing
    type: looker_column
    fields: [looker_batch_processing.batch_date, looker_batch_processing.total_rows_processed,
             looker_batch_processing.batch_count]
    sorts: [looker_batch_processing.batch_date desc]
    limit: 14
    listen:
      cluster_filter: looker_batch_processing.cluster_name
      date_filter: looker_batch_processing.batch_time
    row: 20
    col: 12
    width: 12
    height: 8

  # Row 5: Alert Trends
  - title: "Alert Trend by Severity"
    name: alert_trend_chart
    model: striim_watcher
    explore: alert_trends
    type: looker_line
    fields: [looker_alert_trends.alert_date, looker_alert_trends.severity,
             looker_alert_trends.alert_count]
    pivots: [looker_alert_trends.severity]
    sorts: [looker_alert_trends.alert_date desc]
    limit: 500
    listen:
      cluster_filter: looker_alert_trends.cluster_name
      date_filter: looker_alert_trends.alert_time
    row: 28
    col: 0
    width: 12
    height: 6

  - title: "Alert Distribution by Type"
    name: alert_distribution_pie
    model: striim_watcher
    explore: alert_trends
    type: looker_pie
    fields: [looker_alert_trends.alert_type, looker_alert_trends.alert_count]
    sorts: [looker_alert_trends.alert_count desc]
    limit: 10
    listen:
      cluster_filter: looker_alert_trends.cluster_name
      date_filter: looker_alert_trends.alert_time
    row: 28
    col: 12
    width: 12
    height: 6
