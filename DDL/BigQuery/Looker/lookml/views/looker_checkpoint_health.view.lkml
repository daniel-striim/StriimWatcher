view: looker_checkpoint_health {
  sql_table_name: `striim_watcher_metadata.looker_checkpoint_health` ;;

  dimension: cluster_name {
    type: string
    sql: ${TABLE}.clusterName ;;
  }

  dimension: app_name {
    type: string
    sql: ${TABLE}.appName ;;
    primary_key: yes
  }

  dimension: checkpoint_enabled {
    type: yesno
    sql: ${TABLE}.checkpoint_enabled ;;
  }

  dimension_group: last_checkpoint {
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.last_checkpoint_time ;;
  }

  dimension: checkpoint_age_hours {
    type: number
    sql: ${TABLE}.checkpoint_age_hours ;;
    value_format: "0.00"
  }

  dimension: checkpoint_status {
    type: string
    sql: ${TABLE}.checkpoint_status ;;
    html: 
      {% if value == 'STALE' %}<span style="color: #D32F2F;">{{ value }}</span>
      {% elsif value == 'WARNING' %}<span style="color: #F57C00;">{{ value }}</span>
      {% else %}<span style="color: #388E3C;">{{ value }}</span>{% endif %} ;;
  }

  measure: apps_with_checkpoints {
    type: count
    filters: [checkpoint_enabled: "yes"]
    label: "Apps With Checkpoints"
  }

  measure: stale_checkpoints {
    type: count
    filters: [checkpoint_status: "STALE"]
    label: "Stale Checkpoints"
  }
}
