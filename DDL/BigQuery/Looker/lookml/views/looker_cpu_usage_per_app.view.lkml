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
    primary_key: yes
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

  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }

  measure: cpu_rate {
    type: average
    sql: ${TABLE}.cpurate ;;
    label: "CPU Rate"
    value_format: "0.00"
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

  measure: app_count {
    type: count_distinct
    sql: ${TABLE}.appname ;;
    label: "App Count"
  }
}
