view: looker_smart_alert_history {
  sql_table_name: `striim_watcher_metadata.looker_smart_alert_history` ;;

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

  dimension: alert_message {
    type: string
    sql: ${TABLE}.alert_message ;;
  }

  dimension: severity {
    type: string
    sql: ${TABLE}.severity ;;
  }

  dimension_group: alert {
    type: time
    timeframes: [raw, time, date, hour]
    sql: ${TABLE}.alert_time ;;
  }

  measure: alert_count {
    type: count
    label: "Total Alerts"
  }

  measure: warn_count {
    type: count
    filters: [severity: "WARN"]
    label: "Warnings"
  }
}
