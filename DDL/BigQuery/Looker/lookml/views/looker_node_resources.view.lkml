view: looker_node_resources {
  sql_table_name: `striim_watcher_metadata.looker_node_resources` ;;

  dimension: cluster_name {
    type: string
    sql: ${TABLE}.clusterName ;;
  }

  dimension: node_name {
    type: string
    sql: ${TABLE}.nodename ;;
    primary_key: yes
  }

  dimension_group: batch {
    type: time
    timeframes: [raw, time, date, hour]
    sql: ${TABLE}.batchdate ;;
  }

  dimension: cpu_percent {
    type: number
    sql: ${TABLE}.cpu_percent ;;
    value_format: "0.0"
  }

  dimension: memory_percent {
    type: number
    sql: ${TABLE}.memory_percent ;;
    value_format: "0.0"
  }

  dimension: cpu_status {
    type: string
    sql: CASE 
      WHEN ${TABLE}.cpu_percent > 90 THEN 'CRITICAL'
      WHEN ${TABLE}.cpu_percent > 75 THEN 'WARNING'
      ELSE 'NORMAL'
    END ;;
    html: 
      {% if value == 'CRITICAL' %}<span style="color: #D32F2F;">{{ value }}</span>
      {% elsif value == 'WARNING' %}<span style="color: #F57C00;">{{ value }}</span>
      {% else %}<span style="color: #388E3C;">{{ value }}</span>{% endif %} ;;
  }

  measure: avg_cpu_percent {
    type: average
    sql: ${TABLE}.cpu_percent ;;
    label: "Avg CPU %"
    value_format: "0.0"
  }

  measure: max_cpu_percent {
    type: max
    sql: ${TABLE}.cpu_percent ;;
    label: "Max CPU %"
    value_format: "0.0"
  }

  measure: avg_memory_percent {
    type: average
    sql: ${TABLE}.memory_percent ;;
    label: "Avg Memory %"
    value_format: "0.0"
  }

  measure: max_memory_percent {
    type: max
    sql: ${TABLE}.memory_percent ;;
    label: "Max Memory %"
    value_format: "0.0"
  }
}
