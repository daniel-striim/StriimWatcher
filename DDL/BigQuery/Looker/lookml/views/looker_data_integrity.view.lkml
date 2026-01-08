view: looker_data_integrity {
  sql_table_name: `striim_watcher_metadata.looker_data_integrity` ;;

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

  dimension: target_name {
    type: string
    sql: ${TABLE}.targetName ;;
    primary_key: yes
  }

  dimension: sync_status {
    type: string
    sql: ${TABLE}.sync_status ;;
    html: 
      {% if value == 'SIGNIFICANT_DRIFT' %}<span style="color: #D32F2F; font-weight: bold;">{{ value }}</span>
      {% elsif value == 'MODERATE_DRIFT' %}<span style="color: #F57C00;">{{ value }}</span>
      {% elsif value == 'MINOR_DRIFT' %}<span style="color: #FBC02D;">{{ value }}</span>
      {% else %}<span style="color: #388E3C;">{{ value }}</span>{% endif %} ;;
  }

  dimension: sync_severity {
    type: number
    sql: ${TABLE}.sync_severity ;;
  }

  dimension: total_difference {
    type: number
    sql: ${TABLE}.total_difference ;;
  }

  measure: table_count {
    type: count
    label: "Tables"
  }

  measure: total_drift {
    type: sum
    sql: ${TABLE}.total_difference ;;
    label: "Total Drift"
  }

  measure: tables_in_sync {
    type: count
    filters: [sync_status: "IN_SYNC"]
    label: "Tables In Sync"
  }

  measure: tables_with_drift {
    type: count
    filters: [sync_status: "-IN_SYNC"]
    label: "Tables With Drift"
  }
}
