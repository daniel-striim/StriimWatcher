view: looker_lag_graph {
  sql_table_name: `striim_watcher_metadata.looker_lag_graph` ;;

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
    timeframes: [raw, time, date, hour, minute15]
    sql: ${TABLE}.batchdate ;;
  }

  dimension: lag_seconds {
    type: number
    sql: ${TABLE}.lag_seconds ;;
  }

  dimension: lag_tier {
    type: tier
    tiers: [0, 60, 300, 900, 3600]
    style: integer
    sql: ${TABLE}.lag_seconds ;;
    label: "Lag Tier"
  }

  measure: avg_lag_seconds {
    type: average
    sql: ${TABLE}.lag_seconds ;;
    label: "Avg Lag (Seconds)"
    value_format: "0.00"
  }

  measure: max_lag_seconds {
    type: max
    sql: ${TABLE}.lag_seconds ;;
    label: "Max Lag (Seconds)"
    value_format: "0.00"
  }

  measure: min_lag_seconds {
    type: min
    sql: ${TABLE}.lag_seconds ;;
    label: "Min Lag (Seconds)"
    value_format: "0.00"
  }

  measure: rolling_avg_lag {
    type: average
    sql: ${TABLE}.rolling_avg_lag ;;
    label: "Rolling Avg Lag"
    value_format: "0.00"
  }

  measure: p95_lag {
    type: percentile
    percentile: 95
    sql: ${TABLE}.lag_seconds ;;
    label: "P95 Lag (Seconds)"
    value_format: "0.00"
  }
}
