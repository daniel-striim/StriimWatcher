view: looker_oracle_open_trx {
  sql_table_name: `striim_watcher_metadata.looker_oracle_open_trx` ;;

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
    primary_key: yes
  }

  dimension: open_transaction_count {
    type: number
    sql: ${TABLE}.open_transaction_count ;;
  }

  dimension: oldest_transaction_age_hours {
    type: number
    sql: ${TABLE}.oldest_transaction_age_hours ;;
    value_format: "0.00"
  }

  dimension: transaction_status {
    type: string
    sql: CASE 
      WHEN ${TABLE}.oldest_transaction_age_hours > 24 THEN 'CRITICAL'
      WHEN ${TABLE}.oldest_transaction_age_hours > 4 THEN 'WARNING'
      ELSE 'NORMAL'
    END ;;
    html: 
      {% if value == 'CRITICAL' %}<span style="color: #D32F2F;">{{ value }}</span>
      {% elsif value == 'WARNING' %}<span style="color: #F57C00;">{{ value }}</span>
      {% else %}<span style="color: #388E3C;">{{ value }}</span>{% endif %} ;;
  }

  measure: total_open_transactions {
    type: sum
    sql: ${TABLE}.open_transaction_count ;;
    label: "Total Open Transactions"
  }

  measure: max_transaction_age_hours {
    type: max
    sql: ${TABLE}.oldest_transaction_age_hours ;;
    label: "Max Transaction Age (Hours)"
    value_format: "0.00"
  }

  measure: sources_with_open_trx {
    type: count
    label: "Sources With Open Transactions"
  }
}
