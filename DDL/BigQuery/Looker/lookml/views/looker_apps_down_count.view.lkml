view: looker_apps_down_count {
  sql_table_name: `striim_watcher_metadata.looker_apps_down_count` ;;

  dimension: cluster_name {
    type: string
    sql: ${TABLE}.clusterName ;;
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

  dimension: node_name {
    type: string
    sql: ${TABLE}.nodename ;;
  }

  dimension_group: down_since {
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.down_since ;;
  }

  dimension: duration_down_hours {
    type: number
    sql: ${TABLE}.duration_down_hours ;;
    value_format: "0.00"
  }

  measure: app_count {
    type: count
    label: "Apps Down"
  }

  measure: avg_downtime_hours {
    type: average
    sql: ${TABLE}.duration_down_hours ;;
    label: "Avg Downtime (Hours)"
    value_format: "0.00"
  }

  measure: max_downtime_hours {
    type: max
    sql: ${TABLE}.duration_down_hours ;;
    label: "Max Downtime (Hours)"
    value_format: "0.00"
  }
}
