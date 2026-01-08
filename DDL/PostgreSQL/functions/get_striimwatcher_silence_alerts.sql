-- Function: Get StriimWatcher Silence Alerts
-- Purpose: Identifies clusters where StriimWatcher has not populated data for a specified duration
-- Parameters: threshold_minutes - Alert threshold in minutes (default: 60)
-- Returns: Alerts for clusters that have been silent longer than the threshold

CREATE OR REPLACE FUNCTION mon.get_striimwatcher_silence_alerts(threshold_minutes BIGINT DEFAULT 60)
RETURNS TABLE(
  clusterName TEXT,
  entity_name TEXT,
  deploymentOn TEXT,
  alert_type TEXT,
  alert_trigger_time TIMESTAMP,
  duration_of_problem_state_minutes BIGINT,
  configured_threshold_minutes BIGINT
)
AS $$
WITH
-- Get the latest run for each cluster and calculate silence duration
LatestClusterRuns AS (
  SELECT
    rh.clusterName,
    MAX(rh.batchdate) as last_run_time,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX(rh.batchdate)))/60 as minutes_since_last_run
  FROM
    mon.striim_mon_table_runhistory rh
  GROUP BY
    rh.clusterName
)

-- Generate alerts for clusters that have been silent longer than threshold
SELECT
  lcr.clusterName,
  'StriimWatcher-' || lcr.clusterName AS entity_name,
  'System Monitoring' AS deploymentOn,
  'STRIIMWATCHER_SILENCE' AS alert_type,
  CURRENT_TIMESTAMP AS alert_trigger_time,
  lcr.minutes_since_last_run::BIGINT AS duration_of_problem_state_minutes,
  threshold_minutes AS configured_threshold_minutes
FROM
  LatestClusterRuns lcr
WHERE
  -- Only alert if silence duration exceeds the specified threshold
  lcr.minutes_since_last_run >= threshold_minutes;
$$ LANGUAGE SQL;
