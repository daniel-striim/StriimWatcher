view: looker_app_failure_list {
  sql_table_name: `striim_watcher_metadata.looker_app_failure_list` ;;

  dimension: cluster_name {
    type: string
    sql: ${TABLE}.clusterName ;;
  }

  dimension: app_name {
    type: string
    sql: ${TABLE}.appName ;;
    primary_key: yes
  }

  dimension: node_name {
    type: string
    sql: ${TABLE}.nodename ;;
  }

  dimension: app_status {
    type: string
    sql: ${TABLE}.appStatus ;;
  }

  dimension_group: failure {
    type: time
    timeframes: [raw, time, date, hour]
    sql: ${TABLE}.failure_time ;;
  }

  dimension: failure_reason {
    type: string
    sql: ${TABLE}.failure_reason ;;
  }

  measure: failure_count {
    type: count
    label: "Total Failures"
  }

  measure: unique_apps_failed {
    type: count_distinct
    sql: ${TABLE}.appName ;;
    label: "Unique Apps Failed"
  }
}
