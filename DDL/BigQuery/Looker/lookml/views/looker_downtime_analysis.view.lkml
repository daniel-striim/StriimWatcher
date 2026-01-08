view: looker_downtime_analysis {
  sql_table_name: `striim_watcher_metadata.looker_downtime_analysis` ;;

  dimension: app_name {
    type: string
    sql: ${TABLE}.appName ;;
    primary_key: yes
  }

  dimension: cluster_name {
    type: string
    sql: ${TABLE}.clusterName ;;
  }

  dimension: node_name {
    type: string
    sql: ${TABLE}.nodename ;;
  }

  dimension: reliability_status {
    type: string
    sql: ${TABLE}.reliability_status ;;
    html: 
      {% if value == 'CURRENTLY_DOWN' %}<span style="color: #D32F2F; font-weight: bold;">{{ value }}</span>
      {% elsif value == 'UNSTABLE' %}<span style="color: #F57C00;">{{ value }}</span>
      {% elsif value == 'OCCASIONAL_ISSUES' %}<span style="color: #FBC02D;">{{ value }}</span>
      {% elsif value == 'MOSTLY_STABLE' %}<span style="color: #7CB342;">{{ value }}</span>
      {% else %}<span style="color: #388E3C;">{{ value }}</span>{% endif %} ;;
  }

  dimension: currently_down {
    type: yesno
    sql: ${TABLE}.currently_down ;;
  }

  dimension: stability_score {
    type: number
    sql: ${TABLE}.stability_score ;;
  }

  dimension: total_downtime_transitions {
    type: number
    sql: ${TABLE}.total_downtime_transitions ;;
  }

  dimension: longest_downtime_hours {
    type: number
    sql: ${TABLE}.longest_downtime_hours ;;
    value_format: "0.00"
  }

  dimension: days_since_last_downtime {
    type: number
    sql: ${TABLE}.days_since_last_downtime ;;
    value_format: "0.0"
  }

  measure: avg_stability_score {
    type: average
    sql: ${TABLE}.stability_score ;;
    label: "Avg Stability Score"
    value_format: "0"
  }

  measure: apps_currently_down {
    type: count
    filters: [currently_down: "yes"]
    label: "Apps Currently Down"
  }

  measure: total_apps {
    type: count
    label: "Total Apps"
  }

  measure: total_transitions {
    type: sum
    sql: ${TABLE}.total_downtime_transitions ;;
    label: "Total Downtime Events"
  }
}
