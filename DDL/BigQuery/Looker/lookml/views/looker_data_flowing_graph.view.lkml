view: looker_data_flowing_graph {
  sql_table_name: `striim_watcher_metadata.looker_data_flowing_graph` ;;

  dimension: cluster_name {
    type: string
    sql: ${TABLE}.clusterName ;;
  }

  dimension: app_name {
    type: string
    sql: ${TABLE}.appName ;;
  }

  dimension_group: batch {
    type: time
    timeframes: [raw, time, date, hour]
    sql: ${TABLE}.batchdate ;;
  }

  dimension: source_rate {
    type: number
    sql: ${TABLE}.source_rate ;;
  }

  dimension: target_rate {
    type: number
    sql: ${TABLE}.target_rate ;;
  }

  dimension: is_flowing {
    type: yesno
    sql: ${TABLE}.source_rate > 0 OR ${TABLE}.target_rate > 0 ;;
    label: "Data Flowing"
  }

  measure: avg_source_rate {
    type: average
    sql: ${TABLE}.source_rate ;;
    label: "Avg Source Rate"
    value_format: "#,##0"
  }

  measure: avg_target_rate {
    type: average
    sql: ${TABLE}.target_rate ;;
    label: "Avg Target Rate"
    value_format: "#,##0"
  }

  measure: max_source_rate {
    type: max
    sql: ${TABLE}.source_rate ;;
    label: "Max Source Rate"
    value_format: "#,##0"
  }

  measure: max_target_rate {
    type: max
    sql: ${TABLE}.target_rate ;;
    label: "Max Target Rate"
    value_format: "#,##0"
  }

  measure: total_source_events {
    type: sum
    sql: ${TABLE}.source_rate ;;
    label: "Total Source Events"
    value_format: "#,##0"
  }

  measure: total_target_events {
    type: sum
    sql: ${TABLE}.target_rate ;;
    label: "Total Target Events"
    value_format: "#,##0"
  }
}
