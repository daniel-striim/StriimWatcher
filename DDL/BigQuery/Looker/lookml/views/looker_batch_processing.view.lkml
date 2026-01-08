view: looker_batch_processing {
  sql_table_name: `striim_watcher_metadata.looker_batch_processing` ;;

  dimension: cluster_name {
    type: string
    sql: ${TABLE}.clusterName ;;
  }

  dimension: app_name {
    type: string
    sql: ${TABLE}.appName ;;
  }

  dimension: target_name {
    type: string
    sql: ${TABLE}.targetName ;;
    primary_key: yes
  }

  dimension_group: batch {
    type: time
    timeframes: [raw, time, date, hour]
    sql: ${TABLE}.batchdate ;;
  }

  dimension: rows_processed {
    type: number
    sql: ${TABLE}.rows_processed ;;
  }

  dimension: batch_duration_seconds {
    type: number
    sql: ${TABLE}.batch_duration_seconds ;;
    value_format: "0.00"
  }

  dimension: batch_status {
    type: string
    sql: ${TABLE}.batch_status ;;
  }

  measure: total_rows_processed {
    type: sum
    sql: ${TABLE}.rows_processed ;;
    label: "Total Rows Processed"
    value_format: "#,##0"
  }

  measure: avg_batch_duration {
    type: average
    sql: ${TABLE}.batch_duration_seconds ;;
    label: "Avg Batch Duration (Sec)"
    value_format: "0.00"
  }

  measure: batch_count {
    type: count
    label: "Total Batches"
  }

  measure: successful_batches {
    type: count
    filters: [batch_status: "SUCCESS"]
    label: "Successful Batches"
  }
}
