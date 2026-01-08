-- View: Looker Downtime Analysis
-- Purpose: Shows application downtime patterns and metrics
-- Dashboard: Leadership Dashboard
-- Description: Returns downtime analysis using the existing get_app_downtime_analysis function

CREATE OR REPLACE VIEW `striim_watcher_metadata.looker_downtime_analysis` AS
SELECT
  da.appName,
  lkd.deploymentOn as nodename,
  rh.clusterName,
  da.total_downtime_transitions,
  da.longest_downtime_minutes,
  ROUND(da.longest_downtime_minutes / 60.0, 2) as longest_downtime_hours,
  da.longest_downtime_start,
  da.longest_downtime_end,
  da.most_recent_downtime_start,
  da.most_recent_downtime_end,
  da.most_recent_downtime_minutes,
  ROUND(da.most_recent_downtime_minutes / 60.0, 2) as most_recent_downtime_hours,
  da.minutes_since_last_downtime,
  ROUND(da.minutes_since_last_downtime / 60.0, 2) as hours_since_last_downtime,
  ROUND(da.minutes_since_last_downtime / 1440.0, 2) as days_since_last_downtime,
  da.currently_down,
  -- Stability score (higher is better)
  CASE
    WHEN da.total_downtime_transitions = 0 THEN 100
    WHEN da.total_downtime_transitions = 1 THEN 80
    WHEN da.total_downtime_transitions <= 3 THEN 60
    WHEN da.total_downtime_transitions <= 5 THEN 40
    WHEN da.total_downtime_transitions <= 10 THEN 20
    ELSE 0
  END as stability_score,
  -- Reliability status
  CASE
    WHEN da.currently_down THEN 'CURRENTLY_DOWN'
    WHEN da.total_downtime_transitions = 0 THEN 'STABLE'
    WHEN da.total_downtime_transitions <= 2 AND da.longest_downtime_minutes <= 60 THEN 'MOSTLY_STABLE'
    WHEN da.total_downtime_transitions <= 5 THEN 'OCCASIONAL_ISSUES'
    ELSE 'UNSTABLE'
  END as reliability_status
FROM
  `striim_watcher_metadata.get_app_downtime_analysis`(30) da
LEFT JOIN
  `striim_watcher_metadata.latest_known_deployments` lkd
  ON da.appName = lkd.appName
LEFT JOIN (
  SELECT DISTINCT rh.clusterName, ad.appName
  FROM `striim_watcher_metadata.striim_mon_appdetail` ad
  INNER JOIN `striim_watcher_metadata.striim_mon_table_runhistory` rh ON ad.batchdate = rh.batchdate
  INNER JOIN (SELECT MAX(batchdate) as max_batchdate FROM `striim_watcher_metadata.striim_mon_table_runhistory`) mb
    ON ad.batchdate = mb.max_batchdate
) rh ON da.appName = rh.appName
ORDER BY
  da.total_downtime_transitions DESC,
  da.longest_downtime_minutes DESC;

