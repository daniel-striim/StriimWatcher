view: looker_unified_alerts {
  sql_table_name: `striim_watcher_metadata.looker_unified_alerts` ;;

  dimension: cluster_name {
    type: string
    sql: ${TABLE}.clusterName ;;
    label: "Cluster"
  }

  dimension: app_name {
    type: string
    sql: ${TABLE}.appName ;;
    label: "Application"
  }

  dimension: node_name {
    type: string
    sql: ${TABLE}.nodename ;;
    label: "Node"
  }

  dimension: alert_type {
    type: string
    sql: ${TABLE}.alert_type ;;
    label: "Alert Type"
  }

  dimension: alert_category {
    type: string
    sql: ${TABLE}.alert_category ;;
    label: "Category"
  }

  dimension: severity {
    type: string
    sql: ${TABLE}.severity ;;
    label: "Severity"
    html: 
      {% if value == 'CRITICAL' %}<span style="color: #D32F2F; font-weight: bold;">{{ value }}</span>
      {% elsif value == 'HIGH' %}<span style="color: #F57C00;">{{ value }}</span>
      {% elsif value == 'MEDIUM' %}<span style="color: #FBC02D;">{{ value }}</span>
      {% else %}<span style="color: #388E3C;">{{ value }}</span>{% endif %} ;;
  }

  dimension: alert_priority {
    type: number
    sql: ${TABLE}.alert_priority ;;
    label: "Priority"
  }

  dimension: duration_hours {
    type: number
    sql: ${TABLE}.duration_hours ;;
    label: "Duration (Hours)"
    value_format: "0.00"
  }

  dimension_group: alert_trigger {
    type: time
    timeframes: [raw, time, date, hour]
    sql: ${TABLE}.alert_trigger_time ;;
    label: "Alert Trigger"
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

  measure: medium_count {
    type: count
    filters: [severity: "MEDIUM"]
    label: "Medium Alerts"
  }

  measure: avg_duration_hours {
    type: average
    sql: ${TABLE}.duration_hours ;;
    label: "Avg Duration (Hours)"
    value_format: "0.00"
  }
}
