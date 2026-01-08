-- Function: Looker App Failure Drill-down
-- Purpose: Returns log entries near the time of app failure for root cause analysis
-- Dashboard: Operational Dashboard
-- Parameters: 
--   app_name - The application name to investigate
--   failure_batchdate - The batchdate when the failure was detected
--   minutes_window - Minutes before/after to search (default 15)
-- Description: Shows ERROR and WARN logs within ±15 minutes of failure time

CREATE OR REPLACE FUNCTION mon.looker_app_failure_drilldown(
  p_app_name TEXT,
  p_failure_batchdate TIMESTAMP,
  p_minutes_window INTEGER DEFAULT 15
)
RETURNS TABLE(
  clusterName TEXT,
  log_date TIMESTAMP,
  batchdate TIMESTAMP,
  server TEXT,
  appName TEXT,
  log_level TEXT,
  message TEXT,
  contextbuffertext TEXT,
  minutes_from_failure DOUBLE PRECISION
)
AS $$
  SELECT
    rh.clusterName,
    lw.log_date,
    lw.batchdate,
    lw.server,
    lw.appName,
    lw.log_level,
    lw.message,
    lw.contextbuffertext,
    EXTRACT(EPOCH FROM (lw.log_date - p_failure_batchdate)) / 60 as minutes_from_failure
  FROM
    mon.striim_mon_log_watcher lw
  INNER JOIN
    mon.striim_mon_table_runhistory rh
    ON lw.batchdate = rh.batchdate
  WHERE
    lw.appName = p_app_name
    AND lw.log_date BETWEEN 
      p_failure_batchdate - (p_minutes_window || ' minutes')::INTERVAL
      AND p_failure_batchdate + (p_minutes_window || ' minutes')::INTERVAL
    AND UPPER(TRIM(lw.log_level)) IN ('ERROR', 'WARN')
  ORDER BY
    lw.log_date DESC;
$$ LANGUAGE SQL;

