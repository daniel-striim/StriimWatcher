view: looker_alert_trends {
  sql_table_name: `striim_watcher_metadata.looker_alert_trends` ;;

  dimension: cluster_name {
    type: string
    sql: ${TABLE}.clusterName ;;
  }

  dimension: alert_type {
    type: string
    sql: ${TABLE}.alert_type ;;
  }

  dimension: severity {
    type: string
    sql: ${TABLE}.severity ;;
  }

  dimension_group: alert {
    type: time
    timeframes: [raw, time, date, hour, week, month]
    sql: ${TABLE}.alert_time ;;
  }

  dimension: day_of_week {
    type: string
    sql: FORMAT_TIMESTAMP('%A', ${TABLE}.alert_time) ;;
    label: "Day of Week"
  }

  dimension: hour_of_day {
    type: number
    sql: EXTRACT(HOUR FROM ${TABLE}.alert_time) ;;
    label: "Hour of Day"
  }

  measure: alert_count {
    type: count
    label: "Total Alerts"
  }

  measure: critical_alerts {
    type: count
    filters: [severity: "CRITICAL"]
    label: "Critical Alerts"
  }

  measure: high_alerts {
    type: count
    filters: [severity: "HIGH"]
    label: "High Alerts"
  }

  measure: medium_alerts {
    type: count
    filters: [severity: "MEDIUM"]
    label: "Medium Alerts"
  }

  measure: low_alerts {
    type: count
    filters: [severity: "LOW"]
    label: "Low Alerts"
  }

  measure: unique_alert_types {
    type: count_distinct
    sql: ${TABLE}.alert_type ;;
    label: "Unique Alert Types"
  }
}
