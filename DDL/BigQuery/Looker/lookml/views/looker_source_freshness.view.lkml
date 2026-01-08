view: looker_source_freshness {
  sql_table_name: `striim_watcher_metadata.looker_source_freshness` ;;

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

  dimension_group: last_event {
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.last_event_time ;;
  }

  dimension: freshness_minutes {
    type: number
    sql: ${TABLE}.freshness_minutes ;;
    value_format: "0.00"
  }

  dimension: freshness_status {
    type: string
    sql: ${TABLE}.freshness_status ;;
    html: 
      {% if value == 'STALE' %}<span style="color: #D32F2F;">{{ value }}</span>
      {% elsif value == 'WARNING' %}<span style="color: #F57C00;">{{ value }}</span>
      {% else %}<span style="color: #388E3C;">{{ value }}</span>{% endif %} ;;
  }

  measure: source_count {
    type: count
    label: "Total Sources"
  }

  measure: stale_sources {
    type: count
    filters: [freshness_status: "STALE"]
    label: "Stale Sources"
  }

  measure: avg_freshness_minutes {
    type: average
    sql: ${TABLE}.freshness_minutes ;;
    label: "Avg Freshness (Min)"
    value_format: "0.00"
  }
}
