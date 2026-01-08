view: looker_backpressure_status {
  sql_table_name: `striim_watcher_metadata.looker_backpressure_status` ;;

  dimension: cluster_name {
    type: string
    sql: ${TABLE}.clusterName ;;
  }

  dimension: app_name {
    type: string
    sql: ${TABLE}.appName ;;
    primary_key: yes
  }

  dimension: component_name {
    type: string
    sql: ${TABLE}.componentName ;;
  }

  dimension: backpressure_active {
    type: yesno
    sql: ${TABLE}.backpressure_active ;;
  }

  dimension: backpressure_duration_minutes {
    type: number
    sql: ${TABLE}.backpressure_duration_minutes ;;
    value_format: "0.00"
  }

  measure: apps_with_backpressure {
    type: count
    filters: [backpressure_active: "yes"]
    label: "Apps With Backpressure"
  }

  measure: avg_backpressure_duration {
    type: average
    sql: ${TABLE}.backpressure_duration_minutes ;;
    label: "Avg Backpressure Duration (Min)"
    value_format: "0.00"
  }
}
