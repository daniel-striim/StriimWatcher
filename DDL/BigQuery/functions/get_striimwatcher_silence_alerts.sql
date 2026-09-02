-- Function: Get StriimWatcher Silence Alerts
-- Purpose: Identifies clusters where StriimWatcher has not populated data for a specified duration
-- Parameters: threshold_minutes - Alert threshold in minutes (recommended: 60)
-- Returns: Alerts for clusters that have been silent longer than the threshold

CREATE OR REPLACE TABLE FUNCTION `striim_watcher_metadata.get_striimwatcher_silence_alerts`(threshold_minutes INT64)
RETURNS TABLE<
  clusterName STRING,
  entity_name STRING,
  deploymentOn STRING,
  alert_type STRING,
  alert_trigger_time TIMESTAMP,
  duration_of_problem_state_minutes INT64,
  configured_threshold_minutes INT64
>
AS (
WITH
-- Get the latest run for each cluster and calculate silence duration
LatestClusterRuns AS (
  SELECT
    rh.clusterName,
    MAX(rh.batchdate) as last_run_time,
    TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), MAX(rh.batchdate), MINUTE) as minutes_since_last_run
  FROM
    `striim_watcher_metadata.striim_mon_table_runhistory` rh
  GROUP BY
    rh.clusterName
)

-- Generate alerts for clusters that have been silent longer than threshold
SELECT
  lcr.clusterName,
  CONCAT('StriimWatcher-', lcr.clusterName) AS entity_name,
  n.nodename AS deploymentOn,
  'STRIIMWATCHER_SILENCE' AS alert_type,
  CURRENT_TIMESTAMP() AS alert_trigger_time,
  lcr.minutes_since_last_run AS duration_of_problem_state_minutes,
  IFNULL(threshold_minutes, 60) AS configured_threshold_minutes
FROM
  LatestClusterRuns lcr
INNER JOIN
  `striim_watcher_metadata.striim_mon_node_cluster` n
  ON lcr.last_run_time = n.batchdate
WHERE
  -- Only alert if silence duration exceeds the specified threshold
  lcr.minutes_since_last_run >= IFNULL(threshold_minutes, 60)
);
