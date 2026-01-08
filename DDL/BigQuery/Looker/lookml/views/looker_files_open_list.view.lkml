view: looker_files_open_list {
  sql_table_name: `striim_watcher_metadata.looker_files_open_list` ;;

  dimension: cluster_name {
    type: string
    sql: ${TABLE}.clusterName ;;
  }

  dimension: app_name {
    type: string
    sql: ${TABLE}.appName ;;
  }

  dimension: source_name {
    type: string
    sql: ${TABLE}.sourceName ;;
  }

  dimension: file_name {
    type: string
    sql: ${TABLE}.fileName ;;
    primary_key: yes
  }

  dimension_group: file_open {
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.file_open_time ;;
  }

  dimension: file_age_hours {
    type: number
    sql: ${TABLE}.file_age_hours ;;
    value_format: "0.00"
  }

  measure: file_count {
    type: count
    label: "Files Open"
  }

  measure: avg_file_age_hours {
    type: average
    sql: ${TABLE}.file_age_hours ;;
    label: "Avg File Age (Hours)"
    value_format: "0.00"
  }
}
